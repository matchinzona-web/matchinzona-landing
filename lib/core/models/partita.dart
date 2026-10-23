import 'package:app_campi/core/models/giocatore_partita.dart';
import 'campo.dart';
import 'utente.dart';

class Partita {
  final String id;
  final Campo campo;
  final Utente organizzatore;
  final DateTime dataPartita;
  final String orarioInizio;
  final String orarioFine;
  final String? sport;

  int numeroGiocatoriPrenotati;
  String statoPartita;
  bool isPublic;
  final bool isPagato;
  final int? maxGiocatori; // 🟢 Campo opzionale dal DB
  final String? stripePaymentIntentId;
  final int? importoRimborsabileCentesimi;
  final double? importoTotale;

  List<GiocatorePartita> listaGiocatoriIscritti;

  Partita({
    required this.id,
    required this.campo,
    required this.organizzatore,
    required this.dataPartita,
    required this.orarioInizio,
    required this.orarioFine,
    this.numeroGiocatoriPrenotati = 1,
    this.statoPartita = 'aperta',
    this.isPublic = true,
    this.isPagato = false,
    this.maxGiocatori,
    this.listaGiocatoriIscritti = const [],
    this.stripePaymentIntentId,
    this.importoRimborsabileCentesimi,
    this.importoTotale,
    this.sport,
  });

  int get maxGiocatoriReali {
    if (maxGiocatori != null && maxGiocatori! > 0) {
      return maxGiocatori!;
    }

    // 3. Altrimenti usa il default del campo (2 per il tennis)
    return campo.numeroDiGiocatori;
  }

  double get prezzoTotalePrenotazione {
    if (importoTotale != null) {
      return importoTotale!;
    }

    // Compatibilità temporanea con prenotazioni senza importo salvato.
    return campo.prezzo;
  }

  double get quotaSingolaGiocatore {
    final maxPosti = maxGiocatoriReali;

    if (maxPosti <= 0) return 0.0;

    return prezzoTotalePrenotazione / maxPosti;
  }

  /// 🟢 AGGIORNATI PER USARE maxGiocatoriReali AL POSTO DI campo.numeroDiGiocatori
  int get postiMancanti => maxGiocatoriReali - numeroGiocatoriPrenotati;

  bool get eCompleta => postiMancanti <= 0 || statoPartita == 'completa';

  factory Partita.fromJson(Map<String, dynamic> json) {
    List<GiocatorePartita> giocatoriParsati = [];

    if (json['giocatori_partita'] != null) {
      final List<dynamic> partecipantiRaw = json['giocatori_partita'];

      giocatoriParsati = partecipantiRaw
          .map((e) => GiocatorePartita.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final organizzatoreRaw = json['organizzatore'];

    final Utente organizzatoreParsato;

    if (organizzatoreRaw is Map) {
      final mappaOrganizzatore = Map<String, dynamic>.from(organizzatoreRaw);

      organizzatoreParsato = Utente(
        id:
            mappaOrganizzatore['id']?.toString() ??
            json['id_organizzatore']?.toString() ??
            '',
        nome: mappaOrganizzatore['nome']?.toString() ?? 'Giocatore',
        cognome: mappaOrganizzatore['cognome']?.toString() ?? 'MatchInZona',
        email: mappaOrganizzatore['email']?.toString() ?? '',
        dataNascita: mappaOrganizzatore['data_nascita'] != null
            ? DateTime.tryParse(mappaOrganizzatore['data_nascita'].toString())
            : null,
        telefono: mappaOrganizzatore['telefono']?.toString(),
        indirizzo: mappaOrganizzatore['indirizzo']?.toString(),
        createdAt: mappaOrganizzatore['created_at'] != null
            ? DateTime.tryParse(mappaOrganizzatore['created_at'].toString())
            : null,
        ruolo: switch (mappaOrganizzatore['tipo'] as int?) {
          1 => Ruolo.gestore,
          _ => Ruolo.giocatore,
        },
        livelliSport: mappaOrganizzatore['livelli_sport'] is Map
            ? Map<String, dynamic>.from(
                mappaOrganizzatore['livelli_sport'] as Map,
              )
            : null,
      );
    } else {
      organizzatoreParsato = Utente(
        id: json['id_organizzatore']?.toString() ?? '',
        nome: 'Giocatore',
        cognome: 'MatchInZona',
        email: '',
      );
    }

    return Partita(
      id: json['id'] as String,
      campo: Campo.fromJson(json['campo'] as Map<String, dynamic>),
      organizzatore: organizzatoreParsato,
      dataPartita: DateTime.parse(json['data_partita'] as String),
      orarioInizio: json['orario_inizio'] as String,
      orarioFine: json['orario_fine'] as String,
      sport: json['sport'] as String?,
      numeroGiocatoriPrenotati: json['numero_giocatori_prenotati'] as int? ?? 1,
      statoPartita: json['stato_partita'] as String? ?? 'aperta',
      isPublic: json['is_public'] as bool? ?? true,
      isPagato: json['is_pagato'] as bool? ?? false,
      maxGiocatori:
          json['max_giocatori']
              as int?, // 🟢 FONDAMENTALE: Legge la nuova colonna da Supabase!
      listaGiocatoriIscritti: giocatoriParsati,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      importoRimborsabileCentesimi:
          json['importo_rimborsabile_centesimi'] as int?,
      importoTotale: (json['importo_totale'] as num?)?.toDouble(),
    );
  }

  String get sportNormalizzato => (sport ?? '').trim().toLowerCase();

  bool get isTennis => sportNormalizzato.startsWith('tennis');

  bool get isCalcio => sportNormalizzato.startsWith('calcio');

  bool get isPadel => sportNormalizzato.startsWith('padel');

  bool get isBasket =>
      sportNormalizzato.startsWith('basket') ||
      sportNormalizzato.startsWith('pallacanestro');

  bool get isPallavolo =>
      sportNormalizzato.startsWith('pallavolo') ||
      sportNormalizzato.startsWith('volley');
}
