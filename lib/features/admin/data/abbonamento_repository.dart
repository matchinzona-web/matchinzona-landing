import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
    required String priceId,
    required String piano,
    String? customerId,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'crea-checkout-session',
        body: {'priceId': priceId, 'piano': piano, 'customerId': ?customerId},
      );

      final String? url = response.data['url'];

      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossibile generare URL checkout';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore apertura checkout'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
