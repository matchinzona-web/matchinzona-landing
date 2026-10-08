import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/models/notifica.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';

final notificheStreamProvider = FutureProvider<List<Notifica>>((ref) async {
  final utente = ref.watch(utenteCorrenteProvider).value;

  if (utente == null) {
    return [];
  }

  final response = await Supabase.instance.client
      .from('notifiche')
      .select()
      .eq('id_utente', utente.id)
      .order('created_at', ascending: false);

  return (response as List).map((json) => Notifica.fromJson(json)).toList();
});
