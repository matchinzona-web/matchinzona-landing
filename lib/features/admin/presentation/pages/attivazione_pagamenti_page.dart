import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/admin/presentation/pages/configurazione_orari.dart';

class AttivazionePagamentiPage extends StatefulWidget {
  final String idSocieta;

  const AttivazionePagamentiPage({super.key, required this.idSocieta});

  @override
  State<AttivazionePagamentiPage> createState() =>
      _AttivazionePagamentiPageState();
}

class _AttivazionePagamentiPageState extends State<AttivazionePagamentiPage> {
  bool _isLoading = false;
  bool _isChecking = false;

  Future<void> _avviaOnboardingStripe() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('Avvio Stripe Connect per società: ${widget.idSocieta}');
      debugPrint('========================================');
      debugPrint('STRIPE CONNECT');
      debugPrint('idSocieta: "${widget.idSocieta}"');
      debugPrint('tipo idSocieta: ${widget.idSocieta.runtimeType}');
      debugPrint('========================================');
      final response = await Supabase.instance.client.functions.invoke(
        'crea-account-connect',
        body: {'id_societa': widget.idSocieta},
      );

      if (response.status != 200 || response.data == null) {
        throw Exception(
          response.data?['error'] ?? 'Impossibile creare il link di pagamento',
        );
      }

      final String? url = response.data['url'];
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('URL di Stripe non valido');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verificaStatoConto() async {
    setState(() => _isChecking = true);

    try {
      // Chiama la nuova Edge Function che controlla Stripe in tempo reale
      final response = await Supabase.instance.client.functions.invoke(
        'verifica-account-connect',
      );

      final bool chargesEnabled = response.data?['charges_enabled'] == true;

      if (!mounted) return;

      if (chargesEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conto Stripe attivato con successo!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ConfigurazioneOrari(idSocieta: widget.idSocieta),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Configurazione non ancora completata su Stripe. Clicca su Apri Portale per terminare.',
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore verifica: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: const Text(
          'Ricezione Pagamenti',
          style: TextStyle(
            color: AppTheme.neonOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.neonOrange, width: 2),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    size: 60,
                    color: AppTheme.neonOrange,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Collega il tuo Conto Bancario',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Per ricevere gli accrediti diretti dei pagamenti delle partite tramite Stripe, inserisci l\'IBAN e i dati aziendali sul portale sicuro Stripe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Bottone avvia Stripe
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _avviaOnboardingStripe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonOrange,
                      foregroundColor: AppTheme.darkBg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.darkBg,
                            ),
                          )
                        : const Icon(Icons.open_in_new),
                    label: Text(
                      _isLoading
                          ? 'Caricamento...'
                          : 'Apri Portale Stripe Connect',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bottone verifica stato
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isChecking ? null : _verificaStatoConto,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isChecking
                          ? 'Verifica in corso...'
                          : 'Ho completato la configurazione',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
