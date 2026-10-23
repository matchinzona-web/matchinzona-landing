import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/repositories/partita_repository.dart';

class StatisticheState {
  final List<Map<String, dynamic>> partiteComplete;
  final List<Map<String, dynamic>> riepiloghiMensili;
  final bool isLoading;
  final String periodoSelezionato;
  final int? annoSelezionato;

  const StatisticheState({
    this.partiteComplete = const [],
    this.riepiloghiMensili = const [],
    this.isLoading = true,
    this.periodoSelezionato = 'Mese',
    this.annoSelezionato,
  });

  StatisticheState copyWith({
    List<Map<String, dynamic>>? partiteComplete,
    List<Map<String, dynamic>>? riepiloghiMensili,
    bool? isLoading,
    String? periodoSelezionato,
    int? annoSelezionato,
  }) {
    return StatisticheState(
      partiteComplete: partiteComplete ?? this.partiteComplete,
      riepiloghiMensili: riepiloghiMensili ?? this.riepiloghiMensili,
      isLoading: isLoading ?? this.isLoading,
      periodoSelezionato: periodoSelezionato ?? this.periodoSelezionato,
      annoSelezionato: annoSelezionato ?? this.annoSelezionato,
    );
  }

  double calcolaRicavoPartita(Map<String, dynamic> partita) {
    final importoStorico = partita['importo_totale'];

    if (importoStorico == null) {
      return 0.0;
    }

    return (importoStorico as num).toDouble();
  }

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
    } catch (_) {
      return false;
    }
  }

  List<int> get anniDisponibili {
    final Set<int> anni = {};

    // Anni presenti nei riepiloghi mensili con un incasso reale.
    for (final r in riepiloghiMensili) {
      final double incasso = (r['incasso_totale'] as num?)?.toDouble() ?? 0.0;

      if (incasso > 0) {
        final anno = r['anno'];
        if (anno is num) {
          anni.add(anno.toInt());
        }
      }
    }

    // Anni presenti nelle partite dettagliate con importo salvato.
    for (final p in partiteComplete) {
      if (!isPartitaTerminata(p)) continue;

      final double importo = calcolaRicavoPartita(p);
      if (importo <= 0) continue;

      try {
        final data = DateTime.parse(p['data_partita'].toString().split(' ')[0]);

        anni.add(data.year);
      } catch (_) {}
    }

    final lista = anni.toList();
    lista.sort((a, b) => b.compareTo(a));

    return lista;
  }

  int? get annoAttivo {
    if (anniDisponibili.isEmpty) {
      return null;
    }

    if (annoSelezionato != null && anniDisponibili.contains(annoSelezionato)) {
      return annoSelezionato;
    }

    return anniDisponibili.first;
  }

  bool _meseCampoGiaArchiviato(Map<String, dynamic> partita) {
    try {
      final data = DateTime.parse(
        partita['data_partita'].toString().split(' ')[0],
      );

      final String idCampo = partita['id_campo'].toString();

      return riepiloghiMensili.any((r) {
        return r['id_campo'].toString() == idCampo &&
            (r['anno'] as num).toInt() == data.year &&
            (r['mese'] as num).toInt() == data.month;
      });
    } catch (_) {
      return false;
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
      }

      if (periodoSelezionato == 'Settimana') {
        final oggi = DateTime(adesso.year, adesso.month, adesso.day);

        final inizioSettimana = oggi.subtract(Duration(days: oggi.weekday - 1));

        final fineSettimana = inizioSettimana.add(const Duration(days: 7));

        return !dataPartita.isBefore(inizioSettimana) &&
            dataPartita.isBefore(fineSettimana);
      }

      if (periodoSelezionato == 'Mese') {
        return dataPartita.year == adesso.year &&
            dataPartita.month == adesso.month;
      }

      if (periodoSelezionato == 'Anno') {
        final anno = annoAttivo;
        if (anno == null) return false;

        return dataPartita.year == anno;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  List<Map<String, dynamic>> get partiteFiltrate {
    final partite = partiteComplete.where((p) {
      if (!isPartitaTerminata(p)) {
        return false;
      }

      if (!rientraNelPeriodo(p['data_partita'].toString())) {
        return false;
      }

      // Se stiamo guardando l'anno e quel campo/mese
      // è già stato archiviato, non contiamo nuovamente
      // la singola partita.
      if (periodoSelezionato == 'Anno' && _meseCampoGiaArchiviato(p)) {
        return false;
      }

      return true;
    }).toList();

    return partite;
  }

  List<Map<String, dynamic>> get riepiloghiAnnoSelezionato {
    if (periodoSelezionato != 'Anno') {
      return [];
    }

    final anno = annoAttivo;
    if (anno == null) {
      return [];
    }

    return riepiloghiMensili.where((r) {
      final valoreAnno = r['anno'];
      if (valoreAnno is! num) return false;

      return valoreAnno.toInt() == anno;
    }).toList();
  }

  double get guadagnoTotale {
    double totale = 0.0;

    for (final p in partiteFiltrate) {
      totale += calcolaRicavoPartita(p);
    }

    if (periodoSelezionato == 'Anno') {
      for (final r in riepiloghiAnnoSelezionato) {
        totale += (r['incasso_totale'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return totale;
  }

  int get numeroPartiteVisualizzate {
    int totale = partiteFiltrate.length;

    if (periodoSelezionato == 'Anno') {
      for (final r in riepiloghiAnnoSelezionato) {
        totale += (r['numero_partite'] as num?)?.toInt() ?? 0;
      }
    }

    return totale;
  }

  Map<String, double> get guadagniPerCampo {
    final Map<String, double> risultato = {};

    // Partite dettagliate recenti
    for (final p in partiteFiltrate) {
      final String nomeCampo =
          p['campo']?['nome_campo']?.toString() ?? 'Campo sconosciuto';

      risultato[nomeCampo] =
          (risultato[nomeCampo] ?? 0.0) + calcolaRicavoPartita(p);
    }

    // Mesi già archiviati
    if (periodoSelezionato == 'Anno') {
      for (final r in riepiloghiAnnoSelezionato) {
        final String nomeCampo =
            r['nome_campo']?.toString() ?? 'Campo sconosciuto';

        final double incasso = (r['incasso_totale'] as num?)?.toDouble() ?? 0.0;

        risultato[nomeCampo] = (risultato[nomeCampo] ?? 0.0) + incasso;
      }
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
      final partite = await _repository.fetchPartiteCompletatePerGuadagni(
        idSocieta,
      );

      final riepiloghi = await _repository.fetchRiepiloghiMensiliGuadagni(
        idSocieta,
      );

      state = state.copyWith(
        partiteComplete: partite,
        riepiloghiMensili: riepiloghi,
      );
    } catch (_) {
      state = state.copyWith(partiteComplete: [], riepiloghiMensili: []);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void impostaPeriodo(String periodo) {
    state = state.copyWith(periodoSelezionato: periodo);
  }

  void impostaAnno(int anno) {
    state = state.copyWith(periodoSelezionato: 'Anno', annoSelezionato: anno);
  }
}

final statisticheProvider =
    NotifierProvider<StatisticheNotifier, StatisticheState>(
      StatisticheNotifier.new,
    );
