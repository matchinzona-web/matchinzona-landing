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
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? provinciaSelezionata;
  static const _chiaveUltimoSport = 'ultimo_sport_prenotazione';
  static const _chiaveUltimaProvincia = 'ultima_provincia_prenotazione';

  String _testoRicerca = '';
  int _idRichiestaFiltri = 0;

  @override
  CreazionePartitaState build() {
    _caricaUltimoSport();
    _caricaUltimaProvincia();

    return CreazionePartitaState(dataSelezionata: DateTime.now());
  }

  Future<List<String>> caricaProvinceDisponibili() {
    return _societaRepo.getProvinceDisponibili();
  }

  Future<void> impostaProvincia(String? provincia) async {
    provinciaSelezionata = provincia == null || provincia == 'Tutte le province'
        ? null
        : provincia;

    final prefs = await SharedPreferences.getInstance();

    if (provinciaSelezionata == null) {
      await prefs.remove(_chiaveUltimaProvincia);
    } else {
      await prefs.setString(_chiaveUltimaProvincia, provinciaSelezionata!);
    }

    await applicaFiltri();
  }

  void impostaFiltroRicerca(TipoRicerca filtro) {
    filtroCorrente = filtro;
  }

  Future<void> cercaSocieta(String queryText) async {
    final nuovoTesto = queryText.trim();
    final vecchioTesto = _testoRicerca;

    _testoRicerca = nuovoTesto;

    // Se il testo passa da meno di 3 lettere ad almeno 3,
    // oppure viceversa, aggiorna i risultati.
    final primaValida = vecchioTesto.length >= 3;
    final nuovaValida = nuovoTesto.length >= 3;

    if (primaValida != nuovaValida ||
        (nuovaValida && vecchioTesto != nuovoTesto)) {
      await applicaFiltri();
    }
  }

  void azzeraTestoRicerca() {
    _testoRicerca = '';
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
    int durataIniziale = 60;

    if (campo != null && sportDaUsare != null) {
      for (final tariffa in campo.tariffeSport) {
        if (tariffa.sport.trim().toLowerCase() == sportDaUsare) {
          final durate = tariffa.durateDisponibili;

          if (durate.isNotEmpty) {
            durataIniziale = durate.contains(60) ? 60 : durate.first;
          }

          break;
        }
      }
    }

    state = state.copyWith(
      campoSelezionato: campo,
      clearCampo: campo == null,
      sportSelezionato: sportDaUsare,
      durataMinutiSelezionata: durataIniziale,
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
    final campo = state.campoSelezionato;
    if (campo == null) return;

    final durata = state.durataMinutiSelezionata;

    state = state.copyWith(
      isLoading: true,
      dataSelezionata: data,
      clearOrario: true,
    );

    try {
      final orari = await _orarioRepo.getOrarioGiorno(
        campo.idSocieta,
        data.weekday,
      );

      final statiOrari = await _partitaRepo.getStatoOrariGiorno(campo.id, data);

      final chiusure = await _chiusuraRepo.getChiusurePerData(
        campo.idSocieta,
        data,
      );

      if (orari == null || orari.isChiuso) {
        state = state.copyWith(
          isLoading: false,
          orariDisponibili: [],
          orariChiusi: [],
          orariOccupati: [],
          partiteApertePerSlot: {},
          mieiMatchApertiPerSlot: {},
          clearOrario: true,
        );
        return;
      }

      final slots = _generaSlotDoppioTurno(orari);

      final List<String> slotChiusi = [];
      final List<String> slotOccupati = [];
      final Map<String, int> apertePerSlot = {};
      final Map<String, String> mieiMatchPerSlot = {};

      // Verifica tutti gli slot anche quando iniziano a :30.
      // Il controllo sul database considera l'intero intervallo.
      final intervalliOccupati = await _partitaRepo.getIntervalliOccupatiGiorno(
        idCampo: campo.id,
        data: data,
      );

      for (final slot in slots) {
        final inizioSlot = _orarioInMinuti(slot);
        final fineSlot = inizioSlot + durata;

        bool isChiuso = false;

        // Controlla le chiusure sull'intera durata,
        // non soltanto sull'orario di partenza.
        for (final chiusura in chiusure) {
          if (chiusura.orarioInizio == null || chiusura.orarioFine == null) {
            isChiuso = true;
            break;
          }

          final inizioChiusura = _orarioInMinuti(chiusura.orarioInizio!);

          int fineChiusura = _orarioInMinuti(chiusura.orarioFine!);

          if (fineChiusura == 0 && inizioChiusura > 0) {
            fineChiusura = 24 * 60;
          }

          if (_intervalliSovrapposti(
            inizioSlot,
            fineSlot,
            inizioChiusura,
            fineChiusura,
          )) {
            isChiuso = true;
            break;
          }
        }

        if (isChiuso) {
          slotChiusi.add(slot);
          continue;
        }

        // Risultato della funzione SQL slot_occupato_reale.
        final occupato = intervalliOccupati.any((prenotazione) {
          final inizioOccupazione = _orarioInMinuti(
            prenotazione['orario_inizio'].toString(),
          );

          int fineOccupazione = _orarioInMinuti(
            prenotazione['orario_fine'].toString(),
          );

          if (fineOccupazione == 0 && inizioOccupazione > 0) {
            fineOccupazione = 24 * 60;
          }

          return _intervalliSovrapposti(
            inizioSlot,
            fineSlot,
            inizioOccupazione,
            fineOccupazione,
          );
        });

        if (occupato) {
          slotOccupati.add(slot);
          continue;
        }

        // Manteniamo temporaneamente il conteggio dei match
        // aperti con lo stesso orario iniziale.
        final info = statiOrari[slot];

        if (info != null) {
          final aperte = (info['aperte'] as num?)?.toInt() ?? 0;

          final mioMatchId = info['mio_match_aperto_id'] as String?;

          if (aperte > 0) {
            apertePerSlot[slot] = aperte;
          }

          if (mioMatchId != null && mioMatchId.isNotEmpty) {
            mieiMatchPerSlot[slot] = mioMatchId;
          }
        }
      }

      final primoLibero = slots.firstWhere(
        (slot) => !slotChiusi.contains(slot) && !slotOccupati.contains(slot),
        orElse: () => '',
      );

      // Se l'utente ha già cambiato campo, data o durata
      // mentre caricavamo, non mostriamo risultati vecchi.
      if (state.campoSelezionato?.id != campo.id ||
          state.durataMinutiSelezionata != durata ||
          state.dataSelezionata != data) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        orariDisponibili: slots,
        orariOccupati: slotOccupati,
        orariChiusi: slotChiusi,
        partiteApertePerSlot: apertePerSlot,
        mieiMatchApertiPerSlot: mieiMatchPerSlot,
        oraInizioSelezionata: primoLibero.isNotEmpty ? primoLibero : null,
      );
    } catch (e) {
      debugPrint('Errore caricamento orari: $e');

      state = state.copyWith(
        isLoading: false,
        orariDisponibili: [],
        orariOccupati: [],
        orariChiusi: [],
        partiteApertePerSlot: {},
        mieiMatchApertiPerSlot: {},
        clearOrario: true,
      );
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

  Future<bool> slotAttualeOccupato() async {
    if (state.campoSelezionato == null || state.oraInizioSelezionata == null) {
      return true;
    }

    final data = state.dataSelezionata;

    final dataStr =
        "${data.year}-"
        "${data.month.toString().padLeft(2, '0')}-"
        "${data.day.toString().padLeft(2, '0')}";

    final orarioInizio = "${state.oraInizioSelezionata}:00";

    final orarioFine = _calcolaOrarioFine(state.oraInizioSelezionata!);

    final response = await Supabase.instance.client.rpc(
      'slot_occupato_reale',
      params: {
        'p_id_campo': state.campoSelezionato!.id,
        'p_data': dataStr,
        'p_inizio': orarioInizio,
        'p_fine': orarioFine,
      },
    );

    return response == true;
  }

  Future<String> confermaMatch(
    Utente organizzatore, {
    String? stripePaymentIntentId,
    int? importoRimborsabileCentesimi,
  }) async {
    if (state.oraInizioSelezionata == null || state.campoSelezionato == null) {
      throw Exception('Dati partita incompleti.');
    }

    final orarioScelto = state.oraInizioSelezionata;

    if (orarioScelto == null ||
        !state.orariDisponibili.contains(orarioScelto) ||
        state.orariOccupati.contains(orarioScelto) ||
        state.orariChiusi.contains(orarioScelto)) {
      throw Exception(
        'L’orario selezionato non è disponibile. '
        'Aggiorna il calendario e riprova.',
      );
    }
    final durateConsentite = getDurateDisponibiliCampo();

    if (!durateConsentite.contains(state.durataMinutiSelezionata)) {
      throw Exception(
        'La durata selezionata non è disponibile per questo campo.',
      );
    }
    final campoDaPrenotare = state.campoSelezionato!;
    final durataDaPrenotare = state.durataMinutiSelezionata;

    final tariffaPresente = campoDaPrenotare.tariffeSport.any(
      (tariffa) =>
          tariffa.sport.trim().toLowerCase() ==
              state.sportSelezionato.trim().toLowerCase() &&
          tariffa.supportaDurata(durataDaPrenotare),
    );

    if (!tariffaPresente) {
      throw Exception(
        'La tariffa per la durata selezionata non è più disponibile.',
      );
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
    // Se lo sport prevede una sola durata, gli slot partono con quella
    // cadenza. Se prevede sia 60 che 90 minuti, partono ogni 30 minuti.
    final durate = getDurateDisponibiliCampo();
    final passoMinuti = durate.length == 1 ? durate.first : 30;

    if (orari.orarioApertura != null && orari.orarioChiusura != null) {
      int minAttuale = _orarioInMinuti(orari.orarioApertura!);
      int minLimite = _orarioInMinuti(orari.orarioChiusura!);

      if (minLimite == 0 && minAttuale > 0) {
        minLimite = 24 * 60;
      }

      while (minAttuale + state.durataMinutiSelezionata <= minLimite) {
        slotsValidi.add(
          "${(minAttuale ~/ 60 % 24).toString().padLeft(2, '0')}:${(minAttuale % 60).toString().padLeft(2, '0')}",
        );
        minAttuale += passoMinuti;
      }
    }

    if (orari.orarioApertura2 != null && orari.orarioChiusura2 != null) {
      int minAttuale2 = _orarioInMinuti(orari.orarioApertura2!);
      int minLimite2 = _orarioInMinuti(orari.orarioChiusura2!);

      if (minLimite2 == 0 && minAttuale2 > 0) {
        minLimite2 = 24 * 60;
      }

      while (minAttuale2 + state.durataMinutiSelezionata <= minLimite2) {
        String slot =
            "${(minAttuale2 ~/ 60 % 24).toString().padLeft(2, '0')}:${(minAttuale2 % 60).toString().padLeft(2, '0')}";
        if (!slotsValidi.contains(slot)) {
          slotsValidi.add(slot);
        }
        minAttuale2 += passoMinuti;
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

  bool _intervalliSovrapposti(int inizioA, int fineA, int inizioB, int fineB) {
    return inizioA < fineB && fineA > inizioB;
  }

  int _minutiFine(String orarioInizio, int durata) {
    return _orarioInMinuti(orarioInizio) + durata;
  }

  String _calcolaOrarioFine(String oraInizio) {
    final int totalMinutes =
        _orarioInMinuti(oraInizio) + state.durataMinutiSelezionata;
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

    final nuovaDurata = durataPredefinitaPerSport(campo, sportNormalizzato);

    state = state.copyWith(
      sportSelezionato: sportNormalizzato,
      durataMinutiSelezionata: nuovaDurata,
      ospitiExtra: 0,
      clearOrario: true,
    );

    caricaOrari(state.dataSelezionata);
  }

  int durataPredefinitaPerSport(Campo campo, String sport) {
    final sportNormalizzato = sport.trim().toLowerCase();

    for (final tariffa in campo.tariffeSport) {
      if (tariffa.sport.trim().toLowerCase() == sportNormalizzato) {
        final durate = tariffa.durateDisponibili;

        if (durate.isEmpty) {
          throw StateError('Nessuna durata disponibile per questo sport.');
        }

        return durate.contains(60) ? 60 : durate.first;
      }
    }

    throw StateError('Sport non disponibile su questo campo.');
  }

  List<int> getDurateDisponibiliCampo() {
    final campo = state.campoSelezionato;

    if (campo == null) {
      return [60];
    }

    for (final tariffa in campo.tariffeSport) {
      if (tariffa.sport == state.sportSelezionato) {
        return tariffa.durateDisponibili;
      }
    }

    return [];
  }

  Future<void> cambiaDurataCampo(int durataMinuti) async {
    final durateDisponibili = getDurateDisponibiliCampo();

    if (!durateDisponibili.contains(durataMinuti)) {
      return;
    }

    if (state.durataMinutiSelezionata == durataMinuti) {
      return;
    }

    state = state.copyWith(
      durataMinutiSelezionata: durataMinuti,
      clearOrario: true,
    );

    await caricaOrari(state.dataSelezionata);
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
    final int idRichiesta = ++_idRichiestaFiltri;

    // Una ricerca troppo corta non restringe ancora i risultati.
    final testo = _testoRicerca.trim();
    final String? query = testo.length >= 3 ? testo : null;

    state = state.copyWith(isLoading: true);

    try {
      final int giornoSettimana = state.dataSelezionata.weekday;

      final risultati = await _societaRepo.cercaSocietaEPrezziPerSport(
        sport: state.sportSelezionato,
        giornoSettimana: giornoSettimana,
        provincia: provinciaSelezionata,
        testoRicerca: query,
      );

      // Ignora le risposte vecchie se nel frattempo è cambiato un filtro
      // o l'utente ha continuato a scrivere.
      if (idRichiesta != _idRichiestaFiltri) return;

      final List<Societa> listaSocieta = [];
      final Map<String, double> mappaPrezzi = {};

      for (final item in risultati) {
        final Societa societa = item['societa'] as Societa;
        final double prezzo = item['prezzo'] as double;

        listaSocieta.add(societa);
        mappaPrezzi[societa.id] = prezzo;
      }

      state = state.copyWith(
        isLoading: false,
        societaTrovate: listaSocieta,
        prezziPerSocieta: mappaPrezzi,
      );
    } catch (e) {
      if (idRichiesta != _idRichiestaFiltri) return;

      state = state.copyWith(isLoading: false);
      debugPrint('Errore applicazione filtri: $e');
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
    final campo = state.campoSelezionato;

    if (campo == null) return 0.0;

    final sport = state.sportSelezionato.trim().toLowerCase();
    final durata = state.durataMinutiSelezionata;

    for (final tariffa in campo.tariffeSport) {
      if (tariffa.sport.trim().toLowerCase() == sport) {
        final prezzo = tariffa.prezzoPerDurata(durata);

        if (prezzo == null || !prezzo.isFinite || prezzo <= 0) {
          throw StateError(
            'Nessun prezzo valido per $sport da $durata minuti.',
          );
        }

        return prezzo;
      }
    }

    throw StateError('Tariffa non disponibile per lo sport selezionato.');
  }

  Future<void> _caricaUltimoSport() async {
    final prefs = await SharedPreferences.getInstance();

    final ultimoSport = prefs.getString(_chiaveUltimoSport);

    if (ultimoSport == null || ultimoSport.trim().isEmpty) {
      return;
    }

    state = state.copyWith(sportSelezionato: ultimoSport);
  }

  Future<void> _caricaUltimaProvincia() async {
    final prefs = await SharedPreferences.getInstance();

    final ultimaProvincia = prefs.getString(_chiaveUltimaProvincia);

    if (ultimaProvincia == null || ultimaProvincia.trim().isEmpty) {
      provinciaSelezionata = null;
      return;
    }

    provinciaSelezionata = ultimaProvincia;
  }
}
