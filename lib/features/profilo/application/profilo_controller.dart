import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';

final profiloControllerProvider = Provider((ref) => ProfiloController(ref));

class ProfiloController {
  final Ref _ref;
  final _supabase = Supabase.instance.client;

  ProfiloController(this._ref);

  Future<void> aggiornaDatiProfilo({
    required String idUtente,
    required String nome,
    required String cognome,
    required String telefono,
    required DateTime dataNascita,
    String? nuovaPassword,
    Map<String, dynamic>? livelliSport,
  }) async {
    try {
      if (nuovaPassword != null && nuovaPassword.isNotEmpty) {
        await _supabase.auth.updateUser(
          UserAttributes(password: nuovaPassword),
        );
      }

      await _supabase
          .from('utenti')
          .update({
            'nome': nome,
            'cognome': cognome,
            'telefono': telefono,
            'data_nascita': dataNascita.toIso8601String(),
            if (livelliSport != null) 'livelli_sport': livelliSport,
          })
          .eq('id', idUtente);

      _ref.invalidate(utenteCorrenteProvider);
      await _ref.read(utenteCorrenteProvider.future);
    } catch (e) {
      rethrow;
    }
  }
}
