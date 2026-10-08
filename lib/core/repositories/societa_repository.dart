import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/models/societa.dart';
import 'package:flutter/material.dart';

class SocietaRepository {
  final SupabaseClient _supabase;

  SocietaRepository({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  bool _iniziaUnaParola(String testo, String query) {
    final queryPulita = query.trim().toLowerCase();

    if (queryPulita.isEmpty) return true;

    final parole = testo
        .toLowerCase()
        .split(RegExp(r'[^a-zA-ZÀ-ÿ0-9]+'))
        .where((parola) => parola.isNotEmpty);

    return parole.any((parola) => parola.startsWith(queryPulita));
  }

  Future<List<Societa>> cercaSocietaPerNome(String query) async {
    try {
      final response = await _supabase
          .from('societa')
          .select()
          .ilike('nome_societa', '%$query%');

      final risultati = (response as List)
          .where((json) {
            return _iniziaUnaParola(
              json['nome_societa']?.toString() ?? '',
              query,
            );
          })
          .map((json) => Societa.fromJson(json))
          .toList();

      return risultati;
    } catch (e) {
      debugPrint("Errore in cercaSocietaPerNome: $e");
      return [];
    }
  }

  Future<List<Societa>> cercaSocietaPerCitta(String query) async {
    try {
      final response = await _supabase
          .from('societa')
          .select()
          .or(
            'comune.ilike.%$query%,'
            'provincia.ilike.%$query%,'
            'indirizzo.ilike.%$query%',
          );

      final risultati = (response as List)
          .where((json) {
            return _iniziaUnaParola(json['comune']?.toString() ?? '', query) ||
                _iniziaUnaParola(json['provincia']?.toString() ?? '', query) ||
                _iniziaUnaParola(json['indirizzo']?.toString() ?? '', query);
          })
          .map((json) => Societa.fromJson(json))
          .toList();

      return risultati;
    } catch (e) {
      debugPrint("Errore in cercaSocietaPerCitta: $e");
      return [];
    }
  }

  Future<List<Societa>> cercaSocietaGlobale(String query) async {
    try {
      final response = await _supabase
          .from('societa')
          .select()
          .or(
            'nome_societa.ilike.%$query%,'
            'via.ilike.%$query%,'
            'comune.ilike.%$query%,'
            'provincia.ilike.%$query%,'
            'indirizzo.ilike.%$query%',
          );

      final risultati = (response as List)
          .where((json) {
            return _iniziaUnaParola(
                  json['nome_societa']?.toString() ?? '',
                  query,
                ) ||
                _iniziaUnaParola(json['via']?.toString() ?? '', query) ||
                _iniziaUnaParola(json['comune']?.toString() ?? '', query) ||
                _iniziaUnaParola(json['provincia']?.toString() ?? '', query) ||
                _iniziaUnaParola(json['indirizzo']?.toString() ?? '', query);
          })
          .map((json) => Societa.fromJson(json))
          .toList();

      return risultati;
    } catch (e) {
      debugPrint("Errore in cercaSocietaGlobale: $e");
      return [];
    }
  }

  Future<Societa?> getSocietaById(String idSocieta) async {
    try {
      final response = await _supabase
          .from('societa')
          .select()
          .eq('id', idSocieta)
          .maybeSingle();
      if (response == null) return null;
      return Societa.fromJson(response);
    } catch (e) {
      debugPrint("Errore in getSocietaById: $e");
      return null;
    }
  }

  Future<List<String>> getProvinceDisponibili() async {
    try {
      final response = await _supabase
          .from('societa')
          .select('provincia')
          .not('provincia', 'is', null);

      final province = (response as List)
          .map((row) => row['provincia']?.toString().trim() ?? '')
          .where((provincia) => provincia.isNotEmpty)
          .toSet()
          .toList();

      province.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return province;
    } catch (e) {
      debugPrint('Errore caricamento province: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> cercaSocietaEPrezziPerSport({
    required String sport,
    required int giornoSettimana,
    String? provincia,
  }) async {
    try {
      debugPrint("Cerco società per sport: $sport e giorno: $giornoSettimana");

      // 1. Trova i CAMPI che supportano lo sport richiesto,
      // insieme alla società e agli orari.
      final query = _supabase
          .from('campi')
          .select('''
    id,
    id_societa,
    created_at,
    tariffe_sport,
    societa!inner(
      *,
      orari_societa!inner(
        giorno_settimana,
        is_chiuso
      )
    )
  ''')
          .filter('tariffe_sport', 'cs', '[{"sport":"$sport"}]')
          .eq('societa.orari_societa.giorno_settimana', giornoSettimana)
          .eq('societa.orari_societa.is_chiuso', false);

      final response = provincia != null && provincia.trim().isNotEmpty
          ? await query.eq('societa.provincia', provincia.trim())
          : await query;

      final List<dynamic> righeSport = response as List;

      if (righeSport.isEmpty) {
        return [];
      }

      // 2. Recuperiamo gli ID delle società candidate.
      final Set<String> idsSocieta = righeSport
          .map((row) => row['id_societa'].toString())
          .toSet();

      if (idsSocieta.isEmpty) {
        return [];
      }

      // 3. Recuperiamo TUTTI i campi delle società candidate,
      // nello stesso ordine usato per determinare quali sono visibili.
      //
      // È una sola query aggiuntiva, indipendentemente
      // dal numero di società trovate.
      final campiResponse = await _supabase
          .from('campi')
          .select('id, id_societa, created_at')
          .inFilter('id_societa', idsSocieta.toList())
          .order('created_at', ascending: true);

      final List<dynamic> tuttiCampi = campiResponse as List;

      // 4. Raggruppiamo i campi per società mantenendo l'ordine.
      final Map<String, List<String>> campiPerSocieta = {};

      for (final campo in tuttiCampi) {
        final idSocieta = campo['id_societa'].toString();
        final idCampo = campo['id'].toString();

        campiPerSocieta.putIfAbsent(idSocieta, () => <String>[]);

        campiPerSocieta[idSocieta]!.add(idCampo);
      }

      // 5. Recuperiamo limite_campi dalle società già presenti
      // nella prima query.
      final Map<String, int> limitiPerSocieta = {};

      for (final row in righeSport) {
        final datiSocieta = row['societa'] as Map<String, dynamic>?;

        if (datiSocieta == null) continue;

        final idSocieta = datiSocieta['id'].toString();

        limitiPerSocieta[idSocieta] =
            (datiSocieta['limite_campi'] as num?)?.toInt() ?? 0;
      }

      // 6. Costruiamo l'insieme dei campi realmente VISIBILI.
      final Set<String> campiVisibili = {};

      for (final entry in campiPerSocieta.entries) {
        final idSocieta = entry.key;
        final campi = entry.value;

        final limite = limitiPerSocieta[idSocieta] ?? 0;

        if (limite <= 0) continue;

        campiVisibili.addAll(campi.take(limite));
      }

      // 7. Ora consideriamo soltanto i campi che:
      // - supportano lo sport
      // - sono dentro limite_campi
      // - appartengono a una società aperta quel giorno.
      final Map<String, Map<String, dynamic>> mappaRisultati = {};

      for (final row in righeSport) {
        final idCampo = row['id'].toString();

        // Campo sospeso/invisibile dal piano:
        // NON deve far comparire la società.
        if (!campiVisibili.contains(idCampo)) {
          continue;
        }

        if (row['societa'] == null) continue;

        final societa = Societa.fromJson(
          row['societa'] as Map<String, dynamic>,
        );

        double prezzoMinimo = 0.0;

        final List tariffe = row['tariffe_sport'] as List? ?? [];

        for (final t in tariffe) {
          final sportTariffa =
              t['sport']?.toString().trim().toLowerCase() ?? '';

          final sportRichiesto = sport.trim().toLowerCase();

          if (sportTariffa == sportRichiesto) {
            prezzoMinimo = (t['prezzo'] as num?)?.toDouble() ?? 0.0;

            break;
          }
        }

        if (prezzoMinimo <= 0) {
          continue;
        }

        // Se più campi VISIBILI supportano lo stesso sport,
        // mostriamo il prezzo più conveniente.
        if (!mappaRisultati.containsKey(societa.id) ||
            prezzoMinimo < (mappaRisultati[societa.id]!['prezzo'] as double)) {
          mappaRisultati[societa.id] = {
            'societa': societa,
            'prezzo': prezzoMinimo,
          };
        }
      }

      debugPrint(
        "Società visibili, aperte e con $sport: "
        "${mappaRisultati.length}",
      );

      return mappaRisultati.values.toList();
    } catch (e) {
      debugPrint("Errore ricerca società con filtri: $e");
      return [];
    }
  }
}
