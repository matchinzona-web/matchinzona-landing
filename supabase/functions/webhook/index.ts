import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import Stripe from "https://esm.sh/stripe@13.6.0?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

function ottieniSpecifichePiano(priceId: string): {
  nome: string;
  limite: number;
} {
  switch (priceId) {
    case "price_1UGdGWFxZCOuiQIA42y8kWez":
      return { nome: "BASE", limite: 2 };

    case "price_1UGdHNFxZCOuiQIAbHY8idXK":
      return { nome: "PRO", limite: 5 };

    case "price_1UGdHzFxZCOuiQIARoCgLykS":
      return { nome: "BUSINESS", limite: 999 };

    default:
      return { nome: "NESSUNO", limite: 0 };
  }
}

serve(async (req) => {
  const signature = req.headers.get("Stripe-Signature")!;
  const body = await req.text();
  let event;

  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "",
    );
  } catch (err) {
    console.error(`Errore validazione Webhook: ${err.message}`);
    return new Response(`Webhook Error: ${err.message}`, { status: 400 });
  }

  const supabaseClient = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  console.log(`Evento Stripe intercettato: ${event.type}`);

  try {
    // ==========================================================
    // 1. PRIMO ACQUISTO (Checkout iniziale andato a buon fine)
    // ==========================================================
    if (event.type === "checkout.session.completed") {
      const session = event.data.object;

      const subscription = await stripe.subscriptions.retrieve(
        session.subscription as string,
      );
      const priceId = subscription.items.data[0].price.id;
      const specifiche = ottieniSpecifichePiano(priceId);

      await supabaseClient
        .from("societa")
        .update({
          piano_attuale: specifiche.nome,
          limite_campi: specifiche.limite,
          stripe_customer_id: session.customer,
          status_abbonamento: "active",

          // La prova gratuita manuale termina definitivamente
          // nel momento in cui viene acquistato un abbonamento Stripe.
          prova_inizio: null,
          prova_fine: null,
        })
        .eq("id_utente", session.client_reference_id);
    }

    // ==========================================================
    // 2. CAMBIO PIANO (Upgrade o Downgrade dal Portale Stripe)
    // ==========================================================
    if (event.type === "customer.subscription.updated") {
      const subscription = event.data.object;
      const priceId = subscription.items.data[0].price.id;
      const specifiche = ottieniSpecifichePiano(priceId);

      if (
        subscription.status === "active" ||
        subscription.status === "trialing"
      ) {
        await supabaseClient
          .from("societa")
          .update({
            piano_attuale: specifiche.nome,
            limite_campi: specifiche.limite,
            status_abbonamento: "active",
          })
          .eq("stripe_customer_id", subscription.customer);
      }
    }

    // ==========================================================
    // 3. ANNULLAMENTO DEFINITIVO (Abbonamento scaduto o cancellato)
    // ==========================================================
    if (event.type === "customer.subscription.deleted") {
      const subscription = event.data.object;

      await supabaseClient
        .from("societa")
        .update({
          piano_attuale: "NESSUNO",
          limite_campi: 0,
          status_abbonamento: "inactive",
        })
        .eq("stripe_customer_id", subscription.customer);
    }

    // ==========================================================
    // 4. RINNOVO ABBONAMENTO PAGATO CON SUCCESSO
    // ==========================================================
    if (event.type === "invoice.payment_succeeded") {
      const invoice = event.data.object;

      const customerId =
        typeof invoice.customer === "string"
          ? invoice.customer
          : invoice.customer?.id;

      if (customerId) {
        const subscriptionId =
          typeof invoice.subscription === "string"
            ? invoice.subscription
            : invoice.subscription?.id;

        if (subscriptionId) {
          const subscription =
            await stripe.subscriptions.retrieve(subscriptionId);

          const priceId = subscription.items.data[0]?.price?.id;

          if (priceId) {
            const specifiche = ottieniSpecifichePiano(priceId);

            if (specifiche.nome !== "NESSUNO") {
              await supabaseClient
                .from("societa")
                .update({
                  piano_attuale: specifiche.nome,
                  limite_campi: specifiche.limite,
                  status_abbonamento: "active",
                })
                .eq("stripe_customer_id", customerId);
            }
          }
        }
      }
    }

    // ==========================================================
    // 5. PAGAMENTO ABBONAMENTO FALLITO
    // ==========================================================
    if (event.type === "invoice.payment_failed") {
      const invoice = event.data.object;

      const customerId =
        typeof invoice.customer === "string"
          ? invoice.customer
          : invoice.customer?.id;

      if (customerId) {
        await supabaseClient
          .from("societa")
          .update({
            status_abbonamento: "payment_failed",
          })
          .eq("stripe_customer_id", customerId);
      }
    }

    // ==========================================================
    // 4. AGGIORNAMENTO STATO ONBOARDING STRIPE CONNECT (GESTORE)
    // ==========================================================
    if (event.type === "account.updated") {
      const account = event.data.object;
      const chargesEnabled = account.charges_enabled === true;
      const payoutsEnabled = account.payouts_enabled === true;

      console.log(
        `Account Connect ${account.id} aggiornato. Charges: ${chargesEnabled}, Payouts: ${payoutsEnabled}`,
      );

      await supabaseClient
        .from("societa")
        .update({
          stripe_charges_enabled: chargesEnabled,
          stripe_payouts_enabled: payoutsEnabled,
        })
        .eq("stripe_account_id", account.id);
    }
  } catch (error) {
    console.error(`Errore durante l'aggiornamento del DB Supabase:`, error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 });
});
