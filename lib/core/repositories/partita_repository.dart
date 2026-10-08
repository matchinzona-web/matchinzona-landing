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
      throw Exception('Errore database: ${e.message}');
    } catch (e) {
      throw Exception('Impossibile completare la creazione in questo momento.');
    }
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
    final dataStr = _formatData(data);
    final idUtenteCorrente = _supabase.auth.currentUser?.id;

    final response = await _supabase
        .from('partite')
        .select('id, orario_inizio, stato_partita, id_organizzatore')
        .eq('id_campo', idCampo)
        .eq('data_partita', dataStr)
        .neq('stato_partita', 'annullata');

    final List<Map<String, dynamic>> partite = List<Map<String, dynamic>>.from(
      response,
    );
    final Map<String, Map<String, dynamic>> mappaStati = {};

    for (var p in partite) {
      String ora = (p['orario_inizio'] as String).substring(0, 5);
      String stato = p['stato_partita'] as String;

      if (!mappaStati.containsKey(ora)) {
        mappaStati[ora] = {'occupato_fisso': false, 'aperte': 0};
        mappaStati[ora] = {
          'occupato_fisso': false,
          'aperte': 0,
          'mio_match_aperto_id': null,
        };
      }

      if (stato == 'completa') {
        mappaStati[ora]!['occupato_fisso'] = true;
      } else if (stato == 'aperta_a_rischio') {
        mappaStati[ora]!['aperte'] = (mappaStati[ora]!['aperte'] as int) + 1;

        final idOrganizzatore = p['id_organizzatore']?.toString();

        if (idUtenteCorrente != null && idOrganizzatore == idUtenteCorrente) {
          mappaStati[ora]!['mio_match_aperto_id'] = p['id']?.toString();
        }
      }
    }

    return mappaStati;
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
}
