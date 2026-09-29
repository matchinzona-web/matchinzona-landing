import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/profilo/application/profilo_notifier.dart';
import 'package:app_campi/features/admin/presentation/widgets/telefono_form_widget.dart';
import 'package:app_campi/features/admin/presentation/widgets/indirizzo_form_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/services/push_notification_service.dart';

class ProfiloGestore extends ConsumerStatefulWidget {
  final Utente utenteLoggato;
  const ProfiloGestore({super.key, required this.utenteLoggato});

  @override
  ConsumerState<ProfiloGestore> createState() => _ProfiloGestoreState();
}

class _ProfiloGestoreState extends ConsumerState<ProfiloGestore> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final FocusNode _viaFocus = FocusNode();
  final FocusNode _civicoFocus = FocusNode();
  final FocusNode _capFocus = FocusNode();
  final FocusNode _cittaFocus = FocusNode();
  final FocusNode _provinciaFocus = FocusNode();

  late final TextEditingController _nomeController;
  late final TextEditingController _cognomeController;
  final TextEditingController _nomeSocietaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _telefonoFissoController =
      TextEditingController();
  final TextEditingController _viaController = TextEditingController();
  final TextEditingController _civicoController = TextEditingController();
  final TextEditingController _capController = TextEditingController();
  final TextEditingController _cittaController = TextEditingController();
  final TextEditingController _provinciaController = TextEditingController();
  TextEditingController? _viaInternalController;
  Map<String, double>? _coordinateIndirizzo;
  final TextEditingController _nuovaPasswordController =
      TextEditingController();
  final TextEditingController _confermaPasswordController =
      TextEditingController();
  bool _mostraPassword = false;
  bool _mostraConfermaPassword = false;

  final Map<String, bool> _campiAbbandonati = {
    'via': true,
    'civico': true,
    'cap': true,
    'citta': true,
    'provincia': true,
  };

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.utenteLoggato.nome);
    _cognomeController = TextEditingController(
      text: widget.utenteLoggato.cognome,
    );

    Future.microtask(() async {
      await ref
          .read(profiloProvider.notifier)
          .caricaDatiSocieta(widget.utenteLoggato.id);

      final state = ref.read(profiloProvider);
      _telefonoController.text = state.telefonoCompleto;

      final data = await _caricaDatiExtra();

      if (data != null && mounted) {
        _nomeSocietaController.text = data['nome_societa']?.toString() ?? '';

        _telefonoFissoController.text = data['telefono']?.toString() ?? '';

        _impostaDatiIndirizzo(data);
      }
    });
  }

  Future<Map<String, dynamic>?> _caricaDatiExtra() async {
    try {
      return await Supabase.instance.client
          .from('societa')
          .select(
            'nome_societa, telefono, cellulare, indirizzo, '
            'via, civico, cap, comune, provincia',
          )
          .eq('id_utente', widget.utenteLoggato.id)
          .maybeSingle();
    } catch (e) {
      debugPrint("Errore caricamento extra: $e");
      return null;
    }
  }

  void _impostaDatiIndirizzo(Map<String, dynamic> data) {
    final via = data['via']?.toString().trim() ?? '';

    final civico = data['civico']?.toString().trim() ?? '';

    final cap = data['cap']?.toString().trim() ?? '';

    final comune = data['comune']?.toString().trim() ?? '';

    final provincia = data['provincia']?.toString().trim().toUpperCase() ?? '';

    final haIndirizzoStrutturato =
        via.isNotEmpty ||
        civico.isNotEmpty ||
        cap.isNotEmpty ||
        comune.isNotEmpty ||
        provincia.isNotEmpty;

    if (haIndirizzoStrutturato) {
      _viaController.text = via;
      _civicoController.text = civico;
      _capController.text = cap;
      _cittaController.text = comune;
      _provinciaController.text = provincia;

      if (_viaInternalController != null) {
        _viaInternalController!.text = _viaController.text;
      }

      return;
    }

    // Fallback per eventuali record vecchi
    // che hanno ancora solo "indirizzo".
    final indirizzoDb = data['indirizzo']?.toString().trim() ?? '';

    if (indirizzoDb.isEmpty) return;

    final parti = indirizzoDb.split(',');

    if (parti.length >= 3) {
      final viaECivico = parti[0].trim();
      final ultimoSpazio = viaECivico.lastIndexOf(' ');

      if (ultimoSpazio != -1) {
        _viaController.text = viaECivico.substring(0, ultimoSpazio).trim();

        _civicoController.text = viaECivico.substring(ultimoSpazio + 1).trim();
      } else {
        _viaController.text = viaECivico;
      }

      final parteComune = parti[1].trim();

      final match = RegExp(r'^(\d{5})\s+(.+)$').firstMatch(parteComune);

      if (match != null) {
        _capController.text = match.group(1) ?? '';

        _cittaController.text = match.group(2) ?? '';
      } else {
        _cittaController.text = parteComune;
      }

      _provinciaController.text = parti[2]
          .trim()
          .replaceAll('(', '')
          .replaceAll(')', '')
          .toUpperCase();

      if (_viaInternalController != null) {
        _viaInternalController!.text = _viaController.text;
      }
    }
  }

  Future<void> _selezionaFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      String estensione = 'jpg';
      if (image.name.contains('.')) estensione = image.name.split('.').last;
      ref.read(profiloProvider.notifier).setFoto(bytes, estensione);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile selezionare la foto. Riprova.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _salvaProfilo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nuovaPasswordController.text.isNotEmpty) {
      final okPassword = await ref
          .read(profiloProvider.notifier)
          .cambiaPassword(_nuovaPasswordController.text);

      if (!okPassword) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Errore aggiornamento password. Sicuro che sia valida?',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      } else {
        _nuovaPasswordController.clear();
        _confermaPasswordController.clear();
      }
    }

    final successo = await ref
        .read(profiloProvider.notifier)
        .salvaProfilo(
          utenteLoggato: widget.utenteLoggato,
          via: (_viaInternalController?.text ?? _viaController.text).trim(),
          civico: _civicoController.text.trim(),
          cap: _capController.text.trim(),
          citta: _cittaController.text.trim(),
          provincia: _provinciaController.text.trim().toUpperCase(),
          telefonoFisso: _telefonoFissoController.text.trim(),
          nome: _nomeController.text.trim(),
          cognome: _cognomeController.text.trim(),
        );

    if (!mounted) return;

    if (!successo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indirizzo non trovato! Verifica via, civico e città.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await Supabase.instance.client
        .from('societa')
        .update({'nome_societa': _nomeSocietaController.text.trim()})
        .eq('id_utente', widget.utenteLoggato.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profilo aggiornato con successo! ✅'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _nomeSocietaController.dispose();
    _telefonoController.dispose();
    _telefonoFissoController.dispose();
    _viaController.dispose();
    _civicoController.dispose();
    _capController.dispose();
    _cittaController.dispose();
    _provinciaController.dispose();
    _viaFocus.dispose();
    _civicoFocus.dispose();
    _capFocus.dispose();
    _cittaFocus.dispose();
    _provinciaFocus.dispose();
    _nuovaPasswordController.dispose();
    _confermaPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _stileInput(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      counterText: '',
      labelStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: icon != null ? Icon(icon, color: AppTheme.neonOrange) : null,
      filled: true,
      fillColor: AppTheme.cardBg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.neonOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Widget _buildNeonFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    required String campoKey,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: _stileInput(label, icon),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profiloProvider);
    debugPrint("isLoading: ${state.isLoading}");
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Profilo e Sicurezza'),
        backgroundColor: AppTheme.darkBg,
        iconTheme: const IconThemeData(color: AppTheme.neonOrange),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonOrange),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Foto Società',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: state.haImmagine
                                  ? AppTheme.neonOrange
                                  : Colors.grey.shade700,
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (state.fotoBytesLocali != null)
                                  Image.memory(
                                    state.fotoBytesLocali!,
                                    fit: BoxFit.cover,
                                  )
                                else if (state.urlValido)
                                  Image.network(
                                    state.fotoUrl!,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  GestureDetector(
                                    onTap: _selezionaFoto,
                                    behavior: HitTestBehavior.opaque,
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          color: AppTheme.neonOrange,
                                          size: 36,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Carica logo centro',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (state.haImmagine)
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppTheme.neonOrange,
                                          radius: 18,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 18,
                                              color: Colors.black,
                                            ),
                                            onPressed: _selezionaFoto,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          backgroundColor: Colors.redAccent,
                                          radius: 18,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                            onPressed: () => ref
                                                .read(profiloProvider.notifier)
                                                .rimuoviFoto(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          'Dati Personali',
                          style: TextStyle(
                            color: AppTheme.neonOrange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _nomeController,
                          enabled: false,
                          decoration: _stileInput('Nome', Icons.person),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _cognomeController,
                          enabled: false,
                          decoration: _stileInput(
                            'Cognome',
                            Icons.person_outline,
                          ),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 15),

                        TelefonoFormWidget(controller: _telefonoController),
                        _buildNeonFormField(
                          controller: _nomeSocietaController,
                          label: 'Nome Società',
                          icon: Icons.business_rounded,
                          campoKey: 'nome_societa',
                          maxLength: 100,
                          validator: (val) {
                            final nomeSocieta = val?.trim() ?? '';

                            if (nomeSocieta.isEmpty) {
                              return 'Inserisci il nome della società';
                            }

                            if (nomeSocieta.length < 3) {
                              return 'Il nome della società deve avere almeno 3 lettere';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 15),
                        const SizedBox(height: 15),

                        _buildNeonFormField(
                          controller: _telefonoFissoController,
                          label: 'Telefono Fisso',
                          icon: Icons.phone,
                          campoKey: 'fisso',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          'Indirizzo Centro Sportivo',
                          style: TextStyle(
                            color: AppTheme.neonOrange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        IndirizzoFormWidget(
                          viaController: _viaController,
                          civicoController: _civicoController,
                          capController: _capController,
                          cittaController: _cittaController,
                          provinciaController: _provinciaController,
                          viaFocus: _viaFocus,
                          civicoFocus: _civicoFocus,
                          capFocus: _capFocus,
                          cittaFocus: _cittaFocus,
                          provinciaFocus: _provinciaFocus,
                          campiAbbandonati: _campiAbbandonati,
                          onViaControllerReady: (controller) {
                            _viaInternalController = controller;
                            _viaInternalController!.text = _viaController.text;
                          },
                          onCoordinateSelezionate: (coordinate) {
                            _coordinateIndirizzo = coordinate;
                          },
                          onIndirizzoModificato: () {
                            _coordinateIndirizzo = null;
                          },
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Cambia Password',
                          style: TextStyle(
                            color: AppTheme.neonOrange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Lascia vuoto se non vuoi cambiare la password.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _nuovaPasswordController,
                          obscureText: !_mostraPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: _stileInput('Nuova Password', Icons.lock)
                              .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _mostraPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(
                                    () => _mostraPassword = !_mostraPassword,
                                  ),
                                ),
                              ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return null;
                            if (val.length < 8) return 'Minimo 8 caratteri';
                            if (!RegExp(r'[A-Z]').hasMatch(val)) {
                              return 'Almeno 1 lettera maiuscola';
                            }
                            if (!RegExp(
                              r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]',
                            ).hasMatch(val)) {
                              return 'Almeno 1 carattere speciale';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _confermaPasswordController,
                          obscureText: !_mostraConfermaPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _stileInput(
                                'Conferma Nuova Password',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _mostraConfermaPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(
                                    () => _mostraConfermaPassword =
                                        !_mostraConfermaPassword,
                                  ),
                                ),
                              ),
                          validator: (val) {
                            if (_nuovaPasswordController.text.isEmpty) {
                              return null;
                            }
                            if (val != _nuovaPasswordController.text) {
                              return 'Le password non coincidono';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state.isSaving ? null : _salvaProfilo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonOrange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: state.isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Salva Modifiche',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        const Divider(color: AppTheme.cardBorder),

                        const SizedBox(height: 16),

                        const Text(
                          'ZONA PERICOLO',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'L’eliminazione dell’account gestore comporta anche la rimozione '
                          'del centro sportivo, dei campi e dei dati collegati. '
                          'L’operazione non può essere annullata.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _eliminaAccount,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: const Icon(Icons.delete_forever, size: 22),
                            label: const Text(
                              'Elimina Account',
                              style: TextStyle(
                                fontSize: 16,
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

  Future<void> _eliminaAccount() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        title: const Text(
          'Elimina Account e Centro Sportivo',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Sei sicuro di voler eliminare definitivamente il tuo account gestore?\n\n'
          'Verranno rimossi:\n'
          '• il profilo gestore;\n'
          '• il centro sportivo e i relativi campi;\n'
          '• le prenotazioni e gli altri dati collegati al centro;\n'
          '• i dati associati al servizio Matchly.\n\n'
          'L’abbonamento collegato verrà inoltre gestito tramite Stripe.\n\n'
          'Alcuni dati potranno essere conservati solo quando richiesto da obblighi di legge.\n\n'
          'Questa azione è irreversibile.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Elimina Tutto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (conferma != true) return;

    try {
      await PushNotificationService.rimuoviTokenCorrente();

      await Supabase.instance.client.functions.invoke(
        'elimina-account-gestore',
      );

      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore eliminazione'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
