import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_page.dart';
import 'features/auth/presentation/widgets/auth_gate.dart';
import 'features/auth/presentation/pages/login_utente.dart';
import 'features/auth/presentation/pages/registrazione_utente.dart';
import 'features/home/presentation/views/onboarding_screen.dart';
import 'package:app_campi/features/auth/presentation/pages/registrazione_proprietario_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

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

  runApp(const ProviderScope(child: PrenotaCampoApp()));
}

class PrenotaCampoApp extends StatefulWidget {
  const PrenotaCampoApp({super.key});

  @override
  State<PrenotaCampoApp> createState() => _PrenotaCampoAppState();
}

class _PrenotaCampoAppState extends State<PrenotaCampoApp> {
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) _gestisciLink(uri);

    _appLinks.uriLinkStream.listen((Uri uri) {
      _gestisciLink(uri);
    });
  }

  void _gestisciLink(Uri uri) {
    debugPrint("Link ricevuto: $uri");

    if (uri.host == 'registrazione') {
      final piano = uri.queryParameters['piano'];

      final sessionId = uri.queryParameters['session_id'];

      if (piano != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => RegistrazioneProprietario(
              pianoScelto: piano,
              sessionId: sessionId,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Arena Pro',
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
