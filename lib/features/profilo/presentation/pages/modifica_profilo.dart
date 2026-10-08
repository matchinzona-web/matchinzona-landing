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
  late Map<String, dynamic> _livelliSport;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.utente.nome);
    _cognomeController = TextEditingController(text: widget.utente.cognome);
    _telefonoController = TextEditingController(
      text: widget.utente.telefono ?? '',
    );
    _dataNascitaSelezionata = widget.utente.dataNascita;
    _livelliSport = Map<String, dynamic>.from(widget.utente.livelliSport ?? {});
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

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

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
            livelliSport: _livelliSport,
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
                      label: 'Telefono',
                      icon: Icons.phone,
                      coloreTema: AppTheme.accent,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        final telefono =
                            val?.replaceAll(RegExp(r'\s+'), '') ?? '';

                        if (telefono.isEmpty) {
                          return 'Il telefono è obbligatorio';
                        }

                        if (!RegExp(r'^\d{10}$').hasMatch(telefono)) {
                          return 'Inserisci un numero di 10 cifre';
                        }

                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUnfocus,
                    ),

                    const SizedBox(height: 32),

                    if (_livelliSport.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'LIVELLI SPORTIVI',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      ..._livelliSport.entries.map((entry) {
                        final sport = entry.key;
                        final livello = entry.value.toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _modificaLivelloSport(sport, livello),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.sports_rounded,
                                    color: AppTheme.accent,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _nomeSportProfilo(sport),
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          livello,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.edit_rounded,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),
                    ],

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

  String _nomeSportProfilo(String sport) {
    switch (sport.trim().toLowerCase()) {
      case 'calcio_5':
        return 'Calcio a 5';
      case 'calcio_6':
        return 'Calcio a 6';
      case 'calcio_7':
        return 'Calcio a 7';
      case 'calcio_8':
        return 'Calcio a 8';
      case 'calcio_11':
        return 'Calcio a 11';
      case 'calcio':
        return 'Calcio';
      case 'tennis':
        return 'Tennis';
      case 'tennis_singolo':
        return 'Tennis';
      case 'tennis_doppio':
        return 'Tennis';
      case 'padel':
        return 'Padel';
      case 'basket':
        return 'Basket';
      case 'volley':
      case 'pallavolo':
        return 'Pallavolo';
      default:
        return sport;
    }
  }

  Future<void> _modificaLivelloSport(
    String sport,
    String livelloAttuale,
  ) async {
    final livelliDisponibili = [
      {
        'titolo': 'Principiante',
        'descrizione': 'Ho appena iniziato o gioco molto raramente.',
      },
      {
        'titolo': 'Amatoriale',
        'descrizione': 'Conosco le regole base e gioco ogni tanto.',
      },
      {
        'titolo': 'Intermedio',
        'descrizione': 'Gioco con continuità e ho una buona visione di gioco.',
      },
      {
        'titolo': 'Avanzato',
        'descrizione': 'Ritmo alto, ottima tecnica e padronanza del gioco.',
      },
      {
        'titolo': 'Esperto / Agonista',
        'descrizione': 'Livello competitivo elevato o tesserato agonista.',
      },
    ];

    final livelloScelto = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sports_rounded,
                        color: AppTheme.accent,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Livello ${_nomeSportProfilo(sport)}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 2),

                          const Text(
                            'Seleziona il livello che ti rappresenta meglio.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: livelliDisponibili.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = livelliDisponibili[index];

                      final titolo = item['titolo']!;
                      final descrizione = item['descrizione']!;

                      final selezionato =
                          titolo.trim().toLowerCase() ==
                          livelloAttuale.trim().toLowerCase();

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(sheetContext, titolo);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selezionato
                                ? AppTheme.accent.withOpacity(0.10)
                                : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selezionato
                                  ? AppTheme.accent
                                  : Colors.white.withOpacity(0.08),
                              width: selezionato ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titolo,
                                      style: TextStyle(
                                        color: selezionato
                                            ? AppTheme.accent
                                            : AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(height: 3),

                                    Text(
                                      descrizione,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              Icon(
                                selezionato
                                    ? Icons.check_circle_rounded
                                    : Icons.chevron_right_rounded,
                                color: selezionato
                                    ? AppTheme.accent
                                    : AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (livelloScelto == null) return;

    setState(() {
      _livelliSport[sport] = livelloScelto;
    });
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
