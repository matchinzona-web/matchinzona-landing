import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/admin/config/piani_config.dart';

class PagamentoAbbonamentoPage extends StatefulWidget {
  final String idSocieta;
  final String pianoScelto;

  const PagamentoAbbonamentoPage({
    super.key,
    required this.idSocieta,
    required this.pianoScelto,
  });

  @override
  State<PagamentoAbbonamentoPage> createState() =>
      _PagamentoAbbonamentoPageState();
}

class _PagamentoAbbonamentoPageState extends State<PagamentoAbbonamentoPage> {
  bool _isLoading = false;

  Map<String, dynamic>? get _piano {
    for (final piano in PianiConfig.piani) {
      if (piano['nome'].toString().toUpperCase() ==
          widget.pianoScelto.toUpperCase()) {
        return piano;
      }
    }

    return null;
  }

  Future<void> _avviaPagamento() async {
    if (_isLoading) return;

    final piano = _piano;

    if (piano == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Piano selezionato non valido.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessione utente non disponibile.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'crea-checkout-session',
        body: {'piano': piano['nome'], 'idSocieta': widget.idSocieta},
      );

      if (!mounted) return;

      final data = response.data;

      if (data == null) {
        throw Exception('Risposta Stripe non valida.');
      }

      final String? url = data['url'] as String?;
      final String? sessionId = data['session_id'] as String?;

      if (url == null || url.isEmpty) {
        throw Exception('URL Stripe non disponibile.');
      }

      if (sessionId == null || sessionId.isEmpty) {
        throw Exception('Sessione Stripe non disponibile.');
      }

      final uri = Uri.tryParse(url);

      if (uri == null) {
        throw Exception('URL Stripe non valido.');
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('stripe_checkout_session_pending', sessionId);

      await prefs.setString(
        'stripe_checkout_piano_pending',
        piano['nome'].toString(),
      );

      final aperto = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!aperto) {
        throw Exception('Impossibile aprire Stripe.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore avvio pagamento'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final piano = _piano;

    if (piano == null) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: Text(
            'Piano non disponibile.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Attiva MatchInZona',
          style: TextStyle(
            color: AppTheme.neonOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.neonOrange,
                    size: 70,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Completa l’attivazione',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Il tuo centro è stato creato. Completa il pagamento '
                    'per attivare il tuo piano MatchInZona.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppTheme.neonOrange.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          piano['titolo'].toString(),
                          style: const TextStyle(
                            color: AppTheme.neonOrange,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                '€',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              piano['prezzo'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),

                        Text(
                          '/ mese + IVA',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          piano['limiti'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _avviaPagamento,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonOrange,
                        foregroundColor: AppTheme.darkBg,
                        disabledBackgroundColor: AppTheme.neonOrange.withValues(
                          alpha: 0.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.darkBg,
                              ),
                            )
                          : const Text(
                              'Procedi al pagamento',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Pagamento sicuro gestito da Stripe.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
