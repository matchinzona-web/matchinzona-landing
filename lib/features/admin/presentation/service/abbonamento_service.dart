import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AbbonamentoService {
  Future<void> apriPortaleStripe(
    BuildContext context,
    String stripeCustomerId,
  ) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'crea-portale-session',
        body: {'stripe_customer_id': stripeCustomerId},
      );

      final String? urlPortale = response.data['url'];

      if (urlPortale != null) {
        await launchUrl(
          Uri.parse(urlPortale),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Impossibile generare l\'URL del portale';
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore apertura portale'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> apriCheckout(
    BuildContext context, {
    required String idSocieta,
    required String piano,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      var session = supabase.auth.currentSession;

      if (session == null) {
        throw 'Sessione utente non disponibile. Effettua nuovamente l\'accesso.';
      }

      try {
        final refreshResponse = await supabase.auth.refreshSession();

        if (refreshResponse.session != null) {
          session = refreshResponse.session;
        }
      } catch (e) {
        debugPrint('Refresh session non riuscito: $e');
      }

      if (session == null) {
        throw 'Sessione utente non valida.';
      }

      debugPrint('Apertura checkout Stripe...');
      debugPrint('Società: $idSocieta');
      debugPrint('Piano: $piano');

      final response = await supabase.functions.invoke(
        'crea-checkout-session',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'idSocieta': idSocieta, 'piano': piano},
      );

      debugPrint('Risposta checkout: ${response.data}');

      final String? url = response.data?['url']?.toString();
      final String? sessionId = response.data?['session_id']?.toString();

      if (url == null || url.isEmpty) {
        throw 'Impossibile generare URL checkout';
      }

      if (sessionId != null && sessionId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('stripe_checkout_session_pending', sessionId);

        await prefs.setString('stripe_checkout_piano_pending', piano);
      }

      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

      if (url == null || url.isEmpty) {
        throw 'Impossibile generare URL checkout';
      }

      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('ERRORE CHECKOUT STRIPE: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore apertura checkout'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
