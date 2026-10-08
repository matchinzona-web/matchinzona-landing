class Notifica {
  final String id;
  final String idUtente;
  final String titolo;
  final String messaggio;
  final bool letto;
  final String? tipo;
  final String? idPartita;
  final DateTime createdAt;
  Notifica({
    required this.id,
    required this.idUtente,
    required this.titolo,
    required this.messaggio,
    required this.letto,
    this.tipo,
    this.idPartita,
    required this.createdAt,
  });

  factory Notifica.fromJson(Map<String, dynamic> json) {
    return Notifica(
      id: json['id'] as String,
      idUtente: json['id_utente'] as String,
      titolo: json['titolo'] as String,
      messaggio: json['messaggio'] as String,
      letto: json['letto'] as bool? ?? false,
      tipo: json['tipo'] as String?,
      idPartita: json['id_partita'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
