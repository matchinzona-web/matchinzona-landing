import '../models/partita.dart';
import '../models/campo.dart';
import '../models/utente.dart';
import '../repositories/partita_repository.dart';
import '../repositories/orario_societa_repository.dart';
import '../repositories/chiusura_straordinaria_repository.dart';

enum MetodoPagamento { nessuno, pagaOra, inSede }

class PartitaService {
  final PartitaRepository _repository;
  final OrarioSocietaRepository _orarioRepository;
  final ChiusuraStraordinariaRepository _chiusuraRepository;

  static const int oreLimiteScadenza = 4;
  static const int orePerditaProtezioneFissa = 24;
  static const int oreDurataMassimaProtezione = 48;
  static const int maxPartiteNelloSlot = 3;
  static const int maxGiocatoriSportPiccoli = 4;
  static const int minAperturaSportPiccoli = 2;
  static const int minProtezioneSportPiccoli = 3;
  static const double percentualeProtezioneSportGrandi = 0.8;
  static const double percentualeAperturaPrimeTime = 0.6;
  static const double percentualeAperturaStandardTime = 0.4;
  static const int primeTimeInizio = 18;
  static const int primeTimeFine = 22;

  static const int oreMinPreavvisoCreazione = 1;

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

  int getSogliaProtezione(int maxGiocatori) =>
      maxGiocatori <= maxGiocatoriSportPiccoli
      ? minProtezioneSportPiccoli
      : (maxGiocatori * percentualeProtezioneSportGrandi).floor();

  int getMinimoApertura(int maxGiocatori, bool isPrimeTime) =>
      maxGiocatori <= maxGiocatoriSportPiccoli
      ? minAperturaSportPiccoli
      : (maxGiocatori *
                (isPrimeTime
                    ? percentualeAperturaPrimeTime
                    : percentualeAperturaStandardTime))
            .ceil();

  bool _isPrimeTime(String orarioInizio) {
    final ora = int.tryParse(orarioInizio.split(':')[0]) ?? 0;
    return ora >= primeTimeInizio && ora < primeTimeFine;
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
    return (int.parse(parti[0]) * 60) + int.parse(parti[1]);
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

    final int maxPosti =
        partita.maxGiocatoriReali; // 🟢 Usiamo maxGiocatoriReali
    final isPt = _isPrimeTime(partita.orarioInizio);
    final minimoApertura = getMinimoApertura(maxPosti, isPt);

    if (partita.numeroGiocatoriPrenotati < minimoApertura) {
      return 'annullata';
    }

    if (partita.numeroGiocatoriPrenotati >= maxPosti) {
      return 'completa';
    }

    if (DateTime.now().isAfter(
      inizioEsatto.subtract(const Duration(hours: orePerditaProtezioneFissa)),
    )) {
      return 'aperta_a_rischio';
    }

    return partita.statoPartita;
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

  Future<String?> creaNuovaPartita({
    required Campo campo,
    required Utente organizzatore,
    required DateTime dataPartita,
    required String orarioInizio,
    required String orarioFine,
    int ospitiExtra = 0,
    bool isPartitaPrivata = false,
    bool isPagato = false,
  }) async {
    try {
      if (ospitiExtra < 0) {
        return 'Il numero di ospiti non può essere negativo.';
      }

      // Durante la creazione in creaNuovaPartita:
      int maxGiocatori = campo.numeroDiGiocatori;

      // Se è Tennis ed è selezionato il doppio o ci sono 3 ospiti extra (totale 4 persone)
      if (campo.nomeCampo.toLowerCase().contains('tennis')) {
        if (ospitiExtra >= 3 || (isPartitaPrivata && ospitiExtra > 1)) {
          maxGiocatori = 4;
        } else if (ospitiExtra <= 1) {
          maxGiocatori = 2; // Singolo fisso
        }
      }

      final int giocatoriTotaliIniziali = 1 + ospitiExtra;
      final bool isPartitaGiaCompleta = giocatoriTotaliIniziali >= maxGiocatori;

      final inizioEsatto = _calcolaInizioEsatto(dataPartita, orarioInizio);
      final adesso = DateTime.now();

      if (adesso.isAfter(inizioEsatto)) {
        return 'Non puoi creare una partita in un orario già passato.';
      }

      if (adesso.isAfter(
        inizioEsatto.subtract(const Duration(hours: oreMinPreavvisoCreazione)),
      )) {
        return 'Non puoi creare una partita con meno di $oreMinPreavvisoCreazione ora di anticipo.';
      }

      final isPt = _isPrimeTime(orarioInizio);

      if (giocatoriTotaliIniziali > maxGiocatori) {
        return 'Errore: troppi giocatori per questo campo.';
      }

      if (giocatoriTotaliIniziali < getMinimoApertura(maxGiocatori, isPt)) {
        return 'Servono più giocatori per aprire una partita in questo orario.';
      }

      if (giocatoriTotaliIniziali < getSogliaProtezione(maxGiocatori) &&
          adesso.isAfter(
            inizioEsatto.subtract(const Duration(hours: oreLimiteScadenza)),
          )) {
        return 'Mancano meno di $oreLimiteScadenza ore all\'inizio: impossibile aprire una partita a rischio.';
      }

      if (await _repository.isSlotOccupato(
        campo.id,
        dataPartita,
        orarioInizio,
      )) {
        return 'Lo slot è già occupato da una partita completa o protetta.';
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
        return 'Hai già una partita aperta in questo orario.';
      }

      if (partiteEsistenti.any(
        (p) => p['stato_partita'] == 'aperta_protetta',
      )) {
        return 'È già presente una partita protetta in questo orario.';
      }

      if (!isPartitaGiaCompleta && !isPartitaPrivata) {
        if (partiteEsistenti.isNotEmpty) {
          final partiteCompatibili = partiteEsistenti.where((p) {
            final int giocatoriAttuali =
                p['numero_giocatori_prenotati'] as int? ?? 0;
            final int postiLiberi = maxGiocatori - giocatoriAttuali;
            return giocatoriTotaliIniziali <= postiLiberi;
          }).toList();

          if (partiteCompatibili.isNotEmpty) {
            partiteCompatibili.sort((a, b) {
              final int gA = a['numero_giocatori_prenotati'] as int? ?? 0;
              final int gB = b['numero_giocatori_prenotati'] as int? ?? 0;
              return gB.compareTo(gA);
            });

            final partitaMigliore = partiteCompatibili.first;
            final int maxGiocatoriTrovati =
                partitaMigliore['numero_giocatori_prenotati'] as int? ?? 0;

            return 'Esiste già una partita con $maxGiocatoriTrovati giocatori in cui c\'è posto per voi. Unisciti a quella per ottimizzare le presenze. UNISCITI_FORZATO';
          }
        }

        if (partiteEsistenti.length >= maxPartiteNelloSlot) {
          return 'Raggiunto il limite massimo di $maxPartiteNelloSlot partite aperte in questo orario. Puoi solo prenotare il Campo Intero o unirti a una esistente. MAX_PARTITE_RAGGIUNTE';
        }
      }

      if (isPartitaPrivata &&
          !isPartitaGiaCompleta &&
          partiteEsistenti.any(
            (p) => p['stato_partita'] == 'aperta_protetta',
          )) {
        return 'Non puoi creare una partita privata in uno slot con una partita protetta.';
      }

      if (!await _isSocietaAperta(
        campo.idSocieta,
        dataPartita,
        orarioInizio,
        orarioFine,
      )) {
        return 'Il centro sportivo è chiuso in questo orario.';
      }

      final int sogliaProtezione = getSogliaProtezione(maxGiocatori);
      final bool isMenoDi24h = adesso.isAfter(
        inizioEsatto.subtract(const Duration(hours: orePerditaProtezioneFissa)),
      );
      final bool laNuovaPartitaSeraProtetta =
          giocatoriTotaliIniziali >= sogliaProtezione && !isMenoDi24h;

      final result = await _repository.creaPartitaDinamica({
        'p_id_campo': campo.id,
        'p_id_organizzatore': organizzatore.id,
        'p_data':
            "${dataPartita.year}-${dataPartita.month.toString().padLeft(2, '0')}-${dataPartita.day.toString().padLeft(2, '0')}",
        'p_inizio': orarioInizio,
        'p_fine': orarioFine,
        'p_giocatori_iniziali': giocatoriTotaliIniziali,
        'p_is_public': !isPartitaPrivata,
        'p_max_giocatori_custom': maxGiocatori,
        'p_is_pagato': isPagato,
      });

      if (result['status'] == 'error') return result['message'];

      await _repository.inserisciGiocatorePartita({
        'id_partita': result['id'],
        'id_utente': organizzatore.id,
        'ospiti_extra': ospitiExtra,
      });

      if (isPartitaGiaCompleta || isPartitaPrivata) {
        await _repository.annullaAltrePartiteNelloSlot(
          idCampo: campo.id,
          dataPartita: dataPartita,
          orarioInizio: orarioInizio,
          idPartitaVincente: result['id'],
        );
      } else if (laNuovaPartitaSeraProtetta) {
        await _repository.annullaPartiteARischioNelloSlot(
          idCampo: campo.id,
          dataPartita: dataPartita,
          orarioInizio: orarioInizio,
          idPartitaVincente: result['id'],
        );
      }

      return null;
    } catch (e) {
      return 'Errore durante la creazione: $e';
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

      if (adesso.isAfter(inizioEsatto.subtract(const Duration(hours: 1)))) {
        return 'Iscrizioni chiuse: manca meno di 1 ora all\'inizio.';
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

      final bool isMenoDi24h = adesso.isAfter(
        inizioEsatto.subtract(const Duration(hours: orePerditaProtezioneFissa)),
      );

      if (nuovoTotale >= maxPosti) {
        await _repository.completaPartitaEAnnullaSlotRpc(
          idPartita: partita.id,
          nuovoTotale: nuovoTotale,
          idCampo: partita.campo.id,
          dataPartita: partita.dataPartita,
          orarioInizio: partita.orarioInizio,
        );
      } else {
        final String nuovoStato =
            (nuovoTotale >= getSogliaProtezione(maxPosti) && !isMenoDi24h)
            ? 'aperta_protetta'
            : 'aperta_a_rischio';

        await _repository.aggiornaGiocatoriEStato(
          idPartita: partita.id,
          nuovoTotale: nuovoTotale,
          nuovoStato: nuovoStato,
        );
      }

      return null;
    } catch (e) {
      return 'Errore iscrizione: $e';
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
        inizioEsatto.subtract(const Duration(hours: oreLimiteScadenza)),
      )) {
        return 'Abbandono bloccato: mancano meno di $oreLimiteScadenza ore all\'inizio.';
      }

      final int maxGiocatoriReali = partita.maxGiocatoriReali;

      final int ospitiExtra = await _repository.getOspitiExtraGiocatore(
        partita.id,
        giocatoreDaRimuovere.id,
      );

      await _repository.rimuoviGiocatorePartita(
        partita.id,
        giocatoreDaRimuovere.id,
      );

      final int nuovoTotale =
          (partita.numeroGiocatoriPrenotati - (1 + ospitiExtra)).clamp(0, 99);

      final isPt = _isPrimeTime(partita.orarioInizio);
      final minimoApertura = getMinimoApertura(maxGiocatoriReali, isPt);

      if (nuovoTotale <= 0 || nuovoTotale < minimoApertura) {
        await _repository.aggiornaGiocatoriEStato(
          idPartita: partita.id,
          nuovoTotale: nuovoTotale,
          nuovoStato: 'annullata',
        );
      } else {
        final bool isMenoDi24h = adesso.isAfter(
          inizioEsatto.subtract(
            const Duration(hours: orePerditaProtezioneFissa),
          ),
        );

        final String stato =
            (nuovoTotale >= getSogliaProtezione(maxGiocatoriReali) &&
                !isMenoDi24h)
            ? 'aperta_protetta'
            : 'aperta_a_rischio';

        await _repository.aggiornaGiocatoriEStato(
          idPartita: partita.id,
          nuovoTotale: nuovoTotale,
          nuovoStato: stato,
        );
      }

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
    final int endMin = _orarioInMinuti(end);

    bool inTurno1 = false;
    if (o.orarioApertura != null && o.orarioChiusura != null) {
      inTurno1 =
          startMin >= _orarioInMinuti(o.orarioApertura!) &&
          endMin <= _orarioInMinuti(o.orarioChiusura!);
    }

    bool inTurno2 = false;
    if (o.orarioApertura2 != null && o.orarioChiusura2 != null) {
      inTurno2 =
          startMin >= _orarioInMinuti(o.orarioApertura2!) &&
          endMin <= _orarioInMinuti(o.orarioChiusura2!);
    }

    return inTurno1 || inTurno2;
  }

  DateTime getScadenzaPartita(Partita partita) {
    return _calcolaInizioEsatto(
      partita.dataPartita,
      partita.orarioInizio,
    ).subtract(const Duration(hours: oreLimiteScadenza));
  }

  String tempoRimanenteScadenza(Partita partita) {
    try {
      final scadenza = getScadenzaPartita(partita);
      final differenza = scadenza.difference(DateTime.now());
      if (differenza.isNegative) return "00h : 00m";
      return "${differenza.inHours.toString().padLeft(2, '0')}h : ${differenza.inMinutes.remainder(60).toString().padLeft(2, '0')}m";
    } catch (_) {
      return "00h : 00m";
    }
  }

  String tempoRimanenteProtezione(Partita partita) {
    try {
      final inizioEsatto = _calcolaInizioEsatto(
        partita.dataPartita,
        partita.orarioInizio,
      );

      final scadenzaProtezione = inizioEsatto.subtract(
        const Duration(hours: orePerditaProtezioneFissa),
      );

      final differenza = scadenzaProtezione.difference(DateTime.now());

      if (differenza.isNegative) return "Scaduta";

      final int giorni = differenza.inDays;
      final int ore = differenza.inHours % 24;
      final int minuti = differenza.inMinutes % 60;

      if (giorni > 0) {
        return "$giorni g ${ore}h";
      } else {
        return "${ore}h ${minuti.toString().padLeft(2, '0')}m";
      }
    } catch (_) {
      return "N/D";
    }
  }
}
