import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app_campi/core/theme/app_theme.dart';

class RichiediAccessoGestorePage extends StatefulWidget {
  final String pianoScelto;

  const RichiediAccessoGestorePage({super.key, required this.pianoScelto});

  @override
  State<RichiediAccessoGestorePage> createState() =>
      _RichiediAccessoGestorePageState();
}

class _RichiediAccessoGestorePageState
    extends State<RichiediAccessoGestorePage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _centroController = TextEditingController();
  final _cittaController = TextEditingController();

  bool _invioInCorso = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _centroController.dispose();
    _cittaController.dispose();
    super.dispose();
  }

  Future<void> _inviaRichiesta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _invioInCorso = true;
    });

    try {
      await Supabase.instance.client.from('richieste_accesso_gestore').insert({
        'nome_cognome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'nome_centro': _centroController.text.trim(),
        'citta': _cittaController.text.trim(),
        'piano_scelto': widget.pianoScelto,
      });

      try {
        await Supabase.instance.client.functions.invoke(
          'invia-richiesta-gestore',
          body: {
            'nome_cognome': _nomeController.text.trim(),
            'email': _emailController.text.trim(),
            'telefono': _telefonoController.text.trim(),
            'nome_centro': _centroController.text.trim(),
            'citta': _cittaController.text.trim(),
            'piano_scelto': widget.pianoScelto,
          },
        );
      } catch (e) {
        debugPrint('Errore invio email richiesta gestore: $e');
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Richiesta ricevuta',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Grazie! Abbiamo ricevuto la tua richiesta.\n\n'
              'Ti contatteremo al più presto all’indirizzo email indicato.',
              style: TextStyle(color: Colors.grey.shade300, height: 1.5),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Torna alla Home',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l’invio della richiesta')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _invioInCorso = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.neonOrange),
        title: const Text(
          'Richiedi accesso gestore',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.neonOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'FASE DI LANCIO',
                          style: TextStyle(
                            color: AppTheme.neonOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Prova Matchly gratuitamente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Compila il modulo per richiedere l’attivazione del profilo gestore. '
                        'Ti contatteremo per configurare il tuo centro sportivo su Matchly.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Soluzione selezionata: ${widget.pianoScelto}',
                        style: const TextStyle(
                          color: AppTheme.neonOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nomeController,
                          label: 'Nome e cognome referente',
                          icon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          isEmail: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _telefonoController,
                          label: 'Numero di telefono',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _centroController,
                          label: 'Nome centro / società',
                          icon: Icons.sports_soccer_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _cittaController,
                          label: 'Città',
                          icon: Icons.location_city_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _invioInCorso ? null : _inviaRichiesta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonOrange,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppTheme.neonOrange.withOpacity(
                      0.5,
                    ),
                    disabledForegroundColor: Colors.black54,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _invioInCorso
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Invia richiesta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'La richiesta non comporta alcun pagamento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppTheme.neonOrange),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.neonOrange, width: 1.5),
        ),
      ),
      validator: (value) {
        final testo = value?.trim() ?? '';

        if (testo.isEmpty) {
          return 'Campo obbligatorio';
        }

        if (isEmail) {
          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

          if (!emailRegex.hasMatch(testo)) {
            return 'Inserisci un indirizzo email valido';
          }
        }

        return null;
      },
    );
  }
}
