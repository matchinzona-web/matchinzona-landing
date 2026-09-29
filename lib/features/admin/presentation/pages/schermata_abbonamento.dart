import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/admin/application/abbonamento_provider.dart';
import 'package:app_campi/features/admin/presentation/service/abbonamento_service.dart';
import 'package:app_campi/features/admin/config/piani_config.dart';

class SchermataAbbonamento extends ConsumerStatefulWidget {
  final String idSocieta;
  const SchermataAbbonamento({super.key, required this.idSocieta});

  @override
  ConsumerState<SchermataAbbonamento> createState() =>
      _SchermataAbbonamentoState();
}

class _SchermataAbbonamentoState extends ConsumerState<SchermataAbbonamento> {
  bool _stoAggiornandoDopoStripe = false;
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (!mounted) return;

      await _ricaricaAbbonamento();
    });
  }

  void _mostraDialogSceltaPiano(String? stripeCustomerId) {
    final pageContext = context;
    final piani = PianiConfig.piani;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.neonOrange, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Scegli un Piano',
          style: TextStyle(
            color: AppTheme.neonOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: piani
              .map(
                (piano) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(dialogContext);

                      Future.microtask(() {
                        if (!mounted) return;

                        AbbonamentoService().apriCheckout(
                          pageContext,
                          idSocieta: widget.idSocieta,
                          piano: piano['nome']!,
                        );
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                piano['nome']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                piano['limiti']!,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            piano['prezzo']!,
                            style: const TextStyle(
                              color: AppTheme.neonOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(abbonamentoProvider);

    if (_stoAggiornandoDopoStripe) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.neonOrange),
              SizedBox(height: 16),
              Text(
                'Aggiornamento abbonamento in corso...',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: const Text(
          'Gestione Abbonamento',
          style: TextStyle(
            color: AppTheme.neonOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.neonOrange),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonOrange),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppTheme.neonOrange,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PIANO ATTUALE',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          state.piano.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.grey, height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Campi Utilizzati:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${state.campiInseriti} / ${state.limite}',
                              style: const TextStyle(
                                color: AppTheme.neonOrange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: state.limite > 0
                              ? state.campiInseriti / state.limite
                              : 0,
                          backgroundColor: Colors.grey.shade800,
                          color: AppTheme.neonOrange,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    state.stripeCustomerId == null ||
                            state.stripeCustomerId!.isEmpty
                        ? 'Attiva il tuo abbonamento'
                        : state.piano == 'NESSUNO'
                        ? 'Nessun abbonamento attivo'
                        : 'Modifica o Rinnova',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.stripeCustomerId == null ||
                            state.stripeCustomerId!.isEmpty
                        ? 'Stai utilizzando Matchly con un accesso gratuito. '
                              'Puoi attivare in qualsiasi momento un abbonamento per continuare '
                              'a utilizzare il servizio anche dopo la fine del periodo gratuito.'
                        : state.piano == 'NESSUNO'
                        ? 'Il tuo abbonamento è scaduto o è stato annullato. '
                              'Acquista un nuovo piano per continuare a gestire i tuoi campi.'
                        : 'Vuoi fare l\'upgrade, cambiare metodo di pagamento o scaricare '
                              'le fatture? Premi il pulsante sotto per accedere al portale Stripe.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonOrange,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        final bool haStripeCustomer =
                            state.stripeCustomerId != null &&
                            state.stripeCustomerId!.trim().isNotEmpty;

                        // CASO 1:
                        // Prova gratuita manuale oppure nessun abbonamento Stripe.
                        // Non avendo ancora un Customer Stripe, permettiamo
                        // l'acquisto di un vero abbonamento.
                        if (!haStripeCustomer) {
                          _mostraDialogSceltaPiano(null);
                          return;
                        }

                        // CASO 2:
                        // Ha già avuto Stripe, ma al momento non ha un piano attivo.
                        // Può acquistare nuovamente un piano riutilizzando
                        // il Customer Stripe esistente.
                        if (state.piano == 'NESSUNO') {
                          _mostraDialogSceltaPiano(state.stripeCustomerId);
                          return;
                        }

                        // CASO 3:
                        // Abbonamento Stripe attivo.
                        // Può modificare/cancellare/gestire dal portale Stripe.
                        AbbonamentoService().apriPortaleStripe(
                          context,
                          state.stripeCustomerId!,
                        );
                      },
                      icon: Icon(
                        state.stripeCustomerId == null ||
                                state.stripeCustomerId!.isEmpty ||
                                state.piano == 'NESSUNO'
                            ? Icons.shopping_cart
                            : Icons.open_in_new,
                        size: 20,
                      ),
                      label: Text(
                        state.stripeCustomerId == null ||
                                state.stripeCustomerId!.isEmpty ||
                                state.piano == 'NESSUNO'
                            ? 'Attiva Abbonamento'
                            : 'Apri Portale Clienti Stripe',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
    );
  }

  Future<void> _ricaricaAbbonamento() async {
    // Piccola attesa per dare tempo al webhook Stripe
    // di aggiornare la società su Supabase.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    await ref.read(abbonamentoProvider.notifier).caricaDati(widget.idSocieta);
  }
}
