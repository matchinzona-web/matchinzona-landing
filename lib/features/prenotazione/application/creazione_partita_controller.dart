import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/models/campo.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/models/societa.dart';
import 'package:app_campi/core/repositories/campi_repository.dart';
import 'package:app_campi/core/repositories/orario_societa_repository.dart';
import 'package:app_campi/core/repositories/partita_repository.dart';
import 'package:app_campi/core/services/partita_service.dart';
import 'package:app_campi/features/prenotazione/application/creazione_partita_state.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/repositories/chiusura_straordinaria_repository.dart';
import 'package:app_campi/core/models/orario_societa.dart';
import 'package:app_campi/core/repositories/societa_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TipoRicerca { tutti, societa, citta }

final creazionePartitaProvider =
    NotifierProvider<CreazionePartitaController, CreazionePartitaState>(
      CreazionePartitaController.new,
    );

class CreazionePartitaController extends Notifier<CreazionePartitaState> {
  final _campiRepo = CampiRepository();
  final _societaRepo = SocietaRepository();
  final _orarioRepo = OrarioSocietaRepository();
  final _partitaRepo = PartitaRepository();
  final _partitaService = PartitaService();
  final _chiusuraRepo = ChiusuraStraordinariaRepository();

  TipoRicerca filtroCorrente = TipoRicerca.tutti;
  static const _chiaveUltimoSport = 'ultimo_sport_prenotazione';

  @override
  CreazionePartitaState build() {
    _caricaUltimoSport();

    return CreazionePartitaState(dataSelezionata: DateTime.now());
  }

  void impostaFiltroRicerca(TipoRicerca filtro) {
    filtroCorrente = filtro;
  }

  Future<void> cercaSocieta(String queryText) async {
    if (queryText.isEmpty) return;
    state = state.copyWith(isLoading: true, societaTrovate: []);

    try {
      List<Societa> risultati = [];
      if (filtroCorrente == TipoRicerca.societa) {
        risultati = await _societaRepo.cercaSocietaPerNome(queryText);
      } else if (filtroCorrente == TipoRicerca.citta) {
        risultati = await _societaRepo.cercaSocietaPerCitta(queryText);
      } else {
        risultati = await _societaRepo.cercaSocietaGlobale(queryText);
      }

      final Map<String, Societa> mappaUnivoca = {
        for (var s in risultati) s.id: s,
      };

      state = state.copyWith(
        isLoading: false,
        societaTrovate: mappaUnivoca.values.toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint("Errore ricerca società: $e");
    }
  }

  Future<void> caricaCampiSocieta(String idSocieta) async {
    state = state.copyWith(isLoading: true, campiTrovati: []);
    try {
      final campi = await _campiRepo.getCampiSocietaConDettagli(idSocieta);
      final societa = await _societaRepo.getSocietaById(idSocieta);
      final int limiteCampi = societa?.limiteCampi ?? campi.length;
      final campiAttivi = campi.take(limiteCampi).toList();

      // FILTRAGGIO CAMPI PER LO SPORT SELEZIONATO
      final sportSelezionato = state.sportSelezionato;

      bool supportaSport(Campo campo) {
        final sportRichiesto = sportSelezionato.trim().toLowerCase();

        return campo.tariffeSport.any((tariffa) {
          final sportCampo = tariffa.sport.trim().toLowerCase();

          if (sportCampo == sportRichiesto) {
            return true;
          }

          // "Tutto il calcio"
          if (sportRichiesto == 'calcio') {
            return sportCampo.startsWith('calcio_');
          }

          // "Tutto il tennis"
          if (sportRichiesto == 'tennis') {
            return sportCampo.startsWith('tennis_');
          }

          return false;
        });
      }

      final campiOrdinati = [...campiAttivi];

      campiOrdinati.sort((a, b) {
        final aCompatibile = supportaSport(a);
        final bCompatibile = supportaSport(b);

        if (aCompatibile && !bCompatibile) return -1;
        if (!aCompatibile && bCompatibile) return 1;

        return 0;
      });

      state = state.copyWith(isLoading: false, campiTrovati: campiOrdinati);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint("Errore caricamento campi: $e");
    }
  }

  void selezionaCampo(Campo? campo) {
    String? sportDaUsare;

    if (campo != null && campo.tariffeSport.isNotEmpty) {
      final String sportAttuale = state.sportSelezionato.trim().toLowerCase();

      final bool campoSupportaSportAttuale = campo.tariffeSport.any(
        (t) => t.sport.trim().toLowerCase() == sportAttuale,
      );

      if (campoSupportaSportAttuale) {
        // Se il campo supporta lo sport che l'utente ha cercato,
        // manteniamo quello.
        sportDaUsare = sportAttuale;
      } else {
        // Altrimenti selezioniamo il primo sport realmente
        // disponibile su questo campo.
        sportDaUsare = campo.tariffeSport.first.sport.trim().toLowerCase();
      }
    }

    state = state.copyWith(
      campoSelezionato: campo,
      clearCampo: campo == null,
      sportSelezionato: sportDaUsare,
      ospitiExtra: 0,
      clearOrario: true,
      giorniChiusi: [],
      pagamentiOnlineDisponibili: false,
      metodoPagamentoScelto: MetodoPagamento.inSede,
    );

    if (campo != null) {
      _caricaDisponibilitaPagamenti(campo.idSocieta);

      _inizializzaCalendario(campo.idSocieta);

      caricaOrari(state.dataSelezionata);
    }
  }

  Future<void> _caricaDisponibilitaPagamenti(String idSocieta) async {
    try {
      final societa = await _societaRepo.getSocietaById(idSocieta);

      if (societa == null) {
        state = state.copyWith(
          pagamentiOnlineDisponibili: false,
          metodoPagamentoScelto: MetodoPagamento.inSede,
        );

        return;
      }

      final disponibile =
          societa.stripeChargesEnabled && societa.stripePayoutsEnabled;

      state = state.copyWith(
        pagamentiOnlineDisponibili: disponibile,
        metodoPagamentoScelto: disponibile
            ? state.metodoPagamentoScelto
            : MetodoPagamento.inSede,
      );
    } catch (e) {
      debugPrint('Errore verifica pagamenti online: $e');

      state = state.copyWith(
        pagamentiOnlineDisponibili: false,
        metodoPagamentoScelto: MetodoPagamento.inSede,
      );
    }
  }

  Future<void> _inizializzaCalendario(String idSocieta) async {
    List<DateTime> chiusi = [];
    Map<int, bool> cacheSettimanale = {};

    await Future.wait(
      List.generate(14, (i) async {
        final data = DateTime.now().add(Duration(days: i));
        final weekday = data.weekday;

        if (!cacheSettimanale.containsKey(weekday)) {
          final orario = await _orarioRepo.getOrarioGiorno(idSocieta, weekday);
          cacheSettimanale[weekday] = (orario == null || orario.isChiuso);
        }

        if (cacheSettimanale[weekday] == true) {
          chiusi.add(data);
        } else {
          final chiusureStr = await _chiusuraRepo.getChiusurePerData(
            idSocieta,
            data,
          );
          if (chiusureStr.any(
            (c) => c.orarioInizio == null && c.orarioFine == null,
          )) {
            chiusi.add(data);
          }
        }
      }),
    );

    state = state.copyWith(giorniChiusi: chiusi);
  }

  void resetConfigurazione() => selezionaCampo(null);

  void svuotaTutto() =>
      state = CreazionePartitaState(dataSelezionata: DateTime.now());

  Future<void> caricaOrari(DateTime data) async {
    if (state.campoSelezionato == null) return;
    state = state.copyWith(
      isLoading: true,
      dataSelezionata: data,
      clearOrario: true,
    );

    try {
      final orari = await _orarioRepo.getOrarioGiorno(
        state.campoSelezionato!.idSocieta,
        data.weekday,
      );

      final statiOrari = await _partitaRepo.getStatoOrariGiorno(
        state.campoSelezionato!.id,
        data,
      );

      final chiusure = await _chiusuraRepo.getChiusurePerData(
        state.campoSelezionato!.idSocieta,
        data,
      );

      if (orari != null && !orari.isChiuso) {
        final slots = _generaSlotDoppioTurno(orari);

        List<String> slotChiusi = [];
        List<String> slotOccupati = [];
        Map<String, int> apertePerSlot = {};
        Map<String, String> mieiMatchPerSlot = {};

        for (var slot in slots) {
          int minSlot = _orarioInMinuti(slot);
          bool isChiuso = false;

          for (var c in chiusure) {
            if (c.orarioInizio == null ||
                c.orarioFine == null ||
                (minSlot >= _orarioInMinuti(c.orarioInizio!) &&
                    minSlot < _orarioInMinuti(c.orarioFine!))) {
              slotChiusi.add(slot);
              isChiuso = true;
              break;
            }
          }

          if (!isChiuso) {
            final info = statiOrari[slot];
            if (info != null) {
              bool fisso = info['occupato_fisso'] as bool;
              int aperte = info['aperte'] as int;
              final String? mioMatchId = info['mio_match_aperto_id'] as String?;

              if (fisso) {
                slotOccupati.add(slot);
              } else if (aperte > 0) {
                apertePerSlot[slot] = aperte;

                if (mioMatchId != null && mioMatchId.isNotEmpty) {
                  mieiMatchPerSlot[slot] = mioMatchId;
                }
              }
            }
          }
        }

        final firstAvailable = slots.firstWhere(
          (s) => !slotChiusi.contains(s) && !slotOccupati.contains(s),
          orElse: () => '',
        );

        state = state.copyWith(
          orariDisponibili: slots,
          orariOccupati: slotOccupati,
          orariChiusi: slotChiusi,
          partiteApertePerSlot: apertePerSlot,
          mieiMatchApertiPerSlot: mieiMatchPerSlot,
          oraInizioSelezionata: firstAvailable.isNotEmpty
              ? firstAvailable
              : null,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          orariDisponibili: [],
          orariChiusi: [],
          orariOccupati: [],
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint("Errore orari: $e");
    }
  }

  void aggiornaOrario(String? orario) =>
      state = state.copyWith(oraInizioSelezionata: orario);

  void aggiornaOspiti(int ospiti) =>
      state = state.copyWith(ospitiExtra: ospiti);

  void aggiornaTipoPartita(bool isPrivata) {
    state = state.copyWith(
      isPartitaPrivata: isPrivata,
      // 🟢 Se passa a cerca giocatori, resetta forzatamente a Paga al Campo
      metodoPagamentoScelto: isPrivata
          ? state.metodoPagamentoScelto
          : MetodoPagamento.inSede,
    );
  }

  void selezionaMetodoPagamento(MetodoPagamento metodo) {
    if (metodo == MetodoPagamento.pagaOra &&
        !state.pagamentiOnlineDisponibili) {
      return;
    }

    state = state.copyWith(metodoPagamentoScelto: metodo);
  }

  Future<String> confermaMatch(
    Utente organizzatore, {
    String? stripePaymentIntentId,
    int? importoRimborsabileCentesimi,
  }) async {
    if (state.oraInizioSelezionata == null || state.campoSelezionato == null) {
      throw Exception('Dati partita incompleti.');
    }
    state = state.copyWith(isLoading: true);

    try {
      final int maxGiocatoriReal = getMaxGiocatori();

      int ospitiFinali = state.isPartitaPrivata
          ? (maxGiocatoriReal - 1)
          : state.ospitiExtra;

      final bool isMaggiorenne =
          organizzatore.eta != null && organizzatore.eta! >= 18;

      if (state.isPartitaPrivata &&
          state.metodoPagamentoScelto == MetodoPagamento.pagaOra &&
          !isMaggiorenne) {
        throw Exception(
          'Il pagamento online è disponibile solo per utenti maggiorenni.',
        );
      }

      final bool pagatoEffettivo =
          state.isPartitaPrivata &&
          state.metodoPagamentoScelto == MetodoPagamento.pagaOra;

      final esito = await _partitaService.creaNuovaPartita(
        campo: state.campoSelezionato!,
        organizzatore: organizzatore,
        sport: state.sportSelezionato,
        dataPartita: state.dataSelezionata,
        orarioInizio: "${state.oraInizioSelezionata}:00",
        orarioFine: _calcolaOrarioFine(state.oraInizioSelezionata!),
        ospitiExtra: ospitiFinali,
        isPartitaPrivata: state.isPartitaPrivata,
        isPagato: pagatoEffettivo,
        stripePaymentIntentId: stripePaymentIntentId,
        importoRimborsabileCentesimi: importoRimborsabileCentesimi,
      );

      if (!esito.isSuccesso) {
        String msg = esito.errore ?? 'Errore imprevisto';

        if (esito.errore == 'SLOT_GIA_OCCUPATO') {
          msg = "Questo slot è già occupato da una partita completa.";
        }

        throw Exception(msg);
      }

      state = state.copyWith(isLoading: false);
      return esito.idPartita!;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  bool isNumeroGiocatoriValido() {
    if (state.campoSelezionato == null) return false;

    final maxGiocatori = getMaxGiocatori();
    final giocatoriTotali = state.ospitiExtra + 1;

    return giocatoriTotali >= 1 && giocatoriTotali <= maxGiocatori;
  }

  String getInfoStatoPartita() {
    final maxGiocatori = getMaxGiocatori();
    final giocatoriAttuali = state.ospitiExtra + 1;

    if (state.isPartitaPrivata) {
      return "PARTITA PRIVATA";
    }

    if (giocatoriAttuali >= maxGiocatori) {
      return "PARTITA AL COMPLETO";
    }

    return "PARTITA APERTA";
  }

  Color getColoreStato() {
    if (state.isPartitaPrivata) {
      return AppTheme.neonOrange;
    }

    final maxGiocatori = getMaxGiocatori();
    final giocatoriAttuali = state.ospitiExtra + 1;

    if (giocatoriAttuali >= maxGiocatori) {
      return AppTheme.statoSuccesso;
    }

    return AppTheme.accent;
  }

  List<String> _generaSlotDoppioTurno(OrarioSocieta orari) {
    List<String> slotsValidi = [];

    if (orari.orarioApertura != null && orari.orarioChiusura != null) {
      int minAttuale = _orarioInMinuti(orari.orarioApertura!);
      int minLimite = _orarioInMinuti(orari.orarioChiusura!);

      if (minLimite == 0 && minAttuale > 0) {
        minLimite = 24 * 60;
      }

      while (minAttuale + 60 <= minLimite) {
        slotsValidi.add(
          "${(minAttuale ~/ 60 % 24).toString().padLeft(2, '0')}:${(minAttuale % 60).toString().padLeft(2, '0')}",
        );
        minAttuale += 60;
      }
    }

    if (orari.orarioApertura2 != null && orari.orarioChiusura2 != null) {
      int minAttuale2 = _orarioInMinuti(orari.orarioApertura2!);
      int minLimite2 = _orarioInMinuti(orari.orarioChiusura2!);

      if (minLimite2 == 0 && minAttuale2 > 0) {
        minLimite2 = 24 * 60;
      }

      while (minAttuale2 + 60 <= minLimite2) {
        String slot =
            "${(minAttuale2 ~/ 60 % 24).toString().padLeft(2, '0')}:${(minAttuale2 % 60).toString().padLeft(2, '0')}";
        if (!slotsValidi.contains(slot)) {
          slotsValidi.add(slot);
        }
        minAttuale2 += 60;
      }
    }

    slotsValidi.sort(
      (a, b) => _orarioInMinuti(a).compareTo(_orarioInMinuti(b)),
    );

    return slotsValidi;
  }

  int _orarioInMinuti(String orario) {
    final List<String> parti = orario.trim().split(':');

    final int ore = int.parse(parti[0]);
    final int minuti = int.parse(parti[1]);

    return (ore * 60) + minuti;
  }

  String _calcolaOrarioFine(String oraInizio) {
    int totalMinutes = _orarioInMinuti(oraInizio) + 60;
    return "${(totalMinutes ~/ 60 % 24).toString().padLeft(2, '0')}:${(totalMinutes % 60).toString().padLeft(2, '0')}:00";
  }

  void cambiaSportCampo(String sport) {
    final campo = state.campoSelezionato;

    if (campo == null) return;

    final sportNormalizzato = sport.trim().toLowerCase();

    final supportato = campo.tariffeSport.any(
      (t) => t.sport.trim().toLowerCase() == sportNormalizzato,
    );

    if (!supportato) return;

    state = state.copyWith(sportSelezionato: sportNormalizzato, ospitiExtra: 0);
  }

  Future<void> impostaSport(String sport) async {
    state = state.copyWith(sportSelezionato: sport);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_chiaveUltimoSport, sport);
  }

  void impostaData(DateTime data) {
    state = state.copyWith(dataSelezionata: data);
  }

  void impostaFasciaOraria(String fascia) {
    state = state.copyWith(fasciaOraria: fascia);
  }

  Future<void> cercaSocietaGlobaleSeVuota() async {
    if (state.societaTrovate.isNotEmpty) return;
    state = state.copyWith(isLoading: true);

    try {
      // Recupera tutte le società/centri dal database
      final risultati = await _societaRepo.cercaSocietaGlobale('');

      final Map<String, Societa> mappaUnivoca = {
        for (var s in risultati) s.id: s,
      };

      state = state.copyWith(
        isLoading: false,
        societaTrovate: mappaUnivoca.values.toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint("Errore caricamento iniziale società: $e");
    }
  }

  Future<void> applicaFiltri() async {
    state = state.copyWith(isLoading: true);

    try {
      // dataSelezionata.weekday restituisce 1 per Lunedì, 2 per Martedì... 7 per Domenica
      final int giornoSettimana = state.dataSelezionata.weekday;

      final risultati = await _societaRepo.cercaSocietaEPrezziPerSport(
        sport: state.sportSelezionato,
        giornoSettimana: giornoSettimana,
      );

      final List<Societa> listaSocieta = [];
      final Map<String, double> mappaPrezzi = {};

      for (var item in risultati) {
        final Societa s = item['societa'];
        final double p = item['prezzo'];
        listaSocieta.add(s);
        mappaPrezzi[s.id] = p;
      }

      state = state.copyWith(
        isLoading: false,
        societaTrovate: listaSocieta,
        prezziPerSocieta: mappaPrezzi,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint("Errore applicazione filtri: $e");
    }
  }

  int getMaxGiocatori() {
    if (state.campoSelezionato == null) return 0;
    final sport = state.sportSelezionato;

    if (sport == 'tennis_singolo') return 2;
    if (sport == 'tennis_doppio' || sport == 'padel') return 4;

    if (sport == 'calcio_5') return 10;
    if (sport == 'calcio_6') return 12;
    if (sport == 'calcio_7') return 14;
    if (sport == 'calcio_8') return 16;
    if (sport == 'calcio_11') return 22;

    if (sport == 'basket') return 10;
    if (sport == 'pallavolo') return 12;

    return state.campoSelezionato!.numeroDiGiocatori;
  }

  double getPrezzoSportSelezionato() {
    if (state.campoSelezionato == null) return 0.0;
    final campo = state.campoSelezionato!;

    if (campo.tariffeSport.isNotEmpty) {
      for (var t in campo.tariffeSport) {
        if (t.sport == state.sportSelezionato) {
          return t.prezzo;
        }
      }
    }
    return campo.prezzo;
  }

  Future<void> _caricaUltimoSport() async {
    final prefs = await SharedPreferences.getInstance();

    final ultimoSport = prefs.getString(_chiaveUltimoSport);

    if (ultimoSport == null || ultimoSport.trim().isEmpty) {
      return;
    }

    state = state.copyWith(sportSelezionato: ultimoSport);
  }
}
