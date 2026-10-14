import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/utils/connessione_provider.dart';
import 'core/shared_widget/connessione_assente_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/services/push_notification_service.dart';

import 'features/home/presentation/home_page.dart';
import 'features/auth/presentation/widgets/auth_gate.dart';
import 'features/auth/presentation/pages/login_utente.dart';
import 'features/auth/presentation/pages/registrazione_utente.dart';
import 'features/home/presentation/views/onboarding_screen.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';

import 'features/chat/match_chat_page.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      "pk_test_51TgQ7WFxZCOuiQIAWEPNT2Kc7Lz9nfU8kTdNDoy36EfKi8zBcGt4r6GiNVbWI3mlYfTe2F1Y3dFCZ9k6hRdavFCH00Kbrz8a7q";
  await Stripe.instance.applySettings();

  await initializeDateFormatting('it_IT', null);

  try {
    await Supabase.initialize(
      url: 'https://uujvjisnzwpahujggppv.supabase.co',
      anonKey: 'sb_publishable_77eBpp9K9qMnGugAgqRLew_-Avdl6gw',
    );
    debugPrint("Supabase inizializzato correttamente.");
  } catch (e) {
    debugPrint("Errore fatale inizializzazione Supabase: $e");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: PrenotaCampoApp()));
}

class PrenotaCampoApp extends StatefulWidget {
  const PrenotaCampoApp({super.key});

  @override
  State<PrenotaCampoApp> createState() => _PrenotaCampoAppState();
}

class _PrenotaCampoAppState extends State<PrenotaCampoApp>
    with WidgetsBindingObserver {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Map<String, String>>? _pushTapSubscription;
  StreamSubscription<AuthState>? _passwordRecoverySubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    initDeepLinks();

    _passwordRecoverySubscription = Supabase
        .instance
        .client
        .auth
        .onAuthStateChange
        .listen((data) {
          if (data.event != AuthChangeEvent.passwordRecovery) {
            return;
          }

          debugPrint('Sessione password recovery confermata da Supabase.');

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) =>
                    const ResetPasswordPage(isRecoverySession: true),
              ),
              (route) => false,
            );
          });
        });

    _pushTapSubscription = PushNotificationService.notificationTapStream.listen(
      (data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _gestisciTapPush(data);
        });
      },
    );

    Future.microtask(() async {
      // Qui inizializziamo subito il listener del TAP.
      // Se l'utente non è ancora disponibile, il token verrà
      // inizializzato successivamente da AuthGate.
      await PushNotificationService.inizializza();

      final pending = PushNotificationService.prendiTapPendente();

      if (pending != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _gestisciTapPush(pending);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllaCheckoutPending();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _pushTapSubscription?.cancel();
    _passwordRecoverySubscription?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controllaCheckoutPending();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pending = PushNotificationService.prendiTapPendente();

        if (pending != null) {
          _gestisciTapPush(pending);
        }
      });
    }
  }

  Future<void> initDeepLinks() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) _gestisciLink(uri);

    _appLinks.uriLinkStream.listen((Uri uri) {
      _gestisciLink(uri);
    });
  }

  Future<void> _gestisciTapPush(Map<String, String> data) async {
    final tipo = data['tipo'] ?? '';
    final idPartita = data['id_partita'] ?? '';

    debugPrint('Navigazione push -> tipo=$tipo, idPartita=$idPartita');

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    switch (tipo) {
      case 'giocatore_unito':
      case 'giocatore_abbandonato':
      case 'match_completo':
      case 'completa':
      case 'match_a_rischio':
      case 'aperta_a_rischio':
      case 'match_annullato':
      case 'annullata':
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage(initialIndex: 2)),
          (route) => false,
        );
        return;

      case 'messaggio_chat':
        if (idPartita.isEmpty) {
          return;
        }

        try {
          final partita = await Supabase.instance.client
              .from('partite')
              .select('''
              campo:campi(
                societa(
                  nome_societa
                )
              )
            ''')
              .eq('id', idPartita)
              .maybeSingle();

          final nomeSocieta =
              partita?['campo']?['societa']?['nome_societa']?.toString() ??
              'Centro Sportivo';

          navigator.push(
            MaterialPageRoute(
              builder: (_) =>
                  MatchChatPage(matchId: idPartita, nomeSocieta: nomeSocieta),
            ),
          );
        } catch (e) {
          debugPrint('Errore apertura chat da push: $e');
        }

        return;

      case 'prenotazione_gestore':
      case 'prenotazione_annullata_gestore':
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
        return;

      default:
        return;
    }
  }

  Future<void> _gestisciLink(Uri uri) async {
    debugPrint("Link ricevuto: $uri");

    // =========================================================
    // RESET PASSWORD SUPABASE
    // =========================================================
    final isResetPassword =
        uri.scheme == 'myapp' && uri.host == 'reset-password';

    if (isResetPassword) {
      debugPrint(
        'Deep link reset password ricevuto. '
        'Attendo la conferma passwordRecovery di Supabase.',
      );

      return;
    }

    // =========================================================
    // INVITO MATCH DA WHATSAPP / APP LINK
    // =========================================================

    final isMatchInvite =
        uri.scheme == 'https' &&
        uri.host == 'matchinzona-landing.vercel.app' &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'match';

    if (isMatchInvite) {
      final idPartita = uri.pathSegments[1];

      debugPrint('Invito match ricevuto: $idPartita');

      await _gestisciInvitoMatch(idPartita);

      return;
    }

    // =========================================================
    // RITORNO CHECKOUT STRIPE ABBONAMENTO
    // =========================================================
    final isAbbonamentoStripe =
        uri.scheme == 'myapp' && uri.host == 'abbonamento';

    if (!isAbbonamentoStripe) {
      return;
    }

    final sessionId = uri.queryParameters['session_id'];
    final status = uri.queryParameters['status'];

    debugPrint(
      'Ritorno Stripe abbonamento -> '
      'status: $status, '
      'sessionId: $sessionId',
    );

    if (status == 'cancel') {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('stripe_checkout_session_pending');
      await prefs.remove('stripe_checkout_piano_pending');

      debugPrint('Checkout Stripe annullato.');

      return;
    }

    if (status != 'success' || sessionId == null || sessionId.isEmpty) {
      return;
    }

    await _verificaCheckoutENaviga(sessionId: sessionId);
  }

  Future<void> _gestisciInvitoMatch(String idPartita) async {
    final navigator = navigatorKey.currentState;

    if (navigator == null || idPartita.isEmpty) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      navigator.pushNamed('/login');
      return;
    }

    try {
      final iscrizione = await Supabase.instance.client
          .from('giocatori_partita')
          .select('id_partita')
          .eq('id_partita', idPartita)
          .eq('id_utente', user.id)
          .maybeSingle();

      final giaIscritto = iscrizione != null;

      if (giaIscritto) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage(initialIndex: 2)),
          (route) => false,
        );

        return;
      }

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage(initialIndex: 1)),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Errore gestione invito match: $e');
    }
  }

  bool _stoNavigandoDopoCheckout = false;

  Future<void> _verificaCheckoutENaviga({required String sessionId}) async {
    if (_stoNavigandoDopoCheckout) {
      return;
    }

    _stoNavigandoDopoCheckout = true;

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ottieni-dati-sessione',
        body: {'session_id': sessionId},
      );

      final data = response.data;

      if (data is! Map || data['completed'] != true) {
        debugPrint('Checkout Stripe non ancora completato.');
        return;
      }

      final idSocieta = data['id_societa']?.toString();

      if (idSocieta == null || idSocieta.isEmpty) {
        debugPrint('Checkout completato ma id_societa non disponibile.');
        return;
      }

      debugPrint('Checkout completato. Società: $idSocieta');

      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('stripe_checkout_session_pending');

      await prefs.remove('stripe_checkout_piano_pending');

      if (!mounted) {
        return;
      }

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Errore verifica checkout Stripe: $e');
    } finally {
      _stoNavigandoDopoCheckout = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MatchInZona',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkNeonTheme,
      builder: (context, child) {
        return Stack(
          children: [
            ScrollConfiguration(
              behavior: NoGlowScrollBehavior(),
              child: child ?? const SizedBox.shrink(),
            ),

            const Positioned.fill(child: ConnessioneAssenteOverlay()),
          ],
        );
      },

      home: const AuthGate(),
      routes: {
        '/home': (context) => const HomePage(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginUtente(),
        '/registrazione': (context) => const RegistrazioneUtente(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        SfGlobalLocalizations.delegate,
      ],
      supportedLocales: const [Locale('it', 'IT')],
      locale: const Locale('it', 'IT'),
    );
  }

  bool _stoControllandoCheckout = false;

  Future<void> _controllaCheckoutPending() async {
    if (_stoControllandoCheckout || _stoNavigandoDopoCheckout) {
      return;
    }

    _stoControllandoCheckout = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      final sessionId = prefs.getString('stripe_checkout_session_pending');

      if (sessionId == null || sessionId.isEmpty) {
        return;
      }

      debugPrint('Controllo checkout pendente: $sessionId');

      final response = await Supabase.instance.client.functions.invoke(
        'ottieni-dati-sessione',
        body: {'session_id': sessionId},
      );

      final data = response.data;

      if (data is! Map) {
        return;
      }

      final completed = data['completed'] == true;

      debugPrint('Checkout completato: $completed');

      if (!completed) {
        return;
      }

      final idSocieta = data['id_societa']?.toString();

      if (idSocieta == null || idSocieta.isEmpty) {
        debugPrint('Checkout completato ma id_societa mancante.');
        return;
      }

      await prefs.remove('stripe_checkout_session_pending');

      await prefs.remove('stripe_checkout_piano_pending');

      if (!mounted) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      });
    } catch (e) {
      debugPrint('Errore controllo checkout pendente: $e');
    } finally {
      _stoControllandoCheckout = false;
    }
  }
}

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
