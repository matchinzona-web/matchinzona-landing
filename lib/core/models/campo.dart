import 'societa.dart';

class TariffaSport {
  final String sport;
  final double prezzo;

  TariffaSport({required this.sport, required this.prezzo});

  factory TariffaSport.fromJson(Map<String, dynamic> json) {
    return TariffaSport(
      sport: json['sport'] as String,
      prezzo: (json['prezzo'] as num).toDouble(),
    );
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
