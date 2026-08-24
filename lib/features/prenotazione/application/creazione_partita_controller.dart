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

  @override
  CreazionePartitaState build() {
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

      final campiFiltratiPerSport = campiAttivi.where((campo) {
        // 1. Controlliamo se la lista tariffeSport del campo contiene lo sport selezionato
        if (campo.tariffeSport != null && campo.tariffeSport!.isNotEmpty) {
          for (final t in campo.tariffeSport!) {
            // Accesso sicuro alle proprietà di TariffaSport
            final String sportNome = t.sport;
            if (sportNome == sportSelezionato ||
                (sportSelezionato.contains('tennis') &&
                    sportNome.contains('tennis'))) {
              return true;
            }
          }
        }

        // 2. Controllo sul nome del campo come fallback
        final nomeCampo = campo.nomeCampo.toLowerCase();
        if (sportSelezionato == 'calcio_5' &&
            (nomeCampo.contains('calcio') || nomeCampo.contains('5'))) {
          return true;
        }
        if (sportSelezionato.contains('tennis') &&
            nomeCampo.contains('tennis')) {
          return true;
        }
        if (sportSelezionato == 'padel' && nomeCampo.contains('padel')) {
          return true;
        }
        if (sportSelezionato == 'basket' && nomeCampo.contains('basket')) {
          return true;
        }
        if (sportSelezionato == 'volley' &&
            (nomeCampo.contains('volley') || nomeCampo.contains('pallavolo'))) {
          return true;
        }

        return false;
      }).toList();

      // Se per qualsiasi motivo la lista filtrata è vuota, mostra i campi attivi di fallback
      final campiFinali = campiFiltratiPerSport.isNotEmpty
          ? campiFiltratiPerSport
          : campiAttivi;

      state = state.copyWith(isLoading: false, campiTrovati: campiFinali);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint("Errore caricamento campi: $e");
    }
  }

  void selezionaCampo(Campo? campo) {
    state = state.copyWith(
      campoSelezionato: campo,
      clearCampo: campo == null,
      ospitiExtra: 0,
      clearOrario: true,
      giorniChiusi: [],
    );
    if (campo != null) {
      _inizializzaCalendario(campo.idSocieta);
      caricaOrari(state.dataSelezionata);
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

              if (fisso) {
                slotOccupati.add(slot);
              } else if (aperte > 0) {
                apertePerSlot[slot] = aperte;
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

  void selezionaMetodoPagamento(MetodoPagamento metodo) =>
      state = state.copyWith(metodoPagamentoScelto: metodo);

  Future<void> confermaMatch(Utente organizzatore) async {
    if (state.oraInizioSelezionata == null || state.campoSelezionato == null) {
      return;
    }
    state = state.copyWith(isLoading: true);

    try {
      // 🟢 CORRETTO: Usa getMaxGiocatori() che legge 'tennis_doppio' = 4 o 'tennis_singolo' = 2!
      final int maxGiocatoriReal = getMaxGiocatori();

      int ospitiFinali = state.isPartitaPrivata
          ? (maxGiocatoriReal -
                1) // 🟢 Per il doppio fa 4 - 1 = 3 ospiti extra (Totale 4 giocatori)
          : state.ospitiExtra;

      // 🟢 isPagato è true SOLO se la partita è privata (campo intero) ed è stato scelto Paga Ora
      final bool pagatoEffettivo =
          state.isPartitaPrivata &&
          state.metodoPagamentoScelto == MetodoPagamento.pagaOra;

      final errore = await _partitaService.creaNuovaPartita(
        campo: state.campoSelezionato!,
        organizzatore: organizzatore,
        dataPartita: state.dataSelezionata,
        orarioInizio: "${state.oraInizioSelezionata}:00",
        orarioFine: _calcolaOrarioFine(state.oraInizioSelezionata!),
        ospitiExtra: ospitiFinali,
        isPartitaPrivata: state.isPartitaPrivata,
        isPagato: pagatoEffettivo,
      );

      if (errore != null) {
        String msg = errore;
        if (errore == 'SLOT_OCCUPATO_PARTITA_PROTETTA') {
          msg =
              "Impossibile prenotare: è già presente una partita protetta in questo orario.";
        } else if (errore == 'SLOT_GIA_OCCUPATO') {
          msg = "Questo slot è già occupato da una partita completa.";
        }
        throw Exception(msg);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  bool isMenoDi24h() {
    if (state.oraInizioSelezionata == null) return false;

    final parti = state.oraInizioSelezionata!.split(':');
    final inizioPartita = DateTime(
      state.dataSelezionata.year,
      state.dataSelezionata.month,
      state.dataSelezionata.day,
      int.parse(parti[0]),
      int.parse(parti[1]),
    );

    return DateTime.now().isAfter(
      inizioPartita.subtract(
        const Duration(hours: PartitaService.orePerditaProtezioneFissa),
      ),
    );
  }

  bool isNumeroGiocatoriValido() {
    if (state.isPartitaPrivata) return true;
    final max = state.campoSelezionato?.numeroDiGiocatori ?? 0;
    final attuali = state.ospitiExtra + 1;
    final oraInizio =
        int.tryParse(state.oraInizioSelezionata?.split(':').first ?? '0') ?? 0;
    bool isPrimeTime =
        oraInizio >= PartitaService.primeTimeInizio &&
        oraInizio <= PartitaService.primeTimeFine;
    return attuali >= _partitaService.getMinimoApertura(max, isPrimeTime);
  }

  String getInfoStatoPartita() {
    final maxGiocatori =
        getMaxGiocatori(); // 🔴 Usa getMaxGiocatori() invece di campo.numeroDiGiocatori!
    final ospitiAttuali = state.ospitiExtra + 1;

    if (state.isPartitaPrivata) return "PARTITA PRIVATA";
    if (ospitiAttuali >= maxGiocatori) return "PARTITA AL COMPLETO";

    // Logica normale
    if (ospitiAttuali >= (maxGiocatori * 0.8).floor())
      return "PARTITA PROTETTA";
    return "PARTITA A RISCHIO";
  }

  Color getColoreStato() {
    if (state.isPartitaPrivata) return AppTheme.neonOrange;

    final max = state.campoSelezionato?.numeroDiGiocatori ?? 0;
    final attuali = state.ospitiExtra + 1;

    if (attuali >= max) return AppTheme.neonOrange;

    final minRichiesti = _partitaService.getMinimoApertura(max, _isPrimeTime());
    final sogliaProtezione = _partitaService.getSogliaProtezione(max);

    if (attuali < minRichiesti) return Colors.orange;
    if (attuali < sogliaProtezione || isMenoDi24h()) return Colors.redAccent;
    return AppTheme.neonGreen;
  }

  bool _isPrimeTime() {
    final oraInizio =
        int.tryParse(state.oraInizioSelezionata?.split(':').first ?? '0') ?? 0;
    return oraInizio >= PartitaService.primeTimeInizio &&
        oraInizio <= PartitaService.primeTimeFine;
  }

  List<String> _generaSlotDoppioTurno(OrarioSocieta orari) {
    List<String> slotsValidi = [];

    if (orari.orarioApertura != null && orari.orarioChiusura != null) {
      int minAttuale = _orarioInMinuti(orari.orarioApertura!);
      int minLimite = _orarioInMinuti(orari.orarioChiusura!);

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
    List<String> parti = orario.trim().split(':');
    return (int.parse(parti[0]) * 60) + int.parse(parti[1]);
  }

  String _calcolaOrarioFine(String oraInizio) {
    int totalMinutes = _orarioInMinuti(oraInizio) + 60;
    return "${(totalMinutes ~/ 60 % 24).toString().padLeft(2, '0')}:${(totalMinutes % 60).toString().padLeft(2, '0')}:00";
  }

  void impostaSport(String sport) {
    state = state.copyWith(sportSelezionato: sport);
    // Ricarica o rifiltra i risultati
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
    if (sport == 'calcio_5' || sport == 'basket') return 10;

    return state.campoSelezionato!.numeroDiGiocatori;
  }

  double getPrezzoSportSelezionato() {
    if (state.campoSelezionato == null) return 0.0;
    final campo = state.campoSelezionato!;

    if (campo.tariffeSport != null && campo.tariffeSport!.isNotEmpty) {
      for (var t in campo.tariffeSport!) {
        if (t.sport == state.sportSelezionato) {
          return t.prezzo;
        }
      }
    }
    return campo.prezzo;
  }
}
