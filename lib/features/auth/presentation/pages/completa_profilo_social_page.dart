import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/theme/app_styles.dart';
import 'package:app_campi/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class CompletaProfiloSocialPage extends ConsumerStatefulWidget {
  const CompletaProfiloSocialPage({super.key});

  @override
  ConsumerState<CompletaProfiloSocialPage> createState() =>
      _CompletaProfiloSocialPageState();
}

class _CompletaProfiloSocialPageState
    extends ConsumerState<CompletaProfiloSocialPage> {
  final _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  final TextEditingController _nomeController = TextEditingController();

  final TextEditingController _cognomeController = TextEditingController();

  final TextEditingController _telefonoController = TextEditingController();

  DateTime? _dataNascita;

  bool _isLoading = false;
  bool _caricamentoIniziale = true;
  bool _terminiAccettati = false;
  bool _mostraErroreTermini = false;
  bool _nomeDaSocial = false;
  bool _cognomeDaSocial = false;

  String? _erroreDataNascita;

  @override
  void initState() {
    super.initState();
    _caricaDatiSocial();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _caricaDatiSocial() {
    try {
      final dati = _authService.datiSocialUtenteCorrente();

      final nome = (dati['nome'] ?? '').toString().trim();
      final cognome = (dati['cognome'] ?? '').toString().trim();

      _nomeController.text = nome;
      _cognomeController.text = cognome;

      _nomeDaSocial = nome.isNotEmpty;
      _cognomeDaSocial = cognome.isNotEmpty;
    } catch (e) {
      debugPrint('Errore caricamento dati social: $e');
    }

    if (mounted) {
      setState(() {
        _caricamentoIniziale = false;
      });
    }
  }

  Future<void> _selezionaData() async {
    final oggi = DateTime.now();

    final initialDate = DateTime(oggi.year - 14, oggi.month, oggi.day);

    final scelta = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(oggi.year - 14, oggi.month, oggi.day),
      locale: const Locale('it', 'IT'),
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

    if (scelta == null) {
      return;
    }

    setState(() {
      _dataNascita = scelta;

      if (_haAlmeno14Anni(scelta)) {
        _erroreDataNascita = null;
      } else {
        _erroreDataNascita = 'Devi avere almeno 14 anni.';
      }
    });
  }

  bool _haAlmeno14Anni(DateTime nascita) {
    final oggi = DateTime.now();

    int eta = oggi.year - nascita.year;

    if (oggi.month < nascita.month ||
        (oggi.month == nascita.month && oggi.day < nascita.day)) {
      eta--;
    }

    return eta >= 14;
  }

  String _formattaData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  String? _validaNome(String? valore, String campo) {
    if (valore == null || valore.trim().isEmpty) {
      return '$campo obbligatorio';
    }

    if (valore.trim().length < 2) {
      return '$campo troppo corto';
    }

    return null;
  }

  String? _validaTelefono(String? valore) {
    final numero = (valore ?? '').trim();

    if (numero.isEmpty) {
      return 'Inserisci il numero di cellulare';
    }

    if (!RegExp(r'^\d{10}$').hasMatch(numero)) {
      return 'Inserisci esattamente 10 cifre';
    }

    return null;
  }

  Future<void> _apriUrlLegale(String urlString) async {
    final uri = Uri.parse(urlString);

    try {
      final aperto = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!aperto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile aprire il collegamento.'),
            backgroundColor: AppTheme.statoErrore,
          ),
        );
      }
    } catch (e) {
      debugPrint('Errore apertura URL $urlString: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile aprire il collegamento.'),
            backgroundColor: AppTheme.statoErrore,
          ),
        );
      }
    }
  }

  Future<void> _completaProfilo() async {
    final formValido = _formKey.currentState?.validate() ?? false;
    if (!_terminiAccettati) {
      setState(() {
        _mostraErroreTermini = true;
      });
    }

    if (_dataNascita == null) {
      setState(() {
        _erroreDataNascita = 'Seleziona la data di nascita';
      });
    } else if (!_haAlmeno14Anni(_dataNascita!)) {
      setState(() {
        _erroreDataNascita = 'Devi avere almeno 18 anni.';
      });
    } else {
      setState(() {
        _erroreDataNascita = null;
      });
    }

    if (!formValido || _erroreDataNascita != null || !_terminiAccettati) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Controlla i dati inseriti.'),
          backgroundColor: AppTheme.statoErrore,
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.completaProfiloSocial(
        nome: _nomeController.text.trim(),
        cognome: _cognomeController.text.trim(),
        dataNascita: _dataNascita!,
        telefono: _telefonoController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ref.invalidate(utenteCorrenteProvider);

      await ref.read(utenteCorrenteProvider.future);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilo completato! Benvenuto in MatchInZona.'),
          backgroundColor: AppTheme.statoSuccesso,
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.statoErrore,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_caricamentoIniziale) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();

            if (!mounted) return;

            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withOpacity(0.08),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: AppTheme.accent,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Completa il tuo profilo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Ci servono ancora pochi dati per personalizzare MatchInZona e permetterti di giocare.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 36),

                  TextFormField(
                    controller: _nomeController,
                    readOnly: _nomeDaSocial,
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
                    validator: _nomeDaSocial
                        ? null
                        : (value) => _validaNome(value, 'Nome'),
                  ),

                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _cognomeController,
                    readOnly: _cognomeDaSocial,
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
                    validator: _cognomeDaSocial
                        ? null
                        : (value) => _validaNome(value, 'Cognome'),
                  ),

                  const SizedBox(height: 18),

                  InkWell(
                    onTap: _selezionaData,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: AppStyles.capsuleDecoration(
                        'Data di nascita *',
                        Icons.calendar_today_rounded,
                        coloreTema: AppTheme.accent,
                      ).copyWith(errorText: _erroreDataNascita),
                      child: Text(
                        _dataNascita == null
                            ? 'Seleziona'
                            : _formattaData(_dataNascita!),
                        style: TextStyle(
                          color: _dataNascita == null
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: AppStyles.capsuleDecoration(
                      'Cellulare *',
                      Icons.phone_android_rounded,
                      coloreTema: AppTheme.accent,
                    ),
                    validator: _validaTelefono,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Il cellulare viene utilizzato per le funzionalità legate alle prenotazioni e al tuo profilo.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 26),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _mostraErroreTermini && !_terminiAccettati
                            ? AppTheme.statoErrore
                            : AppTheme.cardBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _terminiAccettati,
                          activeColor: AppTheme.accent,
                          checkColor: AppTheme.darkBg,
                          side: BorderSide(
                            color: _mostraErroreTermini && !_terminiAccettati
                                ? AppTheme.statoErrore
                                : AppTheme.textSecondary,
                            width: 1.5,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _terminiAccettati = value ?? false;

                              if (_terminiAccettati) {
                                _mostraErroreTermini = false;
                              }
                            });
                          },
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: RichText(
                              text: TextSpan(
                                text: 'Ho letto la ',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _apriUrlLegale(
                                        'https://matchinzona-web.github.io/matchinzona-privacy/',
                                      ),
                                  ),

                                  const TextSpan(text: ' e accetto i '),

                                  TextSpan(
                                    text: 'Termini e Condizioni',
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _apriUrlLegale(
                                        'https://matchinzona-web.github.io/matchinzona-privacy/termini.html',
                                      ),
                                  ),

                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_mostraErroreTermini && !_terminiAccettati)
                    const Padding(
                      padding: EdgeInsets.only(left: 14, top: 6),
                      child: Text(
                        'Devi leggere la Privacy Policy e accettare i Termini per continuare.',
                        style: TextStyle(
                          color: AppTheme.statoErrore,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 26),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _completaProfilo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.darkBg,
                        disabledBackgroundColor: Colors.grey.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.darkBg,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        _isLoading ? 'SALVATAGGIO...' : 'CONTINUA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
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
    );
  }
}
