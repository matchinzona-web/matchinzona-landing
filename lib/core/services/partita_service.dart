import '../models/partita.dart';
import '../models/campo.dart';
import '../models/utente.dart';
import '../repositories/partita_repository.dart';
import '../repositories/orario_societa_repository.dart';
import '../repositories/chiusura_straordinaria_repository.dart';

enum MetodoPagamento { nessuno, pagaOra, inSede }

class RisultatoCreazionePartita {
  final String? idPartita;
  final String? errore;

  bool get isSuccesso => errore == null && idPartita != null;

  RisultatoCreazionePartita.successo(this.idPartita) : errore = null;
  RisultatoCreazionePartita.fallimento(this.errore) : idPartita = null;
}

class PartitaService {
  final PartitaRepository _repository;
  final OrarioSocietaRepository _orarioRepository;
  final ChiusuraStraordinariaRepository _chiusuraRepository;

  static const int oreAnnullamentoAutomatico = 2;
  static const int minutiLimiteAbbandono = 30;
  static const int minutiMinPreavvisoCreazione = 30;

  PartitaService({
    PartitaRepository? repository,
    OrarioSocietaRepository? orarioRepository,
    ChiusuraStraordinariaRepository? chiusuraRepository,
  }) : _repository = repository ?? PartitaRepository(),
       _orarioRepository = orarioRepository ?? OrarioSocietaRepository(),
       _chiusuraRepository =
           chiusuraRepository ?? ChiusuraStraordinariaRepository();

  Future<void> _sincronizzaStatoPartita(Partita partita) async {
    final statoReale = getStatoRealePartita(partita);
    if (statoReale != partita.statoPartita) {
      await _repository.aggiornaStatoPartita(partita.id, statoReale);
    }
  }

  Future<List<Map<String, dynamic>>> ottieniPrenotazioniSocieta(
    String idSocieta,
  ) async {
    final tutteLePartite = await _repository.fetchPrenotazioniGestore(
      idSocieta,
    );
    return tutteLePartite
        .where((p) => p['stato_partita'] == 'completa')
        .toList();
  }

  DateTime _calcolaInizioEsatto(DateTime data, String orarioInizio) {
    final parti = orarioInizio.split(':');
    return DateTime(
      data.year,
      data.month,
      data.day,
      int.parse(parti[0]),
      int.parse(parti[1]),
    );
  }

  int _orarioInMinuti(String orario) {
    final parti = orario.trim().split(':');

    final int ore = int.parse(parti[0]);
    final int minuti = int.parse(parti[1]);

    return (ore * 60) + minuti;
  }

  // 🔴 CORRETTO: Ora usa partita.maxGiocatoriReali
  String getStatoRealePartita(Partita partita) {
    if (partita.statoPartita == 'completa' ||
        partita.statoPartita == 'annullata') {
      return partita.statoPartita;
    }

    final inizioEsatto = _calcolaInizioEsatto(
      partita.dataPartita,
      partita.orarioInizio,
    );

    if (DateTime.now().isAfter(inizioEsatto)) {
      return 'annullata';
    }

    final int maxPosti = partita.maxGiocatoriReali;

    if (partita.numeroGiocatoriPrenotati >= maxPosti) {
      return 'completa';
    }

    if (partita.numeroGiocatoriPrenotati <= 0) {
      return 'annullata';
    }

    return 'aperta_a_rischio';
  }

  Future<List<Partita>> getPartiteDisponibili() async {
    try {
      final datiGrezzi = await _repository.getPartiteDatiGrezzi();
      final partite = datiGrezzi.map((json) => Partita.fromJson(json)).toList();
      for (final p in partite) {
        await _sincronizzaStatoPartita(p);
      }
      return partite;
    } catch (_) {
      return [];
    }
  }

  double _calcolaImportoPartita({
    required Campo campo,
    required String? sport,
    required String orarioInizio,
    required String orarioFine,
  }) {
    double prezzoOrario = campo.prezzo;

    final sportNormalizzato = sport?.trim().toLowerCase();

    if (sportNormalizzato != null &&
        sportNormalizzato.isNotEmpty &&
        campo.tariffeSport.isNotEmpty) {
      for (final tariffa in campo.tariffeSport) {
        if (tariffa.sport.trim().toLowerCase() == sportNormalizzato) {
          prezzoOrario = tariffa.prezzo;
          break;
        }
      }
    }

    try {
      final inizio = orarioInizio.split(':');
      final fine = orarioFine.split(':');

      final minutiInizio = int.parse(inizio[0]) * 60 + int.parse(inizio[1]);

      int minutiFine = int.parse(fine[0]) * 60 + int.parse(fine[1]);

      if (minutiFine == 0 && minutiInizio > 0) {
        minutiFine = 24 * 60;
      }

      final durataOre = (minutiFine - minutiInizio) / 60.0;

      return prezzoOrario * durataOre;
    } catch (_) {
      return prezzoOrario;
    }
  }

  Future<RisultatoCreazionePartita> creaNuovaPartita({
    required Campo campo,
    required Utente organizzatore,
    required String sport,
    required DateTime dataPartita,
    required String orarioInizio,
    required String orarioFine,
    int ospitiExtra = 0,
    bool isPartitaPrivata = false,
    bool isPagato = false,
    String? stripePaymentIntentId,
    int? importoRimborsabileCentesimi,
  }) async {
    try {
      if (ospitiExtra < 0) {
        return RisultatoCreazionePartita.fallimento(
          'Il numero di ospiti non può essere negativo.',
        );
      }

      final sportNormalizzato = sport.trim().toLowerCase();

      int maxGiocatori;

      switch (sportNormalizzato) {
        case 'tennis_singolo':
          maxGiocatori = 2;
          break;

        case 'tennis_doppio':
        case 'padel':
          maxGiocatori = 4;
          break;

        case 'calcio_5':
          maxGiocatori = 10;
          break;

        case 'calcio_6':
          maxGiocatori = 12;
          break;

        case 'calcio_7':
          maxGiocatori = 14;
          break;

        case 'calcio_8':
          maxGiocatori = 16;
          break;

        case 'calcio_11':
          maxGiocatori = 22;
          break;

        case 'basket':
          maxGiocatori = 10;
          break;

        case 'pallavolo':
          maxGiocatori = 12;
          break;

        default:
          maxGiocatori = campo.numeroDiGiocatori;
      }

      final int giocatoriTotaliIniziali = 1 + ospitiExtra;
      final bool isPartitaGiaCompleta = giocatoriTotaliIniziali >= maxGiocatori;
      final bool isPartitaAperta = !isPartitaPrivata && !isPartitaGiaCompleta;

      final inizioEsatto = _calcolaInizioEsatto(dataPartita, orarioInizio);
      final adesso = DateTime.now();

      if (adesso.isAfter(inizioEsatto)) {
        return RisultatoCreazionePartita.fallimento(
          'Non puoi creare una partita in un orario già passato.',
        );
      }

      if (isPartitaAperta &&
          adesso.isAfter(
            inizioEsatto.subtract(
              const Duration(hours: oreAnnullamentoAutomatico),
            ),
          )) {
        return RisultatoCreazionePartita.fallimento(
          'Non puoi aprire una partita quando mancano meno di '
          '$oreAnnullamentoAutomatico ore all\'inizio.',
        );
      }

      if (!isPartitaAperta &&
          adesso.isAfter(
            inizioEsatto.subtract(
              const Duration(minutes: minutiMinPreavvisoCreazione),
            ),
          )) {
        return RisultatoCreazionePartita.fallimento(
          'Puoi prenotare il campo intero fino a '
          '$minutiMinPreavvisoCreazione minuti prima dell\'inizio.',
        );
      }

      if (giocatoriTotaliIniziali > maxGiocatori) {
        return RisultatoCreazionePartita.fallimento(
          'Errore: troppi giocatori per questo campo.',
        );
      }

      if (await _repository.isSlotOccupato(
        campo.id,
        dataPartita,
        orarioInizio,
      )) {
        return RisultatoCreazionePartita.fallimento(
          'Lo slot è già occupato da una partita completa.',
        );
      }

      final partiteEsistenti = await _repository.getPartiteAperteNelloSlot(
        idCampo: campo.id,
        dataPartita: dataPartita,
        orarioInizio: orarioInizio,
      );

      final giaCreatoInSlot = partiteEsistenti.any(
        (p) => p['id_organizzatore'] == organizzatore.id,
      );
      if (giaCreatoInSlot) {
        return RisultatoCreazionePartita.fallimento(
          'Hai già una partita aperta in questo orario.',
        );
      }

      if (!await _isSocietaAperta(
        campo.idSocieta,
        dataPartita,
        orarioInizio,
        orarioFine,
      )) {
        return RisultatoCreazionePartita.fallimento(
          'Il centro sportivo è chiuso in questo orario.',
        );
      }

      final double importoTotale = _calcolaImportoPartita(
        campo: campo,
        sport: sportNormalizzato,
        orarioInizio: orarioInizio,
        orarioFine: orarioFine,
      );

      final result = await _repository.creaPartitaDinamica({
        'p_id_campo': campo.id,
        'p_id_organizzatore': organizzatore.id,
        'p_sport': sportNormalizzato,
        'p_data':
            "${dataPartita.year}-${dataPartita.month.toString().padLeft(2, '0')}-${dataPartita.day.toString().padLeft(2, '0')}",
        'p_inizio': orarioInizio,
        'p_fine': orarioFine,
        'p_giocatori_iniziali': giocatoriTotaliIniziali,
        'p_is_public': !isPartitaPrivata,
        'p_max_giocatori_custom': maxGiocatori,
        'p_is_pagato': isPagato,
        'p_stripe_payment_intent_id': stripePaymentIntentId,
        'p_importo_rimborsabile_centesimi': importoRimborsabileCentesimi,
        'p_importo_totale': importoTotale,
      });

      if (result['status'] == 'error') {
        return RisultatoCreazionePartita.fallimento(
          result['message']?.toString() ?? 'Errore creazione.',
        );
      }

      final String idPartitaGenerata = result['id'].toString();

      await _repository.inserisciGiocatorePartita({
        'id_partita': idPartitaGenerata,
        'id_utente': organizzatore.id,
        'ospiti_extra': ospitiExtra,
      });

      if (isPartitaGiaCompleta || isPartitaPrivata) {
        await _repository.annullaAltrePartiteNelloSlot(
          idCampo: campo.id,
          dataPartita: dataPartita,
          orarioInizio: orarioInizio,
          idPartitaVincente: idPartitaGenerata,
        );
      }

      return RisultatoCreazionePartita.successo(idPartitaGenerata);
    } catch (e) {
      return RisultatoCreazionePartita.fallimento(
        'Errore durante la creazione',
      );
    }
  }

  Future<RisultatoCreazionePartita> creaPrenotazioneManuale({
    required Campo campo,
    required String idGestore,
    required DateTime dataPartita,
    required String orarioInizio,
    String? nomeCliente,
    String? telefonoCliente,
    String? notaGestore,
  }) async {
    try {
      final parti = orarioInizio.split(':');

      final int ora = int.parse(parti[0]);
      final int minuto = int.parse(parti[1]);

      final inizioEsatto = DateTime(
        dataPartita.year,
        dataPartita.month,
        dataPartita.day,
        ora,
        minuto,
      );

      if (inizioEsatto.isBefore(DateTime.now())) {
        return RisultatoCreazionePartita.fallimento(
          'Non puoi inserire una prenotazione in un orario già passato.',
        );
      }

      // Prenotazioni : durata fissa di 60 minuti.
      final fineEsatto = inizioEsatto.add(const Duration(minutes: 60));

      final String inizioDb =
          '${ora.toString().padLeft(2, '0')}:'
          '${minuto.toString().padLeft(2, '0')}:00';

      final String orarioFine =
          '${fineEsatto.hour.toString().padLeft(2, '0')}:'
          '${fineEsatto.minute.toString().padLeft(2, '0')}:00';

      final centroAperto = await _isSocietaAperta(
        campo.idSocieta,
        dataPartita,
        inizioDb,
        orarioFine,
      );

      if (!centroAperto) {
        return RisultatoCreazionePartita.fallimento(
          'Il centro sportivo è chiuso in questo orario.',
        );
      }

      final disponibile = await _repository
          .isSlotDisponibilePerPrenotazioneManuale(
            idCampo: campo.id,
            dataPartita: dataPartita,
            orarioInizio: inizioDb,
          );

      if (!disponibile) {
        return RisultatoCreazionePartita.fallimento(
          'Questo orario è già occupato da una prenotazione completa.',
        );
      }

      final double importoTotale = _calcolaImportoPartita(
        campo: campo,
        sport: null,
        orarioInizio: orarioInizio,
        orarioFine: orarioFine,
      );

      final idPartita = await _repository.creaPrenotazioneManuale(
        idCampo: campo.id,
        idGestore: idGestore,
        dataPartita: dataPartita,
        orarioInizio: inizioDb,
        orarioFine: orarioFine,
        maxGiocatori: campo.numeroDiGiocatori,
        nomeCliente: nomeCliente,
        telefonoCliente: telefonoCliente,
        notaGestore: notaGestore,
        importoTotale: importoTotale,
      );

      // La prenotazione manuale completa prende lo slot.
      // Le eventuali partite aperte vengono annullate.
      await _repository.annullaAltrePartiteNelloSlot(
        idCampo: campo.id,
        dataPartita: dataPartita,
        orarioInizio: inizioDb,
        idPartitaVincente: idPartita,
      );

      return RisultatoCreazionePartita.successo(idPartita);
    } catch (e) {
      return RisultatoCreazionePartita.fallimento(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // 🔴 CORRETTO: Ora usa partita.maxGiocatoriReali
  Future<String?> uniscitiAPartita({
    required Partita partita,
    required Utente nuovoGiocatore,
    int ospitiExtra = 0,
  }) async {
    try {
      if (ospitiExtra < 0) {
        return 'Il numero di ospiti non può essere negativo.';
      }

      final bool giaIscritto = partita.listaGiocatoriIscritti.any(
        (g) => g.idUtente == nuovoGiocatore.id,
      );
      if (giaIscritto) {
        return 'Sei già iscritto a questa partita.';
      }

      final inizioEsatto = _calcolaInizioEsatto(
        partita.dataPartita,
        partita.orarioInizio,
      );
      final adesso = DateTime.now();

      if (adesso.isAfter(inizioEsatto)) {
        return 'Questa partita è già iniziata.';
      }

      if (adesso.isAfter(
        inizioEsatto.subtract(const Duration(hours: oreAnnullamentoAutomatico)),
      )) {
        return 'Iscrizioni chiuse: mancano meno di '
            '$oreAnnullamentoAutomatico ore all\'inizio.';
      }

      final int maxPosti =
          partita.maxGiocatoriReali; // 🟢 Usiamo maxGiocatoriReali
      final int nuovoTotale =
          partita.numeroGiocatoriPrenotati + 1 + ospitiExtra;

      if (nuovoTotale > maxPosti) {
        return 'Posti insufficienti per te e i tuoi ospiti.';
      }

      await _repository.inserisciGiocatorePartita({
        'id_partita': partita.id,
        'id_utente': nuovoGiocatore.id,
        'ospiti_extra': ospitiExtra,
      });

      if (nuovoTotale >= maxPosti) {
        await _repository.completaPartitaEAnnullaSlotRpc(
          idPartita: partita.id,
          nuovoTotale: nuovoTotale,
          idCampo: partita.campo.id,
          dataPartita: partita.dataPartita,
          orarioInizio: partita.orarioInizio,
        );
      } else {
        await _repository.aggiornaGiocatoriEStato(
          idPartita: partita.id,
          nuovoTotale: nuovoTotale,
          nuovoStato: 'aperta_a_rischio',
        );
      }

      return null;
    } catch (e) {
      return 'Impossibile completare l’iscrizione. Riprova tra poco.';
    }
  }

  Future<String?> abbandonaPartita({
    required Partita partita,
    required Utente giocatoreDaRimuovere,
  }) async {
    try {
      final inizioEsatto = _calcolaInizioEsatto(
        partita.dataPartita,
        partita.orarioInizio,
      );
      final adesso = DateTime.now();

      if (adesso.isAfter(inizioEsatto)) {
        return 'La partita è già iniziata: impossibile abbandonare.';
      }

      if (adesso.isAfter(
        inizioEsatto.subtract(const Duration(minutes: minutiLimiteAbbandono)),
      )) {
        return 'Abbandono bloccato: mancano meno di '
            '$minutiLimiteAbbandono minuti all\'inizio.';
      }

      await _repository.abbandonaPartitaRpc(
        idPartita: partita.id,
        idUtente: giocatoreDaRimuovere.id,
      );

      return null;
    } catch (e) {
      return 'Errore durante l\'abbandono.';
    }
  }

  Future<List<Partita>> getPartiteDellUtente(String idUtente) async {
    final dati = await _repository.getPartiteUtente(idUtente);
    return dati.map((json) => Partita.fromJson(json)).toList();
  }

  Future<bool> _isSocietaAperta(
    String idSocieta,
    DateTime data,
    String start,
    String end,
  ) async {
    final o = await _orarioRepository.getOrarioGiorno(idSocieta, data.weekday);
    if (o == null || o.isChiuso) return false;

    final int startMin = _orarioInMinuti(start);

    int endMin = _orarioInMinuti(end);

    if (endMin == 0 && startMin > 0) {
      endMin = 24 * 60;
    }

    bool inTurno1 = false;
    if (o.orarioApertura != null && o.orarioChiusura != null) {
      final int apertura1 = _orarioInMinuti(o.orarioApertura!);

      int chiusura1 = _orarioInMinuti(o.orarioChiusura!);

      if (chiusura1 == 0 && apertura1 > 0) {
        chiusura1 = 24 * 60;
      }

      inTurno1 = startMin >= apertura1 && endMin <= chiusura1;
    }

    bool inTurno2 = false;
    if (o.orarioApertura2 != null && o.orarioChiusura2 != null) {
      final int apertura2 = _orarioInMinuti(o.orarioApertura2!);

      int chiusura2 = _orarioInMinuti(o.orarioChiusura2!);

      if (chiusura2 == 0 && apertura2 > 0) {
        chiusura2 = 24 * 60;
      }

      inTurno2 = startMin >= apertura2 && endMin <= chiusura2;
    }

    return inTurno1 || inTurno2;
  }

  DateTime getScadenzaPartita(Partita partita) {
    return _calcolaInizioEsatto(
      partita.dataPartita,
      partita.orarioInizio,
    ).subtract(const Duration(hours: oreAnnullamentoAutomatico));
  }
}
