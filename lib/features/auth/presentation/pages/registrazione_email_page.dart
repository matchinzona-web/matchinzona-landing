import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_campi/features/auth/data/auth_repository.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_campi/core/utils/validators.dart';
import 'package:app_campi/core/theme/app_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';

const double _spazioTraCampi = 20.0;

class RegistrazioneEmailPage extends ConsumerStatefulWidget {
  const RegistrazioneEmailPage({super.key});

  @override
  ConsumerState<RegistrazioneEmailPage> createState() =>
      _RegistrazioneEmailPageState();
}

class _RegistrazioneEmailPageState
    extends ConsumerState<RegistrazioneEmailPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confermaPasswordController =
      TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfermaPassword = true;
  bool _accettoGDPR = false;
  bool _mostraErroreGDPR = false;
  String? _erroreDataNascita;
  bool _dataNascitaFocused = false;

  DateTime? _dataNascitaSelezionata;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confermaPasswordController.dispose();
    _telefonoController.dispose();

    super.dispose();
  }

  Future<void> _selezionaData(BuildContext context) async {
    final oggi = DateTime.now();
    final ultimaDataConsentita = DateTime(oggi.year - 14, oggi.month, oggi.day);
    final DateTime? prescelto = await showDatePicker(
      context: context,
      initialDate: ultimaDataConsentita,
      firstDate: DateTime(1900),
      lastDate: ultimaDataConsentita,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accent,
              onPrimary: AppTheme.darkBg,
              surface: AppTheme.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (prescelto != null && prescelto != _dataNascitaSelezionata) {
      setState(() {
        _dataNascitaSelezionata = prescelto;
      });
    }
  }

  Future<void> _submitData() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!_accettoGDPR) {
      setState(() => _mostraErroreGDPR = true);
    }

    if (_dataNascitaSelezionata != null) {
      final etaValida = _haAlmeno14Anni(_dataNascitaSelezionata!);
      setState(() {
        _erroreDataNascita = etaValida
            ? null
            : "Devi avere almeno 14 anni per registrarti.";
      });
    } else {
      setState(() => _erroreDataNascita = "Seleziona la tua data di nascita *");
    }

    if (!isValid || _mostraErroreGDPR || _erroreDataNascita != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: const Text(
            'Si è verificato un errore. Riprova.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.statoErrore,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      await authService.registraGiocatore(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nome: _nomeController.text.trim(),
        cognome: _cognomeController.text.trim(),
        dataNascita: _dataNascitaSelezionata,
        telefono: _telefonoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registrazione completata con successo!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        ref.invalidate(utenteCorrenteProvider);

        try {
          await ref.read(utenteCorrenteProvider.future);
        } catch (_) {}

        if (!mounted) return;

        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (msg.toLowerCase().contains('already registered') ||
            msg.toLowerCase().contains('already exists')) {
          msg = "Questa email è già registrata. Vai alla pagina di login!";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.statoErrore,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                        "REGISTRAZIONE",
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
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 10,
                        ),
                        children: [
                          const Text(
                            'Registrati con email',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'I campi contrassegnati con * sono obbligatori.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

                          TextFormField(
                            controller: _nomeController,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: AppStyles.capsuleDecoration(
                              'Nome *',
                              Icons.person_outline_rounded,
                              coloreTema: AppTheme.accent,
                            ),
                            validator: (val) =>
                                _validaMinLunghezza(val, 'nome'),
                            autovalidateMode: AutovalidateMode.onUnfocus,
                          ),
                          const SizedBox(height: _spazioTraCampi),

                          TextFormField(
                            controller: _cognomeController,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: AppStyles.capsuleDecoration(
                              'Cognome *',
                              Icons.badge_outlined,
                              coloreTema: AppTheme.accent,
                            ),
                            validator: (val) =>
                                _validaMinLunghezza(val, 'cognome'),
                            autovalidateMode: AutovalidateMode.onUnfocus,
                          ),
                          const SizedBox(height: _spazioTraCampi),

                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: AppStyles.capsuleDecoration(
                              'Email *',
                              Icons.email_outlined,
                              coloreTema: AppTheme.accent,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidators.validaEmail,
                            autovalidateMode: AutovalidateMode.onUnfocus,
                          ),
                          const SizedBox(height: _spazioTraCampi),

                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            obscureText: _obscurePassword,
                            decoration: AppStyles.capsuleDecoration(
                              'Password *',
                              Icons.lock_outline_rounded,
                              coloreTema: AppTheme.accent,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: AppValidators.validaPassword,
                            autovalidateMode: AutovalidateMode.onUnfocus,
                          ),
                          const SizedBox(height: _spazioTraCampi),

                          TextFormField(
                            controller: _confermaPasswordController,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            obscureText: _obscureConfermaPassword,
                            decoration: AppStyles.capsuleDecoration(
                              'Conferma Password *',
                              Icons.lock_rounded,
                              coloreTema: AppTheme.accent,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfermaPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfermaPassword =
                                      !_obscureConfermaPassword,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Conferma la password *';
                              }
                              if (val != _passwordController.text) {
                                return 'Le password non coincidono';
                              }
                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUnfocus,
                          ),
                          const SizedBox(height: _spazioTraCampi),

                          InkWell(
                            onTap: () async {
                              setState(() => _dataNascitaFocused = true);
                              await _selezionaData(context);
                              if (_dataNascitaSelezionata != null) {
                                setState(() {
                                  if (!_haAlmeno14Anni(
                                    _dataNascitaSelezionata!,
                                  )) {
                                    _erroreDataNascita =
                                        "Devi avere almeno 14 anni per registrarti.";
                                  } else {
                                    _erroreDataNascita = null;
                                  }
                                });
                              }
                              setState(() => _dataNascitaFocused = false);
                            },
                            borderRadius: BorderRadius.circular(16.0),
                            child: InputDecorator(
                              isFocused: _dataNascitaFocused,
                              isEmpty: _dataNascitaSelezionata == null,
                              decoration: AppStyles.capsuleDecoration(
                                'Data di Nascita *',
                                Icons.calendar_today_rounded,
                                coloreTema: AppTheme.accent,
                              ).copyWith(errorText: _erroreDataNascita),
                              child: Text(
                                _dataNascitaSelezionata == null
                                    ? ''
                                    : '${_dataNascitaSelezionata!.day}/${_dataNascitaSelezionata!.month}/${_dataNascitaSelezionata!.year}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: _spazioTraCampi),

                          TextFormField(
                            controller: _telefonoController,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: AppStyles.capsuleDecoration(
                              'Telefono *',
                              Icons.phone_android_rounded,
                              coloreTema: AppTheme.accent,
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Il telefono è obbligatorio';
                              }

                              final telefono = val.replaceAll(
                                RegExp(r'\s+'),
                                '',
                              );

                              if (!RegExp(r'^3\d{9}$').hasMatch(telefono)) {
                                return 'Inserisci un numero di cellulare italiano valido';
                              }

                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUnfocus,
                          ),
                          const SizedBox(height: 24),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    activeColor: AppTheme.accent,
                                    checkColor: AppTheme.darkBg,
                                    side: BorderSide(
                                      color: _mostraErroreGDPR
                                          ? AppTheme.statoErrore
                                          : AppTheme.textSecondary,
                                      width: 1.5,
                                    ),
                                    value: _accettoGDPR,
                                    onChanged: (bool? valore) {
                                      setState(() {
                                        _accettoGDPR = valore ?? false;
                                        if (_accettoGDPR) {
                                          _mostraErroreGDPR = false;
                                        }
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: "Ho letto e accetto la ",
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "Privacy Policy",
                                            style: const TextStyle(
                                              color: AppTheme.accent,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () => _apriUrlLegale(
                                                "https://matchinzona-web.github.io/matchinzona-privacy/",
                                              ),
                                          ),
                                          const TextSpan(text: " e accetto i "),
                                          TextSpan(
                                            text: "Termini e Condizioni",
                                            style: const TextStyle(
                                              color: AppTheme.accent,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () => _apriUrlLegale(
                                                "https://matchinzona-web.github.io/matchinzona-privacy/termini.html",
                                              ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_mostraErroreGDPR)
                                const Padding(
                                  padding: EdgeInsets.only(left: 12, top: 4),
                                  child: Text(
                                    "È obbligatorio accettare i termini per continuare.",
                                    style: TextStyle(
                                      color: AppTheme.statoErrore,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor: AppTheme.darkBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _submitData,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: AppTheme.darkBg,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'REGISTRATI',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
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

  bool _haAlmeno14Anni(DateTime dataNascita) {
    final adesso = DateTime.now();
    int eta = adesso.year - dataNascita.year;

    if (adesso.month < dataNascita.month ||
        (adesso.month == dataNascita.month && adesso.day < dataNascita.day)) {
      eta--;
    }

    return eta >= 14;
  }

  Future<void> _apriUrlLegale(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Impossibile aprire l'URL $urlString. Errore: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossibile aprire il link. Visita: $urlString"),
          ),
        );
      }
    }
  }

  String? _validaMinLunghezza(String? val, String campo) {
    if (val == null || val.trim().isEmpty) return 'Il $campo è obbligatorio';
    if (val.trim().length < 3) return 'Inserisci almeno 3 lettere';
    return null;
  }
}
