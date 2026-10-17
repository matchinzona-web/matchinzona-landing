import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/features/home/presentation/landing_gestore_web_page.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/features/admin/presentation/pages/dashboard_gestore_page.dart';
import 'package:app_campi/features/home/presentation/home_page.dart';
import 'package:app_campi/features/home/presentation/views/onboarding_screen.dart';
import 'package:app_campi/features/auth/presentation/pages/completa_profilo_social_page.dart';
import 'package:app_campi/core/services/push_notification_service.dart';
import 'package:app_campi/features/home/presentation/views/onboarding_screen.dart';
import 'package:flutter/foundation.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = Supabase.instance.client.auth.currentUser;

    // Nessuna sessione Supabase:
    // utente non autenticato.
    if (authUser == null) {
      if (kIsWeb) {
        return const LandingGestoreWebPage();
      }

      return const OnboardingScreen();
    }

    final utenteAsync = ref.watch(utenteCorrenteProvider);

    return utenteAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.neonOrange),
        ),
      ),

      error: (err, stack) {
        // L'utente può essere autenticato con Google/Apple
        // ma non avere ancora la riga in public.utenti.
        return _VerificaProfiloSocial(idUtente: authUser.id);
      },

      data: (utente) {
        // Sessione Auth esistente, ma nessun profilo:
        // tipico primo accesso Google/Apple.
        if (utente == null) {
          return const CompletaProfiloSocialPage();
        }

        // Giocatore normale.
        if (!utente.isGestore) {
          return _PushBootstrap(
            key: ValueKey(utente.id),
            child: const HomePage(),
          );
        }

        // Gestore: controlliamo soltanto che esista la società.
        // Il piano NON deve bloccare l'accesso alla dashboard.
        // Se il piano è NESSUNO, il gestore entra comunque,
        // ma i campi risultano sospesi tramite limite_campi = 0.
        return FutureBuilder<Map<String, dynamic>?>(
          future: Supabase.instance.client
              .from('societa')
              .select('id')
              .eq('id_utente', utente.id)
              .maybeSingle(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppTheme.darkBg,
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.neonOrange),
                ),
              );
            }

            final datiSocieta = snapshot.data;

            // Solo se il gestore non ha proprio una società collegata
            // torniamo all'onboarding.
            if (datiSocieta == null) {
              return const OnboardingScreen();
            }

            return _PushBootstrap(
              key: ValueKey(utente.id),
              child: DashboardGestore.fromLogin(utenteLoggato: utente),
            );
          },
        );
      },
    );
  }
}

class _VerificaProfiloSocial extends StatelessWidget {
  final String idUtente;

  const _VerificaProfiloSocial({required this.idUtente});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('utenti')
          .select()
          .eq('id', idUtente)
          .maybeSingle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.darkBg,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.neonOrange),
            ),
          );
        }

        // Auth Google/Apple esistente,
        // ma nessun profilo in public.utenti.
        if (snapshot.data == null) {
          return const CompletaProfiloSocialPage();
        }

        // Il profilo esiste: se siamo qui significa
        // che il provider ha avuto un errore diverso.
        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.statoErrore,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Impossibile caricare il profilo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Controlla la connessione e riprova.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    child: const Text('RIPROVA'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PushBootstrap extends StatefulWidget {
  final Widget child;

  const _PushBootstrap({super.key, required this.child});

  @override
  State<_PushBootstrap> createState() => _PushBootstrapState();
}

class _PushBootstrapState extends State<_PushBootstrap> {
  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        debugPrint('Avvio PushNotificationService dal nuovo login...');

        await PushNotificationService.inizializza();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
