import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/utils/loading_overlay.dart';
import 'package:app_campi/features/auth/data/auth_repository.dart';
import 'dart:io';

class LoginUtente extends ConsumerStatefulWidget {
  const LoginUtente({super.key});

  @override
  ConsumerState<LoginUtente> createState() => _LoginUtenteState();
}

class _LoginUtenteState extends ConsumerState<LoginUtente> {
  final _formKey = GlobalKey<FormState>();

  final supabase = Supabase.instance.client;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _nascondiPassword = true;

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

    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _accediConGoogle() async {
    try {
      _attesaLoginSocial = true;

      final authService = AuthService();

      await authService.accediConGoogle();
    } catch (e) {
      _attesaLoginSocial = false;

      if (!mounted) return;

      _mostraErrore(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _accediConApple() async {
    try {
      _attesaLoginSocial = true;

      final authService = AuthService();

      await authService.accediConApple();
    } catch (e) {
      _attesaLoginSocial = false;

      if (!mounted) return;

      _mostraErrore(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _eseguiLogin() async {
    if (!_formKey.currentState!.validate()) return;

    LoadingOverlay.show(context, testo: "Accesso in corso...");
    final emailInserita = _emailController.text.trim();

    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: emailInserita,
        password: _passwordController.text,
      );

      if (res.session != null && mounted) {
        final userId = res.session!.user.id;

        final userData = await supabase
            .from('utenti')
            .select()
            .eq('id', userId)
            .single();
        final utenteCorrente = Utente.fromJson(userData);

        if (mounted) {
          ref.invalidate(utenteCorrenteProvider);
          try {
            await ref.read(utenteCorrenteProvider.future);
          } catch (_) {}

          LoadingOverlay.hide(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bentornato, ${utenteCorrente.nome}!',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBg,
                ),
              ),
              backgroundColor: AppTheme.statoSuccesso,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        String messaggioTradotto = 'Credenziali non valide: ${e.message}';

        if (e.message.toLowerCase().contains('email not confirmed')) {
          _mostraDialogReinvioEmail(emailInserita);
          return;
        } else if (e.message.toLowerCase().contains(
          'invalid login credentials',
        )) {
          messaggioTradotto = "Email o password errate. Riprova.";
        }

        _mostraErrore(messaggioTradotto);
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        _mostraErrore('Errore di connessione. Riprova più tardi.');
      }
    }
  }

  void _mostraDialogReinvioEmail(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              color: AppTheme.statoAttenzione,
            ),
            SizedBox(width: 10),
            Text(
              'Verifica Email',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Il tuo account non è ancora attivo.\n\nVuoi ricevere un nuovo link di conferma all\'indirizzo:\n$email?',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Annulla',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              LoadingOverlay.show(context, testo: "Invio in corso...");
              try {
                await supabase.auth.resend(type: OtpType.signup, email: email);
                if (mounted) {
                  LoadingOverlay.hide(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Nuovo link inviato! Controlla la posta.',
                        style: TextStyle(
                          color: AppTheme.darkBg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppTheme.statoSuccesso,
                    ),
                  );
                }
              } catch (err) {
                if (mounted) {
                  LoadingOverlay.hide(context);
                  _mostraErrore('Errore di reinvio');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.darkBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Rinvia Link',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostraDialogPasswordDimenticata() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Text(
          'Reimposta password',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: _buildCapsuleDecoration('Email', Icons.email_outlined),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Annulla',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = emailController.text.trim();

              if (value.isEmpty ||
                  !value.contains('@') ||
                  !value.contains('.')) {
                return;
              }

              Navigator.pop(ctx, value);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.darkBg,
            ),
            child: const Text(
              'INVIA LINK',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    LoadingOverlay.show(context, testo: 'Invio link in corso...');

    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'myapp://reset-password',
      );

      if (!mounted) return;

      LoadingOverlay.hide(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ti abbiamo inviato un link per reimpostare la password.\n'
            'Se non lo trovi, controlla anche la cartella Spam.',
            style: TextStyle(
              color: AppTheme.darkBg,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.statoSuccesso,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      LoadingOverlay.hide(context);

      _mostraErrore('Non è stato possibile inviare il link. Riprova.');
    }
  }

  void _mostraErrore(String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          messaggio,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.statoErrore,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _buildCapsuleDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: AppTheme.accent,
        fontWeight: FontWeight.bold,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      filled: true,
      fillColor: AppTheme.cardBg,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 8.0),
        child: Icon(icon, color: AppTheme.textSecondary, size: 22),
      ),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.cardBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.accent, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.statoErrore, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.statoErrore, width: 2.0),
      ),
    );
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
                        "ACCESSO",
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: AppTheme.accent,
                        selectionColor: AppTheme.accent.withOpacity(0.3),
                        selectionHandleColor: AppTheme.accent,
                      ),
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 20.0,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.accent.withOpacity(0.05),
                                      border: Border.all(
                                        color: AppTheme.accent.withOpacity(0.2),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.sports_soccer_rounded,
                                      size: 50,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const Text(
                                  'Bentornato!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Inserisci le tue credenziali per continuare.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),

                                if (Platform.isIOS) ...[
                                  const SizedBox(height: 12),

                                  SizedBox(
                                    height: 56,
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _accediConApple,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textPrimary,
                                        backgroundColor: AppTheme.cardBg,
                                        side: const BorderSide(
                                          color: AppTheme.cardBorder,
                                          width: 1.2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.apple,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'CONTINUA CON APPLE',
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
                                ],

                                SizedBox(
                                  height: 56,
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _accediConApple,
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
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.apple,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'CONTINUA CON APPLE',
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

                                const SizedBox(height: 24),

                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                        color: AppTheme.cardBorder,
                                      ),
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
                                      child: Divider(
                                        color: AppTheme.cardBorder,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // CAMPO EMAIL
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: _buildCapsuleDecoration(
                                    'Email',
                                    Icons.email_outlined,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Inserisci la tua email';
                                    }
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return 'Formato email non valido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // CAMPO PASSWORD
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _nascondiPassword,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: _buildCapsuleDecoration(
                                    'Password',
                                    Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _nascondiPassword
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color: AppTheme.textSecondary,
                                      ),
                                      onPressed: () => setState(
                                        () => _nascondiPassword =
                                            !_nascondiPassword,
                                      ),
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _eseguiLogin(),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Inserisci la password';
                                    }
                                    return null;
                                  },
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _mostraDialogPasswordDimenticata,
                                    child: const Text(
                                      'Password dimenticata?',
                                      style: TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),
                                // BOTTONE DI ACCESSO
                                SizedBox(
                                  height: 56,
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _eseguiLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accent,
                                      foregroundColor: AppTheme.darkBg,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'ACCEDI AL CAMPO',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // LINK ALLA REGISTRAZIONE
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Non hai un account?",
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).pushReplacementNamed(
                                          '/registrazione',
                                        );
                                      },
                                      child: const Text(
                                        "Registrati",
                                        style: TextStyle(
                                          color: AppTheme.accent,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
