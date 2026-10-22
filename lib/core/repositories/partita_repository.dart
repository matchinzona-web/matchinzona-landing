import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PartitaRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> streamPartiteUtente(String idUtente) {
    return _supabase
        .from('partite')
        .stream(primaryKey: ['id'])
        .order('data_partita', ascending: true)
        .order('orario_inizio', ascending: true)
        .map(
          (partite) =>
              partite.where((p) => p['id_organizzatore'] == idUtente).toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getMatchPubbliciApertiGeolocalizzati({
    required double latUtente,
    required double lonUtente,
    double raggioKm = 30.0,
  }) async {
    try {
      final responseRpc = await _supabase.rpc(
        'get_match_vicini',
        params: {
          'lat_utente': latUtente,
          'lon_utente': lonUtente,
          'raggio_km': raggioKm,
        },
      );

      debugPrint('🟡 MATCH VICINI RPC: ${(responseRpc as List).length}');
      debugPrint(
        '🟡 USER ATTUALE: ${_supabase.auth.currentUser?.id ?? "OSPITE"}',
      );

      final List<dynamic> risultatiRaggio = responseRpc;
      if (risultatiRaggio.isEmpty) return [];

      final List<String> idPartite = risultatiRaggio
          .map((e) => e['id_partita'].toString())
          .toList();

      final Map<String, double> mappaDistanze = {
        for (var e in risultatiRaggio)
          e['id_partita'].toString(): (e['distanza_km'] as num).toDouble(),
      };

      final responseCompleta = await _supabase
          .from('partite')
          .select('''
            *,
            campo:campi(*, societa(*)),
            organizzatore:utenti!partite_id_organizzatore_fkey(*),
            giocatori_partita(
              ospiti_extra,
              utenti(*)
            )
          ''')
          .inFilter('id', idPartite);

      debugPrint(
        '🟠 MATCH COMPLETI SELECT: ${(responseCompleta as List).length}',
      );

      final datiFinali = List<Map<String, dynamic>>.from(responseCompleta);

      for (var partita in datiFinali) {
        final id = partita['id'].toString();
        partita['distanza_km'] = mappaDistanze[id] ?? 0.0;
      }

      datiFinali.sort(
        (a, b) =>
            (a['distanza_km'] as double).compareTo(b['distanza_km'] as double),
      );

      return datiFinali;
    } catch (e, stackTrace) {
      debugPrint('🔴 getMatchPubbliciApertiGeolocalizzati ERRORE: $e');
      debugPrint('$stackTrace');

      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPartiteDatiGrezzi() async {
    try {
      final response = await _supabase
          .from('partite')
          .select('''
            *,
            campo:campi(*, societa(*)),
            organizzatore:utenti!partite_id_organizzatore_fkey(*),
            giocatori_partita(
              ospiti_extra,
              utenti(*)
            )
          ''')
          .order('data_partita', ascending: true)
          .order('orario_inizio', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Impossibile recuperare le partite dal database.');
    }
  }

  Future<int> getOspitiExtraGiocatore(String idPartita, String idUtente) async {
    try {
      final response = await _supabase
          .from('giocatori_partita')
          .select('ospiti_extra')
          .match({'id_partita': idPartita, 'id_utente': idUtente})
          .maybeSingle();

      if (response == null) return 0;
      return response['ospiti_extra'] as int? ?? 0;
    } catch (e) {
      throw Exception('Impossibile recuperare i dati di iscrizione.');
    }
  }

  Future<List<Map<String, dynamic>>> getPartiteAperteNelloSlot({
    required String idCampo,
    required DateTime dataPartita,
    required String orarioInizio,
  }) async {
    try {
      final dataStr = _formatData(dataPartita);

      final response = await _supabase
          .from('partite')
          .select('*')
          .match({
            'id_campo': idCampo,
            'data_partita': dataStr,
            'orario_inizio': orarioInizio,
          })
          .eq('is_public', true)
          .eq('stato_partita', 'aperta_a_rischio');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(
        'Impossibile verificare le partite esistenti nello slot.',
      );
    }
  }

  Future<bool> isSlotOccupato(
    String idCampo,
    DateTime data,
    String orario,
  ) async {
    final dataStr = _formatData(data);

    final response = await _supabase
        .from('partite')
        .select('id')
        .match({
          'id_campo': idCampo,
          'data_partita': dataStr,
          'orario_inizio': orario,
        })
        .eq('stato_partita', 'completa')
        .maybeSingle();

    return response != null;
  }

  /// Recupera tutti gli intervalli occupati di un campo
  /// in una data giornata con una sola chiamata SQL.
  Future<List<Map<String, dynamic>>> getIntervalliOccupatiGiorno({
    required String idCampo,
    required DateTime data,
  }) async {
    final dataStr = _formatData(data);

    final response = await _supabase.rpc(
      'get_intervalli_occupati_campo',
      params: {'p_id_campo': idCampo, 'p_data': dataStr},
    );

    if (response is! List) {
      throw StateError(
        'Risposta non valida durante il caricamento degli intervalli.',
      );
    }

    return List<Map<String, dynamic>>.from(response);
  }

  /// Controlla se esiste una partita completa che si sovrappone
  /// all'intero intervallo richiesto.
  ///
  /// Compatibile con prenotazioni da 60 e 90 minuti.
  Future<bool> isIntervalloOccupato({
    required String idCampo,
    required DateTime data,
    required String orarioInizio,
    required String orarioFine,
  }) async {
    final dataStr = _formatData(data);

    try {
      final response = await _supabase.rpc(
        'slot_occupato_reale',
        params: {
          'p_id_campo': idCampo,
          'p_data': dataStr,
          'p_inizio': orarioInizio,
          'p_fine': orarioFine,
        },
      );

      if (response is bool) {
        return response;
      }

      throw Exception('Risposta non valida dal database.');
    } on PostgrestException catch (e) {
      throw Exception('Impossibile verificare la disponibilità: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> creaPartitaDinamica(
    Map<String, dynamic> parametri,
  ) async {
    try {
      final response = await _supabase.rpc(
        'gestione_prenotazione_dinamica',
        params: parametri,
      );

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'id': response.toString(), 'status': 'success'};
    } on PostgrestException catch (e) {
      final bool slotOccupato =
          e.code == '23P01' ||
          e.message.contains('nessuna_sovrapposizione_partite_complete');

      if (slotOccupato) {
        throw Exception('SLOT_GIA_OCCUPATO');
      }

      throw Exception('Errore database: ${e.message}');
    } catch (e) {
      throw Exception('Impossibile completare la creazione in questo momento.');
    }
  }

  Future<Map<String, dynamic>> iscrivitiPartitaAtomica({
    required String idPartita,
    int ospitiExtra = 0,
  }) async {
    if (ospitiExtra < 0) {
      throw ArgumentError('Il numero di ospiti non può essere negativo.');
    }

    final response = await _supabase.rpc(
      'iscriviti_partita_atomica',
      params: {'p_id_partita': idPartita, 'p_ospiti_extra': ospitiExtra},
    );

    if (response is! Map) {
      throw StateError('Risposta non valida durante l’iscrizione.');
    }

    final risultato = Map<String, dynamic>.from(response);

    if (risultato['successo'] != true) {
      throw StateError('Iscrizione non completata.');
    }

    return risultato;
  }

  Future<void> inserisciGiocatorePartita(
    Map<String, dynamic> datiIscrizione,
  ) async {
    try {
      await _supabase.from('giocatori_partita').insert(datiIscrizione);
    } catch (e) {
      throw Exception('Impossibile iscrivere il giocatore.');
    }
  }

  Future<void> aggiornaNumeroGiocatoriPrenotati(
    String idPartita,
    int nuovoTotale,
  ) async {
    try {
      await _supabase
          .from('partite')
          .update({'numero_giocatori_prenotati': nuovoTotale})
          .eq('id', idPartita);
    } catch (e) {
      throw Exception('Impossibile aggiornare i posti occupati.');
    }
  }

  Future<void> aggiornaImportoTotalePartita(
    String idPartita,
    double importoTotale,
  ) async {
    try {
      await _supabase
          .from('partite')
          .update({'importo_totale': importoTotale})
          .eq('id', idPartita);
    } catch (e) {
      throw Exception('Impossibile salvare l\'importo della partita.');
    }
  }

  Future<void> aggiornaStatoPartita(String idPartita, String nuovoStato) async {
    try {
      await _supabase
          .from('partite')
          .update({'stato_partita': nuovoStato})
          .eq('id', idPartita);
    } catch (e) {
      throw Exception('Impossibile aggiornare lo stato della partita.');
    }
  }

  Future<void> aggiornaGiocatoriEStato({
    required String idPartita,
    required int nuovoTotale,
    required String nuovoStato,
  }) async {
    try {
      await _supabase.rpc(
        'aggiorna_giocatori_e_stato',
        params: {
          'p_id_partita': idPartita,
          'p_nuovo_totale': nuovoTotale,
          'p_nuovo_stato': nuovoStato,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception('Errore database aggiornamento atomico: ${e.message}');
    } catch (e) {
      throw Exception('Errore aggiornamento');
    }
  }

  Future<void> completaPartitaEAnnullaSlotRpc({
    required String idPartita,
    required int nuovoTotale,
    required String idCampo,
    required DateTime dataPartita,
    required String orarioInizio,
  }) async {
    try {
      final dataStr = _formatData(dataPartita);
      final orarioFormattato = orarioInizio.length == 5
          ? "$orarioInizio:00"
          : orarioInizio;

      await _supabase.rpc(
        'completa_partita_e_annulla_slot',
        params: {
          'p_id_partita': idPartita,
          'p_nuovo_totale': nuovoTotale,
          'p_id_campo': idCampo,
          'p_data_partita': dataStr,
          'p_orario_inizio': orarioFormattato,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Errore nel completamento atomico dello slot: ${e.message}',
      );
    } catch (e) {
      throw Exception('Errore imprevisto nel completamento slot');
    }
  }

  Future<void> annullaAltrePartiteNelloSlot({
    required String idCampo,
    required DateTime dataPartita,
    required String orarioInizio,
    required String idPartitaVincente,
  }) async {
    try {
      final dataStr = _formatData(dataPartita);

      await _supabase
          .from('partite')
          .update({'stato_partita': 'annullata'})
          .match({
            'id_campo': idCampo,
            'data_partita': dataStr,
            'orario_inizio': orarioInizio,
          })
          .neq('id', idPartitaVincente)
          .eq('stato_partita', 'aperta_a_rischio');
    } catch (e) {
      throw Exception('Impossibile annullare le altre partite concorrenti.');
    }
  }

  Future<void> rimuoviGiocatorePartita(
    String idPartita,
    String idUtente,
  ) async {
    try {
      await _supabase.from('giocatori_partita').delete().match({
        'id_partita': idPartita,
        'id_utente': idUtente,
      });
    } catch (e) {
      throw Exception('Impossibile disiscrivere il giocatore.');
    }
  }

  // 🟢 CORRETTO: Includiamo tutti i campi necessari (* in campi e tariffe_sport)
  Future<List<Map<String, dynamic>>> fetchPrenotazioniGestore(
    String idSocieta,
  ) async {
    try {
      final campiData = await _supabase
          .from('campi')
          .select('id')
          .eq('id_societa', idSocieta);

      if (campiData.isEmpty) return [];

      final List<String> idCampi = campiData
          .map((c) => c['id'] as String)
          .toList();

      final partiteData = await _supabase
          .from('partite')
          .select('''
      *,
      campo:campi(*),
      organizzatore:utenti!partite_id_organizzatore_fkey(
        nome, cognome, email, telefono
      ),
      giocatori_partita(
        id_utente,
        ospiti_extra,
        utenti(
          nome,
          cognome
        )
      )
    ''')
          .inFilter('id_campo', idCampi);

      return List<Map<String, dynamic>>.from(partiteData);
    } on PostgrestException catch (e) {
      throw Exception('Errore SQL nel recupero prenotazioni: ${e.message}');
    }
  }

  Future<Map<String, Map<String, dynamic>>> getStatoOrariGiorno(
    String idCampo,
    DateTime data,
  ) async {
    try {
      final dataStr = _formatData(data);

      final response = await _supabase.rpc(
        'get_stato_slot_campo',
        params: {'p_id_campo': idCampo, 'p_data': dataStr},
      );

      final List<Map<String, dynamic>> righe = List<Map<String, dynamic>>.from(
        response as List,
      );

      final Map<String, Map<String, dynamic>> mappaStati = {};

      for (final riga in righe) {
        final String orarioCompleto = riga['orario_inizio'].toString();

        final String ora = orarioCompleto.length >= 5
            ? orarioCompleto.substring(0, 5)
            : orarioCompleto;

        mappaStati[ora] = {
          'occupato_fisso': riga['occupato_fisso'] == true,
          'aperte': (riga['aperte'] as num?)?.toInt() ?? 0,
          'mio_match_aperto_id': riga['mio_match_aperto_id']?.toString(),
        };
      }

      return mappaStati;
    } on PostgrestException catch (e) {
      debugPrint('Errore getStatoOrariGiorno RPC: ${e.message}');
      throw Exception('Impossibile verificare la disponibilità degli orari.');
    } catch (e) {
      debugPrint('Errore getStatoOrariGiorno: $e');
      throw Exception('Impossibile verificare la disponibilità degli orari.');
    }
  }

  Future<List<Map<String, dynamic>>> getPartiteUtente(String idUtente) async {
    try {
      final partecipazioni = await _supabase
          .from('giocatori_partita')
          .select('id_partita')
          .eq('id_utente', idUtente);

      final idsPartite = partecipazioni
          .map((e) => e['id_partita'].toString())
          .toList();

      if (idsPartite.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('partite')
          .select('''
          *,
          campo:campi(*, societa(*)),
          organizzatore:utenti!partite_id_organizzatore_fkey(*),
          giocatori_partita(
            id_utente,
            ospiti_extra,
            utenti(*)
          )
        ''')
          .inFilter('id', idsPartite)
          .neq('stato_partita', 'annullata')
          .order('data_partita', ascending: true)
          .order('orario_inizio', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Errore getPartiteUtente: $e');
      throw Exception('Impossibile recuperare le tue partite.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPartiteCompletatePerGuadagni(
    String idSocieta,
  ) async {
    try {
      final campiData = await _supabase
          .from('campi')
          .select('id')
          .eq('id_societa', idSocieta);

      if (campiData.isEmpty) return [];

      final List<String> idCampi = campiData
          .map((c) => c['id'] as String)
          .toList();

      final response = await _supabase
          .from('partite')
          .select('*, campo:campi(*)')
          .inFilter('id_campo', idCampi)
          .eq('stato_partita', 'completa')
          .eq('is_rimborsata', false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Errore nel calcolo dei guadagni');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRiepiloghiMensiliGuadagni(
    String idSocieta,
  ) async {
    try {
      final response = await _supabase
          .from('riepiloghi_mensili_campi')
          .select('*')
          .eq('id_societa', idSocieta)
          .order('anno', ascending: false)
          .order('mese', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Errore nel recupero dello storico guadagni');
    }
  }

  Future<String> creaPrenotazioneManuale({
    required String idCampo,
    required String idGestore,
    required DateTime dataPartita,
    required String orarioInizio,
    required String orarioFine,
    String? sport,
    required int maxGiocatori,
    String? nomeCliente,
    String? telefonoCliente,
    String? notaGestore,
    required double importoTotale,
  }) async {
    try {
      final dataStr = _formatData(dataPartita);

      final response = await _supabase
          .from('partite')
          .insert({
            'id_campo': idCampo,
            'id_organizzatore': idGestore,
            'data_partita': dataStr,
            'orario_inizio': orarioInizio,
            'orario_fine': orarioFine,
            'sport': sport,

            // Prenotazione manuale = campo intero occupato.
            'numero_giocatori_prenotati': maxGiocatori,
            'max_giocatori': maxGiocatori,
            'stato_partita': 'completa',
            'is_public': false,

            'origine_prenotazione': 'gestore',
            'nome_cliente_manual': nomeCliente?.trim().isEmpty == true
                ? null
                : nomeCliente?.trim(),
            'telefono_cliente_manual': telefonoCliente?.trim().isEmpty == true
                ? null
                : telefonoCliente?.trim(),
            'nota_gestore': notaGestore?.trim().isEmpty == true
                ? null
                : notaGestore?.trim(),
            'importo_totale': importoTotale,
          })
          .select('id')
          .single();

      return response['id'].toString();
    } on PostgrestException catch (e) {
      throw Exception(
        'Errore database durante la prenotazione manuale: ${e.message}',
      );
    } catch (e) {
      throw Exception('Impossibile creare la prenotazione manuale');
    }
  }

  Future<bool> isSlotDisponibilePerPrenotazioneManuale({
    required String idCampo,
    required DateTime dataPartita,
    required String orarioInizio,
  }) async {
    try {
      final dataStr = _formatData(dataPartita);

      final response = await _supabase
          .from('partite')
          .select('id')
          .match({
            'id_campo': idCampo,
            'data_partita': dataStr,
            'orario_inizio': orarioInizio,
          })
          .eq('stato_partita', 'completa')
          .limit(1);

      return response.isEmpty;
    } catch (e) {
      throw Exception('Impossibile verificare la disponibilità dello slot.');
    }
  }

  String _formatData(DateTime data) {
    return "${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}";
  }

  Future<Set<String>> getSlotCompletiGiorno({
    required String idCampo,
    required DateTime dataPartita,
  }) async {
    try {
      final dataStr = _formatData(dataPartita);

      final response = await _supabase
          .from('partite')
          .select('orario_inizio')
          .eq('id_campo', idCampo)
          .eq('data_partita', dataStr)
          .eq('stato_partita', 'completa')
          .eq('is_rimborsata', false);

      final partite = List<Map<String, dynamic>>.from(response);

      return partite.map((p) {
        final orario = p['orario_inizio'].toString();

        return orario.length >= 5 ? orario.substring(0, 5) : orario;
      }).toSet();
    } catch (e) {
      throw Exception('Impossibile verificare gli slot già prenotati.');
    }
  }

  Future<void> abbandonaPartitaRpc({
    required String idPartita,
    required String idUtente,
  }) async {
    try {
      await _supabase.rpc(
        'abbandona_partita',
        params: {'p_id_partita': idPartita, 'p_id_utente': idUtente},
      );
    } on PostgrestException catch (e) {
      throw Exception('Errore database: ${e.message}');
    } catch (e) {
      throw Exception('Impossibile abbandonare la partita.');
    }
  }
}
