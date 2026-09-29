import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/models/campo.dart';
import 'package:flutter/material.dart';

class CampiRepository {
  final SupabaseClient _supabase;

  CampiRepository({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchCampiSocieta(String idSocieta) async {
    try {
      final data = await _supabase
          .from('campi')
          .select()
          .eq('id_societa', idSocieta)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw Exception('Errore Database (Lettura Campi): ${e.message}');
    }
  }

  Future<List<Campo>> getCampiSocieta(String idSocieta) async {
    final data = await fetchCampiSocieta(idSocieta);
    return data.map((json) => Campo.fromJson(json)).toList();
  }

  Future<List<Campo>> getCampiSocietaVisibili(String idSocieta) async {
    try {
      final societaData = await _supabase
          .from('societa')
          .select('limite_campi')
          .eq('id', idSocieta)
          .single();

      final int limiteCampi =
          (societaData['limite_campi'] as num?)?.toInt() ?? 0;

      if (limiteCampi <= 0) {
        return [];
      }

      final response = await _supabase
          .from('campi')
          .select()
          .eq('id_societa', idSocieta)
          .order('created_at', ascending: true)
          .limit(limiteCampi);

      return (response as List)
          .map((json) => Campo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Errore in getCampiSocietaVisibili: $e');
      return [];
    }
  }

  Future<List<Campo>> getCampiSocietaConDettagli(String idSocieta) async {
    try {
      final response = await _supabase
          .from('campi')
          .select('*, societa(*)')
          .eq('id_societa', idSocieta)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => Campo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Errore in getCampiSocietaConDettagli: $e");
      rethrow;
    }
  }

  Future<void> insertCampo(Map<String, dynamic> datiCampo) async {
    try {
      await _supabase.from('campi').insert(datiCampo);
    } on PostgrestException catch (e) {
      throw Exception('Errore Database (Creazione Campo): ${e.message}');
    }
  }

  Future<void> updateCampo(
    String idCampo,
    Map<String, dynamic> datiAggiornati,
  ) async {
    try {
      await _supabase.from('campi').update(datiAggiornati).eq('id', idCampo);
    } on PostgrestException catch (e) {
      throw Exception('Errore Database (Aggiornamento Campo): ${e.message}');
    }
  }

  Future<void> deleteCampo(String idCampo) async {
    try {
      await _supabase.from('campi').delete().eq('id', idCampo);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw Exception(
          'Impossibile eliminare: ci sono partite associate a questo campo.',
        );
      }
      throw Exception('Errore Database (Eliminazione Campo): ${e.message}');
    }
  }

  Future<List<Campo>> getCampiByNomeSocieta(String query) async {
    try {
      final response = await _supabase
          .from('campi')
          .select('*, societa!inner(*)')
          .ilike('societa.nome_societa', '%$query%');

      return (response as List)
          .map((json) => Campo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Errore in getCampiByNomeSocieta: $e");
      return [];
    }
  }

  Future<List<Campo>> getCampiByNomeCampo(String query) async {
    try {
      final response = await _supabase
          .from('campi')
          .select('*, societa(*)')
          .ilike('nome_campo', '%$query%');

      return (response as List)
          .map((json) => Campo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Errore in getCampiByNomeCampo: $e");
      return [];
    }
  }

  Future<List<Campo>> getCampiByCitta(String query) async {
    try {
      final response = await _supabase
          .from('campi')
          .select('*, societa!inner(*)')
          .ilike('societa.indirizzo', '%$query%');

      return (response as List)
          .map((json) => Campo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Errore in getCampiByCitta: $e");
      return [];
    }
  }

  Future<void> upsertOrariSocieta(List<Map<String, dynamic>> dati) async {
    try {
      await _supabase.from('orari_societa').upsert(dati);
    } on PostgrestException catch (e) {
      throw Exception('Errore Database (Salvataggio Orari): ${e.message}');
    }
  }
}
