import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;

  static bool _tapInizializzato = false;
  static bool _tokenInizializzato = false;
  static Future<void>? _inizializzazioneInCorso;

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _notificationTapSubscription;

  static final StreamController<Map<String, String>>
  _notificationTapController =
      StreamController<Map<String, String>>.broadcast();

  static Stream<Map<String, String>> get notificationTapStream =>
      _notificationTapController.stream;

  static Map<String, String>? _pendingNotificationTap;

  static Map<String, String>? prendiTapPendente() {
    final pending = _pendingNotificationTap;
    _pendingNotificationTap = null;
    return pending;
  }

  static void ripubblicaTap(Map<String, String> payload) {
    _notificationTapController.add(payload);
  }

  static Future<void> inizializza() {
    final esistente = _inizializzazioneInCorso;

    if (esistente != null) {
      return esistente;
    }

    final future = _inizializzaInternamente();

    _inizializzazioneInCorso = future;

    return future.whenComplete(() {
      _inizializzazioneInCorso = null;
    });
  }

  static Future<void> _inizializzaInternamente() async {
    await _inizializzaGestioneTap();

    if (_tokenInizializzato) return;

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

      _tokenInizializzato = true;

      debugPrint('Push notification service inizializzato.');
    } catch (e) {
      debugPrint('Errore inizializzazione notifiche push: $e');
    }
  }

  static Future<void> _inizializzaGestioneTap() async {
    if (_tapInizializzato) return;

    _tapInizializzato = true;

    await _notificationTapSubscription?.cancel();

    _notificationTapSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      debugPrint('Push aperta da app in background.');
      _gestisciTapNotifica(message);
    });

    debugPrint('Controllo getInitialMessage...');

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('getInitialMessage TROVATA.');
      debugPrint('initialMessage.data = ${initialMessage.data}');
      debugPrint(
        'initialMessage.notification = ${initialMessage.notification?.title}',
      );

      _gestisciTapNotifica(initialMessage);
    } else {
      debugPrint('getInitialMessage = NULL');
    }
  }

  static void _gestisciTapNotifica(RemoteMessage message) {
    final data = message.data;

    final payload = <String, String>{
      'tipo': data['tipo']?.toString() ?? 'notifica',
      'notifica_id': data['notifica_id']?.toString() ?? '',
      'id_partita': data['id_partita']?.toString() ?? '',
    };

    debugPrint(
      'Tap notifica: '
      'tipo=${payload['tipo']}, '
      'notificaId=${payload['notifica_id']}, '
      'idPartita=${payload['id_partita']}',
    );

    if (_notificationTapController.hasListener) {
      _notificationTapController.add(payload);
    } else {
      debugPrint('Navigator non ancora in ascolto: salvo tap pendente.');
      _pendingNotificationTap = payload;
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

        debugPrint('Token eliminati dal DB: $risultato');
      }
    } catch (e) {
      debugPrint('Errore rimozione push token: $e');
    } finally {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      // NON cancelliamo il listener del tap:
      // deve continuare a intercettare l'apertura delle notifiche.
      _tokenInizializzato = false;
    }
  }
}
