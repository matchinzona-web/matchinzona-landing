import 'societa.dart';

class TariffaSport {
  final String sport;

  // Prezzo di riferimento mantenuto per compatibilità.
  final double prezzo;

  // Tariffe effettivamente abilitate: 60 e/o 90 minuti.
  final Map<int, double> prezziDurata;

  TariffaSport({
    required this.sport,
    required this.prezzo,
    Map<int, double>? prezziDurata,
  }) : prezziDurata = prezziDurata ?? {60: prezzo};

  factory TariffaSport.fromJson(Map<String, dynamic> json) {
    final sport = json['sport'] as String;
    final prezzo = (json['prezzo'] as num).toDouble();
    final raw = json['prezzi_durata'];

    // I dati vecchi non hanno prezzi_durata:
    // restano automaticamente prenotabili per 60 minuti.
    if (raw is! Map) {
      return TariffaSport(
        sport: sport,
        prezzo: prezzo,
        prezziDurata: {60: prezzo},
      );
    }

    final Map<int, double> durate = {};

    for (final durata in [60, 90]) {
      final valore = raw[durata.toString()];

      if (valore is num && valore > 0) {
        durate[durata] = valore.toDouble();
      }
    }

    return TariffaSport(sport: sport, prezzo: prezzo, prezziDurata: durate);
  }

  List<int> get durateDisponibili {
    final durate = prezziDurata.keys.toList()..sort();
    return durate;
  }

  bool supportaDurata(int minuti) {
    return prezziDurata.containsKey(minuti);
  }

  double? prezzoPerDurata(int minuti) {
    return prezziDurata[minuti];
  }
}

class Campo {
  final String id;
  final String idSocieta;
  final String nomeCampo;
  final int numeroDiGiocatori;
  final double prezzo;
  final bool coperto;
  final String? fotoUrl;
  final DateTime? createdAt;
  final Societa? societa;
  final List<TariffaSport> tariffeSport; // AGGIUNTO

  Campo({
    required this.id,
    required this.idSocieta,
    required this.nomeCampo,
    required this.numeroDiGiocatori,
    required this.prezzo,
    this.coperto = false,
    this.fotoUrl,
    this.createdAt,
    this.societa,
    this.tariffeSport = const [],
  });

  String get nomeSocieta => societa?.nomeSocieta ?? "Struttura Sportiva";
  String get citta => societa?.citta ?? "Città non specificata";
  String get via => societa?.via ?? "Via non specificata";

  // Ritorna gli sport disponibili su questo campo
  List<String> get sportDisponibili =>
      tariffeSport.map((t) => t.sport).toList();

  // Controlla se il campo supporta uno sport specifico
  bool supportaSport(String sport) {
    final cercato = sport.trim().toLowerCase();

    return tariffeSport.any((t) => t.sport.trim().toLowerCase() == cercato);
  }

  factory Campo.fromJson(Map<String, dynamic> json) {
    List<TariffaSport> tariffe = [];
    if (json['tariffe_sport'] != null) {
      tariffe = (json['tariffe_sport'] as List)
          .map((t) => TariffaSport.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return Campo(
      id: json['id'] as String,
      idSocieta: json['id_societa'] as String,
      nomeCampo: json['nome_campo'] as String,
      numeroDiGiocatori: json['numero_di_giocatori'] as int,
      prezzo: (json['prezzo'] as num).toDouble(),
      coperto: json['coperto'] as bool? ?? false,
      fotoUrl: json['foto_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      societa: json['societa'] != null
          ? Societa.fromJson(json['societa'] as Map<String, dynamic>)
          : null,
      tariffeSport: tariffe,
    );
  }
}
