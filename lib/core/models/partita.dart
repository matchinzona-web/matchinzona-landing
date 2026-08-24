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

  int numeroGiocatoriPrenotati;
  String statoPartita;
  bool isPublic;
  final bool isPagato;
  final int? maxGiocatori; // 🟢 Campo opzionale dal DB

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
  });

  /// 🟢 GETTER CENTRALE PER I GIOCATORI MASSIMI
  /// 🟢 GETTER INTELLIGENTE PER I POSTI MASSIMI REALI
  int get maxGiocatoriReali {
    // 1. Se il database ha salvato un valore esplicito, usiamo quello
    if (maxGiocatori != null && maxGiocatori! > 0) {
      return maxGiocatori!;
    }

    // 2. Se è tennis e ha più di 2 giocatori, è un doppio (4 posti)
    if (campo.nomeCampo.toLowerCase().contains('tennis') &&
        numeroGiocatoriPrenotati > 2) {
      return 4;
    }

    // 3. Altrimenti usa il default del campo (2 per il tennis)
    return campo.numeroDiGiocatori;
  }

  /// 🟢 CALCOLO QUOTA SINGOLA DINAMICO (Prende la tariffa corretta dalle tariffe del campo)
  double get quotaSingolaGiocatore {
    final int maxPosti = maxGiocatoriReali;
    if (maxPosti == 0) return 0.0;

    double prezzoTotaleCampo = campo.prezzo;

    // Se è Tennis Doppio (4 giocatori), cerca la tariffa "Tennis Doppio" in tariffeSport
    if (campo.nomeCampo.toLowerCase().contains('tennis') && maxPosti == 4) {
      final tariffaDoppio = campo.tariffeSport.firstWhere(
        (t) => t.sport.toLowerCase().contains('doppio'),
        orElse: () => TariffaSport(sport: 'doppio', prezzo: campo.prezzo),
      );

      // Se ha trovato la tariffa specifica (es. 20€), la usa. Altrimenti fallback intelligente a 20€ (o 1.33x)
      if (tariffaDoppio.prezzo > campo.prezzo) {
        prezzoTotaleCampo = tariffaDoppio.prezzo;
      } else if (campo.prezzo == 15.0) {
        prezzoTotaleCampo =
            20.0; // Fallback se tariffeSport non è popolato nei Miei Match
      }
    }

    return prezzoTotaleCampo / maxPosti; // Es: 20€ / 4 = 5.00€
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

    return Partita(
      id: json['id'] as String,
      campo: Campo.fromJson(json['campo'] as Map<String, dynamic>),
      organizzatore: Utente.fromJson(
        json['organizzatore'] as Map<String, dynamic>,
      ),
      dataPartita: DateTime.parse(json['data_partita'] as String),
      orarioInizio: json['orario_inizio'] as String,
      orarioFine: json['orario_fine'] as String,
      numeroGiocatoriPrenotati: json['numero_giocatori_prenotati'] as int? ?? 1,
      statoPartita: json['stato_partita'] as String? ?? 'aperta',
      isPublic: json['is_public'] as bool? ?? true,
      isPagato: json['is_pagato'] as bool? ?? false,
      maxGiocatori:
          json['max_giocatori']
              as int?, // 🟢 FONDAMENTALE: Legge la nuova colonna da Supabase!
      listaGiocatoriIscritti: giocatoriParsati,
    );
  }
}
