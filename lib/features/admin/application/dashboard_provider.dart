import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/services/campi_service.dart';
import 'package:app_campi/core/services/partita_service.dart';

class DashboardState {
  final List<Map<String, dynamic>> campi;
  final List<Map<String, dynamic>> datiPartiteRaw;
  final List<Map<String, dynamic>> orariSocieta;
  final List<Map<String, dynamic>> chiusureStraordinarie;
  final List<Appointment> prenotazioniVisibili;
  final String? idCampoSelezionato;
  final String stringaDataCorrente;
  final bool isLoading;
  final String? actualIdSocieta;
  final int limiteCampiConsentiti;
  final double startHour;
  final double endHour;
  final bool isCentroAttivo;
  final bool giornoChiuso;

  const DashboardState({
    this.campi = const [],
    this.datiPartiteRaw = const [],
    this.orariSocieta = const [],
    this.chiusureStraordinarie = const [],
    this.prenotazioniVisibili = const [],
    this.idCampoSelezionato,
    this.stringaDataCorrente = '',
    this.isLoading = true,
    this.actualIdSocieta,
    this.limiteCampiConsentiti = 1,
    this.startHour = 8.0,
    this.endHour = 24.0,
    this.isCentroAttivo = true,
    this.giornoChiuso = false,
  });

  DashboardState copyWith({
    List<Map<String, dynamic>>? campi,
    List<Map<String, dynamic>>? datiPartiteRaw,
    List<Map<String, dynamic>>? orariSocieta,
    List<Map<String, dynamic>>? chiusureStraordinarie,
    List<Appointment>? prenotazioniVisibili,
    String? idCampoSelezionato,
    bool clearIdCampo = false,
    String? stringaDataCorrente,
    bool? isLoading,
    String? actualIdSocieta,
    int? limiteCampiConsentiti,
    double? startHour,
    double? endHour,
    bool? isCentroAttivo,
    bool? giornoChiuso,
  }) {
    return DashboardState(
      campi: campi ?? this.campi,
      datiPartiteRaw: datiPartiteRaw ?? this.datiPartiteRaw,
      orariSocieta: orariSocieta ?? this.orariSocieta,
      chiusureStraordinarie:
          chiusureStraordinarie ?? this.chiusureStraordinarie,
      prenotazioniVisibili: prenotazioniVisibili ?? this.prenotazioniVisibili,
      idCampoSelezionato: clearIdCampo
          ? null
          : (idCampoSelezionato ?? this.idCampoSelezionato),
      stringaDataCorrente: stringaDataCorrente ?? this.stringaDataCorrente,
      isLoading: isLoading ?? this.isLoading,
      actualIdSocieta: actualIdSocieta ?? this.actualIdSocieta,
      limiteCampiConsentiti:
          limiteCampiConsentiti ?? this.limiteCampiConsentiti,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      isCentroAttivo: isCentroAttivo ?? this.isCentroAttivo,
      giornoChiuso: giornoChiuso ?? this.giornoChiuso,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardState> {
  final CampiService _campiService = CampiService();
  final PartitaService _partitaService = PartitaService();
  RealtimeChannel? _realtimeChannel;

  @override
  DashboardState build() => const DashboardState();

  Future<void> inizializza({String? idSocieta, Utente? utenteLoggato}) async {
    state = state.copyWith(isLoading: true);

    try {
      String? actualIdSocieta;
      int limiteCampiConsentiti = 1;

      bool centroAttivo = false;

      if (idSocieta != null) {
        final societaData = await Supabase.instance.client
            .from('societa')
            .select('id, limite_campi, piano_attuale')
            .eq('id', idSocieta)
            .single();

        actualIdSocieta = societaData['id'] as String;

        limiteCampiConsentiti = societaData['limite_campi'] as int? ?? 0;

        final String piano =
            societaData['piano_attuale']?.toString().trim().toLowerCase() ??
            'nessuno';

        centroAttivo = piano != 'nessuno';
      } else if (utenteLoggato != null) {
        final societaData = await Supabase.instance.client
            .from('societa')
            .select('id, limite_campi, piano_attuale')
            .eq('id_utente', utenteLoggato.id)
            .single();

        actualIdSocieta = societaData['id'] as String;

        limiteCampiConsentiti = societaData['limite_campi'] as int? ?? 0;

        final String piano =
            societaData['piano_attuale']?.toString().trim().toLowerCase() ??
            'nessuno';

        centroAttivo = piano != 'nessuno';
      }

      state = state.copyWith(
        actualIdSocieta: actualIdSocieta,
        limiteCampiConsentiti: limiteCampiConsentiti,
        isCentroAttivo: centroAttivo,
      );

      if (actualIdSocieta != null) {
        List<Map<String, dynamic>> campi = [];
        List<Map<String, dynamic>> datiPartiteRaw = [];
        List<Map<String, dynamic>> orariSocieta = [];
        List<Map<String, dynamic>> chiusureStraordinarie = [];

        try {
          campi = await _campiService.ottieniCampiSocieta(actualIdSocieta);
        } catch (e) {
          debugPrint("Err campi: $e");
        }

        String? idCampoSelezionato;
        bool clearIdCampo = false;
        if (campi.isEmpty) {
          clearIdCampo = true;
        } else {
          final ids = campi.map((c) => c['id'].toString()).toList();
          if (state.idCampoSelezionato == null ||
              !ids.contains(state.idCampoSelezionato)) {
            idCampoSelezionato = campi.first['id'].toString();
          } else {
            idCampoSelezionato = state.idCampoSelezionato;
          }
        }

        try {
          datiPartiteRaw = await _partitaService.ottieniPrenotazioniSocieta(
            actualIdSocieta,
          );
        } catch (e) {
          debugPrint("Err partite: $e");
        }

        try {
          orariSocieta = await Supabase.instance.client
              .from('orari_societa')
              .select()
              .eq('id_societa', actualIdSocieta);
        } catch (e) {
          debugPrint("Err orari: $e");
        }

        try {
          chiusureStraordinarie = await Supabase.instance.client
              .from('chiusure_straordinarie')
              .select()
              .eq('id_societa', actualIdSocieta);
        } catch (e) {
          debugPrint("Err chiusure: $e");
        }

        state = state.copyWith(
          campi: campi,
          datiPartiteRaw: datiPartiteRaw,
          orariSocieta: orariSocieta,
          chiusureStraordinarie: chiusureStraordinarie,
          idCampoSelezionato: idCampoSelezionato,
          clearIdCampo: clearIdCampo,
        );

        _calcolaOrariGriglia(DateTime.now());
        filtraEConvertiDatiCalendario();
      }
    } catch (e) {
      debugPrint("Errore inizializzazione: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void _calcolaOrariGriglia(DateTime giorno) {
    if (state.orariSocieta.isEmpty) {
      state = state.copyWith(startHour: 8.0, endHour: 24.0, giornoChiuso: true);
      return;
    }

    final int giornoSettimana = giorno.weekday;

    final Map<String, dynamic> orarioGiorno = state.orariSocieta.firstWhere(
      (o) => o['giorno_settimana'] == giornoSettimana,
      orElse: () => <String, dynamic>{},
    );

    // Se non esiste una configurazione per quel giorno,
    // consideriamo il centro chiuso.
    if (orarioGiorno.isEmpty || orarioGiorno['is_chiuso'] == true) {
      state = state.copyWith(startHour: 8.0, endHour: 9.0, giornoChiuso: true);
      return;
    }

    double? minH;
    double? maxH;

    double? parseHour(String? value) {
      if (value == null || value.isEmpty) return null;

      final parts = value.split(':');
      if (parts.isEmpty) return null;

      final hour = double.tryParse(parts[0]);
      if (hour == null) return null;

      final minutes = parts.length > 1 ? double.tryParse(parts[1]) ?? 0.0 : 0.0;

      return hour + (minutes / 60.0);
    }

    void aggiungiFascia(String? apertura, String? chiusura) {
      final double? start = parseHour(apertura);
      double? end = parseHour(chiusura);

      if (start == null || end == null) return;

      // 00:00 come orario di CHIUSURA significa fine giornata,
      // quindi deve essere trattato come 24:00 e non come 0:00.
      if (end == 0.0 && start > 0.0) {
        end = 24.0;
      }

      if (minH == null || start < minH!) {
        minH = start;
      }

      if (maxH == null || end > maxH!) {
        maxH = end;
      }
    }

    aggiungiFascia(
      orarioGiorno['orario_apertura']?.toString(),
      orarioGiorno['orario_chiusura']?.toString(),
    );

    aggiungiFascia(
      orarioGiorno['orario_apertura_2']?.toString(),
      orarioGiorno['orario_chiusura_2']?.toString(),
    );

    // Configurazione incompleta: consideriamo il giorno chiuso.
    if (minH == null || maxH == null || minH! >= maxH!) {
      state = state.copyWith(startHour: 8.0, endHour: 9.0, giornoChiuso: true);
      return;
    }

    final double startGriglia = minH!.floorToDouble();
    final double endGriglia = maxH!.ceilToDouble();

    state = state.copyWith(
      startHour: startGriglia,
      endHour: endGriglia,
      giornoChiuso: false,
    );
  }

  DateTime _parseDateTimeSicuro(String data, String orario) {
    try {
      final dStr = data.split('T')[0].split(' ')[0];
      final oStr = orario.contains(':') ? orario.substring(0, 5) : "00:00";
      return DateTime.parse('$dStr $oStr:00');
    } catch (e) {
      return DateTime.now();
    }
  }

  void filtraEConvertiDatiCalendario({String? idCampo}) {
    final campoId = idCampo ?? state.idCampoSelezionato;
    List<Appointment> tempAppointments = [];

    final partiteFiltrate = campoId == null
        ? state.datiPartiteRaw
        : state.datiPartiteRaw.where((p) => p['id_campo'] == campoId).toList();

    for (var p in partiteFiltrate) {
      try {
        final start = _parseDateTimeSicuro(
          p['data_partita'].toString(),
          p['orario_inizio'].toString(),
        );
        final end = _parseDateTimeSicuro(
          p['data_partita'].toString(),
          p['orario_fine'].toString(),
        );
        final String nomeCampo = p['campo']?['nome_campo'] ?? 'Campo';
        final bool isPrenotazioneManuale =
            p['origine_prenotazione'] == 'gestore';

        final String nomeClienteManuale = (p['nome_cliente_manual'] ?? '')
            .toString()
            .trim();

        String nomeVisualizzato;

        if (isPrenotazioneManuale) {
          nomeVisualizzato = nomeClienteManuale.isNotEmpty
              ? '📞 $nomeClienteManuale'
              : '📞 Prenotazione manuale';
        } else {
          nomeVisualizzato = p['organizzatore'] != null
              ? '${p['organizzatore']['nome']} '
                    '${p['organizzatore']['cognome']}'
              : 'Utente Sconosciuto';
        }
        final String idPartita = p['id']?.toString() ?? '';
        tempAppointments.add(
          Appointment(
            id: idPartita,
            startTime: start,
            endTime: end,
            subject: '$nomeVisualizzato\n⚽ $nomeCampo',
            notes:
                idPartita, // 🟢 Memorizziamo l'ID esatto della partita per il match immediato
            color: AppTheme.neonOrange,
            isAllDay: false,
          ),
        );
      } catch (e) {}
    }

    for (var c in state.chiusureStraordinarie) {
      try {
        final start = _parseDateTimeSicuro(
          c['data_inizio'].toString(),
          c['orario_inizio'].toString(),
        );

        final end = _parseDateTimeSicuro(
          c['data_fine'].toString(),
          c['orario_fine'].toString(),
        );

        tempAppointments.add(
          Appointment(
            startTime: start,
            endTime: end,
            subject: '⛔ CHIUSO',
            color: Colors.red.shade900,
            isAllDay: false,
          ),
        );
      } catch (e) {}
    }

    // =======================================================================
    // CHIUSURE AUTOMATICHE TRA DUE FASCE DI APERTURA
    //
    // Esempio:
    // 13:00 - 16:00
    // 18:00 - 21:00
    //
    // Il calendario visualizza 13:00 - 21:00,
    // ma il periodo 16:00 - 18:00 viene rappresentato come CHIUSO.
    // =======================================================================

    double? parseHourLocale(String? value) {
      if (value == null || value.isEmpty) {
        return null;
      }

      final parts = value.split(':');

      final double? hour = double.tryParse(parts[0]);

      if (hour == null) {
        return null;
      }

      final double minutes = parts.length > 1
          ? double.tryParse(parts[1]) ?? 0.0
          : 0.0;

      return hour + (minutes / 60.0);
    }

    final DateTime oggi = DateTime.now();

    for (int i = -30; i <= 30; i++) {
      final DateTime giornoCorrente = oggi.add(Duration(days: i));

      final int giornoSettimana = giornoCorrente.weekday;

      final orarioGiorno = state.orariSocieta.firstWhere(
        (o) => o['giorno_settimana'] == giornoSettimana,
        orElse: () => <String, dynamic>{},
      );

      if (orarioGiorno.isEmpty) {
        continue;
      }

      // ================================================================
      // GIORNO COMPLETAMENTE CHIUSO
      // ================================================================

      if (orarioGiorno['is_chiuso'] == true) {
        tempAppointments.add(
          Appointment(
            startTime: DateTime(
              giornoCorrente.year,
              giornoCorrente.month,
              giornoCorrente.day,
              0,
              0,
            ),
            endTime: DateTime(
              giornoCorrente.year,
              giornoCorrente.month,
              giornoCorrente.day,
              23,
              59,
              59,
            ),
            subject: '⛔ GIORNO DI CHIUSURA',
            color: Colors.grey.shade900,
            isAllDay: false,
          ),
        );

        continue;
      }

      // ================================================================
      // DUE FASCE DI APERTURA
      // ================================================================

      final double? primaChiusura = parseHourLocale(
        orarioGiorno['orario_chiusura']?.toString(),
      );

      final double? secondaApertura = parseHourLocale(
        orarioGiorno['orario_apertura_2']?.toString(),
      );

      // Se ad esempio abbiamo:
      //
      // 13:00 - 16:00
      // 18:00 - 21:00
      //
      // creiamo automaticamente:
      //
      // 16:00 - 18:00 = CHIUSO

      if (primaChiusura != null &&
          secondaApertura != null &&
          secondaApertura > primaChiusura) {
        final int startHour = primaChiusura.floor();

        final int startMinute = ((primaChiusura - startHour) * 60).round();

        final int endHour = secondaApertura.floor();

        final int endMinute = ((secondaApertura - endHour) * 60).round();

        tempAppointments.add(
          Appointment(
            id: 'chiusura_fascia_${giornoCorrente.toIso8601String()}',
            startTime: DateTime(
              giornoCorrente.year,
              giornoCorrente.month,
              giornoCorrente.day,
              startHour,
              startMinute,
            ),
            endTime: DateTime(
              giornoCorrente.year,
              giornoCorrente.month,
              giornoCorrente.day,
              endHour,
              endMinute,
            ),
            subject: '⛔ CHIUSO',
            color: Colors.grey.shade800,
            isAllDay: false,
          ),
        );
      }
    }

    state = state.copyWith(
      prenotazioniVisibili: tempAppointments,
      idCampoSelezionato: campoId,
    );
  }

  void aggiornaGiornoCalendario(DateTime giorno) {
    _calcolaOrariGriglia(giorno);
    filtraEConvertiDatiCalendario();
  }

  void aggiornaDataCorrente(String data) {
    state = state.copyWith(stringaDataCorrente: data);
  }

  void avviaRealtimePartite({
    required String? idSocieta,
    required Utente? utenteLoggato,
  }) {
    _realtimeChannel = Supabase.instance.client
        .channel('partite_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'partite',
          callback: (payload) {
            debugPrint('Realtime: cambio rilevato nelle partite');
            inizializza(idSocieta: idSocieta, utenteLoggato: utenteLoggato);
          },
        )
        .subscribe();
  }

  void cancellaRealtime() {
    _realtimeChannel?.unsubscribe();
  }
}

// ===== PROVIDER =====
final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
