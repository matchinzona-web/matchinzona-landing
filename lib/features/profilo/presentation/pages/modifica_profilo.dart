import 'dart:ui';
import 'package:app_campi/core/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/utils/loading_overlay.dart';
import 'package:app_campi/core/shared_widget/freccia_back.dart';
import 'package:app_campi/core/theme/app_styles.dart';
import 'package:app_campi/core/services/push_notification_service.dart';
import 'package:app_campi/features/profilo/application/profilo_controller.dart';

class ModificaProfiloScreen extends ConsumerStatefulWidget {
  final Utente utente;

  const ModificaProfiloScreen({super.key, required this.utente});

  @override
  ConsumerState<ModificaProfiloScreen> createState() =>
      _ModificaProfiloScreenState();
}

class _ModificaProfiloScreenState extends ConsumerState<ModificaProfiloScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _cognomeController;
  late TextEditingController _telefonoController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confermaPasswordController =
      TextEditingController();

  bool _nascondiConfermaPassword = true;
  DateTime? _dataNascitaSelezionata;
  bool _nascondiPassword = true;
  bool _dataNascitaFocused = false;
  String? _erroreDataNascita;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.utente.nome);
    _cognomeController = TextEditingController(text: widget.utente.cognome);
    _telefonoController = TextEditingController(
      text: widget.utente.telefono ?? '',
    );
    _dataNascitaSelezionata = widget.utente.dataNascita;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confermaPasswordController.dispose();
    super.dispose();
  }

  String _formattaData(DateTime? data) {
    if (data == null) return 'Nessuna data impostata';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Future<void> _selezionaData() async {
    final DateTime? scelta = await showDatePicker(
      context: context,
      initialDate: _dataNascitaSelezionata ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
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

    if (scelta != null && scelta != _dataNascitaSelezionata) {
      setState(() => _dataNascitaSelezionata = scelta);
    }
  }

  Future<void> _salvaDati() async {
    FocusScope.of(context).unfocus();
    LoadingOverlay.show(context, testo: "Salvataggio in corso...");

    try {
      await ref
          .read(profiloControllerProvider)
          .aggiornaDatiProfilo(
            idUtente: widget.utente.id,
            nome: _nomeController.text.trim(),
            cognome: _cognomeController.text.trim(),
            telefono: _telefonoController.text.trim(),
            dataNascita: _dataNascitaSelezionata!,
            nuovaPassword: _passwordController.text.trim(),
          );

      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profilo aggiornato con successo!',
              style: TextStyle(
                color: AppTheme.darkBg,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppTheme.statoSuccesso,
          ),
        );
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        String msgErrore = e.message;
        if (msgErrore.toLowerCase().contains('different') ||
            msgErrore.toLowerCase().contains('same')) {
          msgErrore =
              "La nuova password deve essere diversa da quella attuale.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msgErrore),
            backgroundColor: AppTheme.statoErrore,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio'),
            backgroundColor: AppTheme.statoErrore,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ACCOUNT E SICUREZZA',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        leading: const FrecciaBack(
          coloriGradiente: [AppTheme.accent, AppTheme.accent],
        ),
      ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    NeonFormField(
                      initialValue: widget.utente.email,
                      readOnly: true,
                      label: 'Email (Non modificabile)',
                      icon: Icons.email,
                      coloreTema: AppTheme.textDisabled,
                      autovalidateMode: AutovalidateMode.onUnfocus,
                    ),
                    const SizedBox(height: 24),

                    NeonFormField(
                      controller: _nomeController,
                      label: 'Nome',
                      icon: Icons.person_outline,
                      coloreTema: AppTheme.accent,
                      validator: (val) => _validaMinLunghezza(val, 'nome'),
                      autovalidateMode: AutovalidateMode.onUnfocus,
                    ),
                    const SizedBox(height: 24),
                    NeonFormField(
                      controller: _cognomeController,
                      label: 'Cognome',
                      icon: Icons.badge_outlined,
                      coloreTema: AppTheme.accent,
                      validator: (val) => _validaMinLunghezza(val, 'cognome'),
                      autovalidateMode: AutovalidateMode.onUnfocus,
                    ),
                    const SizedBox(height: 24),

                    InputDecorator(
                      decoration: AppStyles.capsuleDecoration(
                        'Data di Nascita',
                        Icons.calendar_today_rounded,
                        coloreTema: AppTheme.textDisabled,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formattaData(_dataNascitaSelezionata),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: AppTheme.textDisabled,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    NeonFormField(
                      controller: _telefonoController,
                      label: 'Telefono (Opzionale)',
                      icon: Icons.phone,
                      coloreTema: AppTheme.accent,
                      keyboardType: TextInputType.phone,
                      validator: AppValidators.validaTelefonoOpzionale,
                      autovalidateMode: AutovalidateMode.onUnfocus,
                    ),
                    const SizedBox(height: 32),

                    const Divider(color: AppTheme.cardBorder),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SICUREZZA',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    NeonFormField(
                      controller: _passwordController,
                      label: 'Nuova Password',
                      hintText: 'Lascia vuoto per non cambiare',
                      icon: Icons.lock_outline_rounded,
                      coloreTema: AppTheme.accent,
                      obscureText: _nascondiPassword,
                      validator: AppValidators.validaPasswordOpzionale,
                      autovalidateMode: AutovalidateMode.onUnfocus,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _nascondiPassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => setState(
                          () => _nascondiPassword = !_nascondiPassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    NeonFormField(
                      controller: _confermaPasswordController,
                      label: 'Conferma Nuova Password',
                      hintText: 'Ripeti la nuova password',
                      icon: Icons.lock_rounded,
                      coloreTema: AppTheme.accent,
                      obscureText: _nascondiConfermaPassword,
                      autovalidateMode: AutovalidateMode.onUnfocus,
                      validator: (val) {
                        if (_passwordController.text.isNotEmpty) {
                          if (val == null || val.isEmpty) {
                            return 'Conferma la password';
                          }
                          if (val != _passwordController.text) {
                            return 'Le password non coincidono';
                          }
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _nascondiConfermaPassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => setState(
                          () => _nascondiConfermaPassword =
                              !_nascondiConfermaPassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _salvaDati,
                        child: const Text(
                          'SALVA MODIFICHE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: AppTheme.cardBorder),
                    const SizedBox(height: 16),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ZONA PERICOLO',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Eliminando l’account perderai definitivamente il profilo, '
                      'le preferenze, le partecipazioni e gli altri dati associati. '
                      'L’operazione non può essere annullata.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 18),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _eliminaAccount(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.delete_forever, size: 22),
                        label: const Text(
                          'ELIMINA ACCOUNT',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validaMinLunghezza(String? val, String campo) {
    if (val == null || val.trim().isEmpty) return 'Il $campo è obbligatorio';
    if (val.trim().length < 3) return 'Inserisci almeno 3 lettere';
    return null;
  }

  Future<void> _eliminaAccount(BuildContext context, WidgetRef ref) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        title: const Text(
          'Elimina Account',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Sei sicuro di voler eliminare definitivamente il tuo account?\n\n'
          'Verranno rimossi il profilo, le preferenze, le partecipazioni '
          'alle partite, le notifiche e gli altri dati associati, salvo '
          'eventuali dati che devono essere conservati per obblighi di legge.\n\n'
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
              'Elimina',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (conferma != true) return;

    try {
      await PushNotificationService.rimuoviTokenCorrente();

      await Supabase.instance.client.functions.invoke('elimina-utente');

      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
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
