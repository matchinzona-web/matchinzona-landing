import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/models/notifica.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';

final notificheStreamProvider = StreamProvider<List<Notifica>>((ref) {
  final utente = ref.watch(utenteCorrenteProvider).value;

  if (utente == null) {
    return Stream.value(<Notifica>[]);
  }

  return Supabase.instance.client
      .from('notifiche')
      .stream(primaryKey: ['id'])
      .eq('id_utente', utente.id)
      .order('created_at', ascending: false)
      .map(
        (rows) => rows
            .map((json) => Notifica.fromJson(Map<String, dynamic>.from(json)))
            .toList(),
      );
});
