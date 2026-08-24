import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/admin/presentation/widgets/foto_societa_widget.dart';
import 'package:app_campi/features/admin/presentation/widgets/telefono_form_widget.dart';
import 'package:app_campi/features/admin/presentation/widgets/indirizzo_form_widget.dart';
import 'package:app_campi/features/admin/presentation/service/geocoding_service.dart';
import 'package:app_campi/features/auth/data/auth_repository.dart';
import 'package:app_campi/features/admin/presentation/pages/attivazione_pagamenti_page.dart';

const Color _coloreElementi = AppTheme.neonOrange;

class RegistrazioneProprietario extends StatefulWidget {
  final String pianoScelto;
  final String? sessionId;

  const RegistrazioneProprietario({
    super.key,
    required this.pianoScelto,
    this.sessionId,
  });

  @override
  State<RegistrazioneProprietario> createState() =>
      _RegistrazioneProprietarioState();
}

class _RegistrazioneProprietarioState extends State<RegistrazioneProprietario> {
  final _formKey = GlobalKey<FormState>();

  final _pIvaController = TextEditingController();
  final _nomeSocietaController = TextEditingController();
  final _nomeProprietarioController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _numeroFissoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confermaPasswordController = TextEditingController();
  final _viaController = TextEditingController();
  final _civicoController = TextEditingController();
  final _cittaController = TextEditingController();
  final _provinciaController = TextEditingController();
  TextEditingController? _viaInternalController;

  final _pIvaFocus = FocusNode();
  final _nomeSocietaFocus = FocusNode();
  final _viaFocus = FocusNode();
  final _civicoFocus = FocusNode();
  final _cittaFocus = FocusNode();
  final _provinciaFocus = FocusNode();
  final _nomeProprietarioFocus = FocusNode();
  final _telefonoFocus = FocusNode();
  final _numeroFissoFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confermaPasswordFocus = FocusNode();

  String? _stripeCustomerId;
  Map<String, double>? _coordinateIndirizzoSelezionato;
  bool _mostraPassword = false;
  bool _mostraConfermaPassword = false;
  String _telefonoCompleto = '';
  bool _telefonoValido = false;

  final Map<String, bool> _campiAbbandonati = {};

  Uint8List? _fotoBytes;
  String? _estensioneFoto;

  @override
  void initState() {
    super.initState();
    _configuraListenerFocus(_pIvaFocus, 'pIva');
    _configuraListenerFocus(_nomeSocietaFocus, 'nomeSocieta');
    _configuraListenerFocus(_viaFocus, 'via');
    _configuraListenerFocus(_civicoFocus, 'civico');
    _configuraListenerFocus(_cittaFocus, 'citta');
    _configuraListenerFocus(_provinciaFocus, 'provincia');
    _configuraListenerFocus(_nomeProprietarioFocus, 'nomeProprietario');
    _configuraListenerFocus(_telefonoFocus, 'telefono');
    _configuraListenerFocus(_numeroFissoFocus, 'numeroFisso');
    _configuraListenerFocus(_emailFocus, 'email');
    _configuraListenerFocus(_passwordFocus, 'password');
    _configuraListenerFocus(_confermaPasswordFocus, 'confermaPassword');
  }

  void _configuraListenerFocus(FocusNode focusNode, String campoKey) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        setState(() => _campiAbbandonati[campoKey] = true);
      }
    });
  }

  @override
  void dispose() {
    _pIvaController.dispose();
    _nomeSocietaController.dispose();
    _nomeProprietarioController.dispose();
    _numeroFissoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confermaPasswordController.dispose();
    _viaController.dispose();
    _civicoController.dispose();
    _cittaController.dispose();
    _provinciaController.dispose();
    _pIvaFocus.dispose();
    _nomeSocietaFocus.dispose();
    _viaFocus.dispose();
    _civicoFocus.dispose();
    _cittaFocus.dispose();
    _provinciaFocus.dispose();
    _nomeProprietarioFocus.dispose();
    _telefonoController.dispose();
    _telefonoFocus.dispose();
    _numeroFissoFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confermaPasswordFocus.dispose();
    super.dispose();
  }

  Widget _buildNeonFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String campoKey,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      validator: (val) {
        if (_campiAbbandonati[campoKey] != true) return null;
        return validator?.call(val);
      },
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppTheme.neonOrange),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.cardBg,
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppTheme.neonOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
        ),
      ),
    );
  }

  void _inviaDati() async {
    setState(() => _campiAbbandonati.updateAll((key, value) => true));

    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifica indirizzo e creazione account...'),
          backgroundColor: AppTheme.neonOrange,
        ),
      );

      try {
        int limiteCampi = 0;
        final String? sessionIdDallUrl = widget.sessionId;

        if (sessionIdDallUrl != null && sessionIdDallUrl.isNotEmpty) {
          try {
            final response = await Supabase.instance.client.functions.invoke(
              'ottieni-dati-sessione',
              body: {'session_id': sessionIdDallUrl},
            );
            if (response.data != null &&
                response.data['stripe_customer_id'] != null) {
              _stripeCustomerId = response.data['stripe_customer_id'] as String;
              final priceId = response.data['price_id'] as String?;
              if (priceId != null) {
                const prezziLimiti = {
                  'price_1Th5bHFxZCOuiQIAaia7ASFn': 1,
                  'price_1TgjxqFxZCOuiQIA9CjLu34s': 2,
                  'price_1Th5c2FxZCOuiQIAM6obraB0': 4,
                  'price_1Th5cRFxZCOuiQIA4VAKya37': 5,
                };
                limiteCampi = prezziLimiti[priceId] ?? 0;
              }
            }
          } catch (e) {
            debugPrint("Errore Edge Function: $e");
          }
        }

        String indirizzoUnito =
            '${(_viaInternalController?.text ?? _viaController.text).trim()} ${_civicoController.text.trim()}, ${_cittaController.text.trim()}, ${_provinciaController.text.trim().toUpperCase()}';

        Map<String, double>? coordinate = _coordinateIndirizzoSelezionato;

        coordinate ??= await GeocodingService.ottieniCoordinate(indirizzoUnito);

        if (coordinate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Non riesco a localizzare questo indirizzo. '
                'Controlla via, civico, città e provincia.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        final double lat = coordinate?['latitudine'] ?? 0.0;
        final double lng = coordinate?['longitudine'] ?? 0.0;

        final String idSocieta = await AuthService().registraProprietario(
          email: _emailController.text,
          password: _passwordController.text,
          nomeProprietario: _nomeProprietarioController.text,
          pIva: _pIvaController.text,
          nomeSocieta: _nomeSocietaController.text,
          indirizzo: indirizzoUnito,
          telefonoFisso: _numeroFissoController.text,
          cellulare: _telefonoController.text.trim(),
          latitudine: lat,
          longitudine: lng,
          pianoScelto: widget.pianoScelto,
          limiteCampi: limiteCampi,
          stripeCustomerId: _stripeCustomerId,
        );

        if (_fotoBytes != null && _estensioneFoto != null) {
          final fileName = '${idSocieta}_logo.$_estensioneFoto';
          await Supabase.instance.client.storage
              .from('avatar_societa')
              .uploadBinary(
                fileName,
                _fotoBytes!,
                fileOptions: const FileOptions(upsert: true),
              );
          final String publicUrl = Supabase.instance.client.storage
              .from('avatar_societa')
              .getPublicUrl(fileName);
          await Supabase.instance.client
              .from('societa')
              .update({'foto_url': publicUrl})
              .eq('id', idSocieta);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('first_time', false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AttivazionePagamentiPage(idSocieta: idSocieta),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: const Text(
          'Registrazione Società',
          style: TextStyle(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: _coloreElementi,
          ),
        ),
        iconTheme: const IconThemeData(color: _coloreElementi),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aggiungi il tuo Centro Sportivo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonOrange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'I campi contrassegnati con * sono obbligatori.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                  const SizedBox(height: 25),

                  // FOTO
                  FotoSocietaWidget(
                    fotoBytes: _fotoBytes,
                    onFotoSelezionata: (bytes, estensione) {
                      setState(() {
                        _fotoBytes = bytes;
                        _estensioneFoto = estensione;
                      });
                    },
                    onFotoRimossa: () {
                      setState(() {
                        _fotoBytes = null;
                        _estensioneFoto = null;
                      });
                    },
                  ),
                  const SizedBox(height: 25),

                  // PARTITA IVA
                  _buildNeonFormField(
                    controller: _pIvaController,
                    focusNode: _pIvaFocus,
                    campoKey: 'pIva',
                    label: 'Partita IVA *',
                    icon: Icons.receipt_long,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Inserisci la Partita IVA';
                      if (!RegExp(r'^\d{11}$').hasMatch(val.trim()))
                        return 'Deve contenere esattamente 11 numeri';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // NOME SOCIETÀ
                  _buildNeonFormField(
                    controller: _nomeSocietaController,
                    focusNode: _nomeSocietaFocus,
                    campoKey: 'nomeSocieta',
                    label: 'Nome della Società *',
                    icon: Icons.business,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Inserisci il nome della società';
                      if (val.trim().length < 3) return 'Almeno 3 lettere';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // INDIRIZZO
                  IndirizzoFormWidget(
                    viaController: _viaController,
                    civicoController: _civicoController,
                    cittaController: _cittaController,
                    provinciaController: _provinciaController,
                    viaFocus: _viaFocus,
                    civicoFocus: _civicoFocus,
                    cittaFocus: _cittaFocus,
                    provinciaFocus: _provinciaFocus,
                    campiAbbandonati: _campiAbbandonati,

                    onViaControllerReady: (controller) {
                      _viaInternalController = controller;
                    },

                    onCoordinateSelezionate: (coordinate) {
                      setState(() {
                        _coordinateIndirizzoSelezionato = coordinate;
                      });
                    },

                    onIndirizzoModificato: () {
                      if (_coordinateIndirizzoSelezionato != null) {
                        setState(() {
                          _coordinateIndirizzoSelezionato = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // NOME PROPRIETARIO
                  _buildNeonFormField(
                    controller: _nomeProprietarioController,
                    focusNode: _nomeProprietarioFocus,
                    campoKey: 'nomeProprietario',
                    label: 'Nome e Cognome Proprietario *',
                    icon: Icons.person,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Inserisci nome e cognome'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  TelefonoFormWidget(
                    controller: _telefonoController,
                    focusNode: _telefonoFocus,
                  ),

                  // TELEFONO FISSO
                  _buildNeonFormField(
                    controller: _numeroFissoController,
                    focusNode: _numeroFissoFocus,
                    campoKey: 'numeroFisso',
                    label: 'Numero Fisso (Facoltativo)',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  // EMAIL
                  _buildNeonFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    campoKey: 'email',
                    label: 'Email Aziendale *',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Inserisci l\'indirizzo email';
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(val.trim()))
                        return 'Inserisci una email valida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // PASSWORD
                  _buildNeonFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    campoKey: 'password',
                    label: 'Password *',
                    icon: Icons.lock,
                    obscureText: !_mostraPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostraPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _mostraPassword = !_mostraPassword),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return 'Inserisci una password';
                      if (val.length < 8) return 'Minimo 8 caratteri';
                      if (!RegExp(r'[A-Z]').hasMatch(val))
                        return 'Almeno 1 lettera maiuscola';
                      if (!RegExp(
                        r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]',
                      ).hasMatch(val))
                        return 'Almeno 1 carattere speciale';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // CONFERMA PASSWORD
                  _buildNeonFormField(
                    controller: _confermaPasswordController,
                    focusNode: _confermaPasswordFocus,
                    campoKey: 'confermaPassword',
                    label: 'Conferma Password *',
                    icon: Icons.lock_outline,
                    obscureText: !_mostraConfermaPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostraConfermaPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                        () =>
                            _mostraConfermaPassword = !_mostraConfermaPassword,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return 'Conferma la password';
                      if (val != _passwordController.text)
                        return 'Le password non coincidono';
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // BOTTONE
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _inviaDati,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonOrange,
                        foregroundColor: AppTheme.darkBg,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Conferma e Salva Dati',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
