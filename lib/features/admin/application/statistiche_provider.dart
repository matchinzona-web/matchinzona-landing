import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/repositories/partita_repository.dart';

class StatisticheState {
  final List<Map<String, dynamic>> partiteComplete;
  final bool isLoading;
  final String periodoSelezionato;

  const StatisticheState({
    this.partiteComplete = const [],
    this.isLoading = true,
    this.periodoSelezionato = 'Mese',
  });

  StatisticheState copyWith({
    List<Map<String, dynamic>>? partiteComplete,
    bool? isLoading,
    String? periodoSelezionato,
  }) {
    return StatisticheState(
      partiteComplete: partiteComplete ?? this.partiteComplete,
      isLoading: isLoading ?? this.isLoading,
      periodoSelezionato: periodoSelezionato ?? this.periodoSelezionato,
    );
  }

  // ricavo di una singola partita dinamico
  double calcolaRicavoPartita(Map<String, dynamic> partita) {
    final importoStorico = partita['importo_totale'];

    if (importoStorico != null) {
      return (importoStorico as num).toDouble();
    }
    final campo = partita['campo'] ?? {};
    final String nomeCampo = (campo['nome_campo'] ?? '')
        .toString()
        .toLowerCase();
    final int maxGiocatori =
        partita['max_giocatori'] as int? ??
        campo['numero_di_giocatori'] as int? ??
        2;

    // 🟢 1. Estrazione tariffe e prezzo base
    final List<dynamic> tariffeRaw =
        campo['tariffe_sport'] as List<dynamic>? ?? [];
    double prezzoAllOra = (campo['prezzo'] as num?)?.toDouble() ?? 0.0;

    // 🟢 2. Se ci sono tariffe specifiche (es. Tennis Doppio vs Singolo), applica quella esatta
    if (tariffeRaw.isNotEmpty) {
      final bool isDoppio = nomeCampo.contains('tennis') && maxGiocatori == 4;
      final tariffa = tariffeRaw.firstWhere((t) {
        final String s = (t['sport'] ?? '').toString().toLowerCase();
        if (isDoppio) return s.contains('doppio');
        if (nomeCampo.contains('tennis')) return s.contains('singolo');
        return true;
      }, orElse: () => null);

      if (tariffa != null && tariffa['prezzo'] != null) {
        prezzoAllOra = (tariffa['prezzo'] as num).toDouble();
      }
    }

    // 🟢 3. Calcolo su durata oraria
    try {
      final inizio = partita['orario_inizio'].toString().split(':');
      final fine = partita['orario_fine'].toString().split(':');
      final int minInizio = int.parse(inizio[0]) * 60 + int.parse(inizio[1]);
      final int minFine = int.parse(fine[0]) * 60 + int.parse(fine[1]);
      final double oreTotali = (minFine - minInizio) / 60.0;
      return oreTotali * prezzoAllOra;
    } catch (e) {
      return prezzoAllOra;
    }
  }

  bool rientraNelPeriodo(String dataPartitaStr) {
    try {
      final dataPartita = DateTime.parse(dataPartitaStr.split(' ')[0]);
      final adesso = DateTime.now();
      if (periodoSelezionato == 'Oggi') {
        return dataPartita.year == adesso.year &&
            dataPartita.month == adesso.month &&
            dataPartita.day == adesso.day;
      } else if (periodoSelezionato == 'Settimana') {
        final inizioSettimana = adesso.subtract(
          Duration(days: adesso.weekday - 1),
        );
        final dataInizioPura = DateTime(
          inizioSettimana.year,
          inizioSettimana.month,
          inizioSettimana.day,
        );
        return dataPartita.isAfter(
          dataInizioPura.subtract(const Duration(seconds: 1)),
        );
      } else if (periodoSelezionato == 'Mese') {
        return dataPartita.year == adesso.year &&
            dataPartita.month == adesso.month;
      } else if (periodoSelezionato == 'Anno') {
        return dataPartita.year == adesso.year;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 🟢 Considera la partita conclusa se la data/ora di fine è precedente al momento attuale
  bool isPartitaTerminata(Map<String, dynamic> p) {
    try {
      final String dStr = p['data_partita']
          .toString()
          .split('T')[0]
          .split(' ')[0];
      final String fineStr =
          p['orario_fine']?.toString().substring(0, 5) ?? '23:59';
      final DateTime finePartita = DateTime.parse('$dStr $fineStr:00');

      return DateTime.now().isAfter(finePartita);
    } catch (e) {
      return false;
    }
  }

  List<Map<String, dynamic>> get partiteFiltrate => partiteComplete
      .where(
        (p) =>
            isPartitaTerminata(p) &&
            rientraNelPeriodo(p['data_partita'].toString()),
      )
      .toList();

  double get guadagnoTotale =>
      partiteFiltrate.fold(0.0, (sum, p) => sum + calcolaRicavoPartita(p));

  Map<String, double> get guadagniPerCampo {
    final Map<String, double> risultato = {};
    for (var p in partiteFiltrate) {
      final String nomeCampo = p['campo']?['nome_campo'] ?? 'Campo Sconosciuto';
      risultato[nomeCampo] =
          (risultato[nomeCampo] ?? 0.0) + calcolaRicavoPartita(p);
    }
    return risultato;
  }
}

class StatisticheNotifier extends Notifier<StatisticheState> {
  final PartitaRepository _repository = PartitaRepository();

  @override
  StatisticheState build() => const StatisticheState();

  Future<void> caricaDati(String idSocieta) async {
    state = state.copyWith(isLoading: true);
    try {
      final dati = await _repository.fetchPartiteCompletatePerGuadagni(
        idSocieta,
      );
      state = state.copyWith(partiteComplete: dati);
    } catch (e) {
      state = state.copyWith(partiteComplete: []);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void impostaPeriodo(String periodo) {
    state = state.copyWith(periodoSelezionato: periodo);
  }
}

final statisticheProvider =
    NotifierProvider<StatisticheNotifier, StatisticheState>(
      StatisticheNotifier.new,
    );
