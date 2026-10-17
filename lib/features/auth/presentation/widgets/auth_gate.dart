import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/features/home/presentation/landing_gestore_web_page.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/features/admin/presentation/pages/dashboard_gestore_page.dart';
import 'package:app_campi/features/home/presentation/views/onboarding_screen.dart';
import 'package:app_campi/core/services/push_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
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
          return const _AccessoRiservatoGestori();
        }

        // Giocatore normale.
        if (!utente.isGestore) {
          return const _AccessoRiservatoGestori();
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
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: AppTheme.darkBg,
            body: Center(
              child: Text(
                'Impossibile verificare il profilo. Riprova più tardi.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        if (snapshot.data == null) {
          return const _AccessoRiservatoGestori();
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

class _AccessoRiservatoGestori extends StatefulWidget {
  const _AccessoRiservatoGestori();

  @override
  State<_AccessoRiservatoGestori> createState() =>
      _AccessoRiservatoGestoriState();
}

class _AccessoRiservatoGestoriState extends State<_AccessoRiservatoGestori> {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.matchly.app';

  // LINK PROVVISORIO: sostituire con quello ufficiale.
  static const String _appStoreUrl = 'https://apps.apple.com/it/';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mostraPopup();
      }
    });
  }

  Future<void> _apriStore(String indirizzo) async {
    try {
      final aperto = await launchUrl(
        Uri.parse(indirizzo),
        mode: LaunchMode.externalApplication,
      );

      if (!aperto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire lo store.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire lo store.')),
      );
    }
  }

  Future<void> _tornaAllaLanding() async {
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      await Supabase.instance.client.auth.signOut();

      if (!navigator.mounted) return;

      navigator.pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile uscire. Riprova.')),
      );
    }
  }

  Future<void> _mostraPopup() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF111D18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFF33463A)),
            ),
            scrollable: true,
            title: const Column(
              children: [
                Icon(
                  Icons.sports_soccer_rounded,
                  color: Color(0xFF79FF61),
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Sei un giocatore?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Questo portale è riservato ai gestori '
                    'dei centri sportivi.\n\n'
                    'Se vuoi prenotare campi e organizzare '
                    'partite, scarica l’app MatchInZona.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFCFD8D0),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _apriStore(_playStoreUrl),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('GOOGLE PLAY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF79FF61),
                        foregroundColor: const Color(0xFF07100D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _apriStore(_appStoreUrl),
                      icon: const Icon(Icons.apple),
                      label: const Text('APP STORE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF647568)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextButton(
                    onPressed: _tornaAllaLanding,
                    child: const Text(
                      'TORNA ALLA LANDING',
                      style: TextStyle(
                        color: Color(0xFFCFD8D0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF07100D),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF79FF61))),
    );
  }
}
