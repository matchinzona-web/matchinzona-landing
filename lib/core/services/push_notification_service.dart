import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;

  static bool _inizializzato = false;

  static StreamSubscription<String>? _tokenRefreshSubscription;

  static Future<void> inizializza() async {
    if (_inizializzato) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        await _salvaToken(token);
      }

      await _tokenRefreshSubscription?.cancel();

      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((
        nuovoToken,
      ) async {
        try {
          await _salvaToken(nuovoToken);
        } catch (e) {
          debugPrint('Errore aggiornamento push token: $e');
        }
      });

      _inizializzato = true;

      debugPrint('Push notification service inizializzato.');
    } catch (e) {
      debugPrint('Errore inizializzazione notifiche push: $e');
    }
  }

  static Future<void> _salvaToken(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final piattaforma = Platform.isIOS ? 'ios' : 'android';

    await _supabase.rpc(
      'registra_push_token',
      params: {'p_token': token, 'p_piattaforma': piattaforma},
    );

    debugPrint('Push token salvato per ${user.id}');
  }

  static Future<void> rimuoviTokenCorrente() async {
    try {
      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        final risultato = await _supabase.rpc(
          'rimuovi_push_token',
          params: {'p_token': token},
        );

        debugPrint('Token corrente: $token');
        debugPrint(
          'Utente corrente prima del logout: ${_supabase.auth.currentUser?.id}',
        );
        debugPrint('Token eliminati dal DB: $risultato');
      }
    } catch (e) {
      debugPrint('Errore rimozione push token: $e');
    } finally {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      _inizializzato = false;
    }
  }
}
