import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_page.dart';
import 'features/auth/presentation/widgets/auth_gate.dart';
import 'features/auth/presentation/pages/login_utente.dart';
import 'features/auth/presentation/pages/registrazione_utente.dart';
import 'features/home/presentation/views/onboarding_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:app_campi/features/admin/presentation/pages/configurazione_orari.dart';
import 'package:firebase_core/firebase_core.dart';
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    initDeepLinks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllaCheckoutPending();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controllaCheckoutPending();
    }
  }

  Future<void> initDeepLinks() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) _gestisciLink(uri);

    _appLinks.uriLinkStream.listen((Uri uri) {
      _gestisciLink(uri);
    });
  }

  Future<void> _gestisciLink(Uri uri) async {
    debugPrint("Link ricevuto: $uri");

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
      title: 'Matchly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkNeonTheme,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: NoGlowScrollBehavior(),
          child: child!,
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
