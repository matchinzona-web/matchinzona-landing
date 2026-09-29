import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/models/utente.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final utenteCorrenteProvider = FutureProvider<Utente?>((ref) async {
  // Mantiene il provider aggiornato quando cambia lo stato auth.
  ref.watch(authStateProvider);

  final session = Supabase.instance.client.auth.currentSession;

  if (session == null) {
    return null;
  }

  final response = await Supabase.instance.client
      .from('utenti')
      .select()
      .eq('id', session.user.id)
      .maybeSingle();

  if (response == null) {
    return null;
  }

  return Utente.fromJson(response);
});
