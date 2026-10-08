import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/features/auth/data/auth_repository.dart';

import 'registrazione_email_page.dart';

class RegistrazioneUtente extends ConsumerStatefulWidget {
  const RegistrazioneUtente({super.key});

  @override
  ConsumerState<RegistrazioneUtente> createState() =>
      _RegistrazioneUtenteState();
}

class _RegistrazioneUtenteState extends ConsumerState<RegistrazioneUtente> {
  bool _isLoading = false;

  StreamSubscription<AuthState>? _authSubscription;
  bool _attesaLoginSocial = false;

  @override
  void initState() {
    super.initState();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (!_attesaLoginSocial) return;

      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        _attesaLoginSocial = false;

        if (!mounted) return;

        ref.invalidate(utenteCorrenteProvider);

        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _accediConGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      _attesaLoginSocial = true;

      final authService = AuthService();
      await authService.accediConGoogle();
    } catch (e) {
      _attesaLoginSocial = false;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non è stato possibile continuare con Google.'),
          backgroundColor: AppTheme.statoErrore,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _apriRegistrazioneEmail() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrazioneEmailPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 20,
                    top: 12,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'REGISTRAZIONE',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 30,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.sports_rounded,
                              color: AppTheme.accent,
                              size: 64,
                            ),

                            const SizedBox(height: 24),

                            const Text(
                              'Crea il tuo Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Entra in MatchInZona e trova subito con chi giocare.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 36),

                            SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _accediConGoogle,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textPrimary,
                                  backgroundColor: AppTheme.cardBg,
                                  side: const BorderSide(
                                    color: AppTheme.cardBorder,
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppTheme.accent,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'G',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'CONTINUA CON GOOGLE',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: AppTheme.cardBorder),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    'OPPURE',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: AppTheme.cardBorder),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: TextButton(
                                onPressed: _apriRegistrazioneEmail,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'REGISTRATI CON EMAIL',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
