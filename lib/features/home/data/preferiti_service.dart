import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/models/societa.dart';

class PreferitiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Societa>> getCentriPreferiti(String idUtente) async {
    try {
      final response = await _supabase
          .from('utenti_centri_preferiti')
          .select('societa:id_societa(*)')
          .eq('id_utente', idUtente);

      return (response as List).map((row) {
        final societaJson = row['societa'] as Map<String, dynamic>;
        return Societa.fromJson(societaJson);
      }).toList();
    } catch (e) {
      throw Exception('Errore nel caricamento dei preferiti');
    }
  }

  /// Aggiunge o rimuove un centro dai preferiti
  Future<void> togglePreferito(
    String idUtente,
    String idSocieta,
    bool isAttualmentePreferito,
  ) async {
    try {
      if (isAttualmentePreferito) {
        // Rimuovi
        await _supabase.from('utenti_centri_preferiti').delete().match({
          'id_utente': idUtente,
          'id_societa': idSocieta,
        });
      } else {
        // Aggiungi
        await _supabase.from('utenti_centri_preferiti').insert({
          'id_utente': idUtente,
          'id_societa': idSocieta,
        });
      }
    } catch (e) {
      throw Exception('Errore nell\'aggiornamento dei preferiti');
    }
  }
}
