import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/services/push_notification_service.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/features/miei_match/application/partite_utente_provider.dart';
import 'package:app_campi/features/prenotazione/application/creazione_partita_controller.dart';

class AuthController {
  final Ref ref;
  AuthController(this.ref);

  Future<void> logout() async {
    try {
      await PushNotificationService.rimuoviTokenCorrente();

      await Supabase.instance.client.auth.signOut();

      ref.invalidate(utenteCorrenteProvider);

      try {
        ref.invalidate(partiteUtenteProvider);
        ref.invalidate(creazionePartitaProvider);
      } catch (_) {}
    } catch (e) {
      rethrow;
    }
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});
