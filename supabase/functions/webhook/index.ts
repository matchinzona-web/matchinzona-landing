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
    case "price_1UVEqiFxZCOuiQIACGeAoiMk":
      return { nome: "BASE", limite: 2 };

    case "price_1UVEs8FxZCOuiQIAYycswuuo":
      return { nome: "PRO", limite: 5 };

    case "price_1UVEslFxZCOuiQIAbjIY8noU":
      return { nome: "BUSINESS", limite: 999 };

    default:
      return { nome: "NESSUNO", limite: 0 };
  }
}

// Aggiorna la società e lancia un errore se la scrittura fallisce
// o se non trova nessuna riga, così Stripe riprova l'evento.
async function aggiornaSocieta(
  client: any,
  colonnaChiave: "id_utente" | "stripe_customer_id" | "stripe_account_id",
  valoreChiave: string,
  dati: Record<string, unknown>,
) {
  const { data, error } = await client
    .from("societa")
    .update(dati)
    .eq(colonnaChiave, valoreChiave)
    .select("id");

  if (error) {
    throw new Error(`Update societa fallito: ${error.message}`);
  }
  if (!data || data.length === 0) {
    throw new Error(
      `Nessuna societa trovata per ${colonnaChiave} = ${valoreChiave}`,
    );
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

      if (specifiche.nome === "NESSUNO") {
        throw new Error(`Price sconosciuto nel checkout: ${priceId}`);
      }

      await aggiornaSocieta(
        supabaseClient,
        "id_utente",
        session.client_reference_id as string,
        {
          piano_attuale: specifiche.nome,
          limite_campi: specifiche.limite,
          stripe_customer_id: session.customer,
          status_abbonamento: "active",

          // La prova gratuita manuale termina definitivamente
          // nel momento in cui viene acquistato un abbonamento Stripe.
          prova_inizio: null,
          prova_fine: null,
        },
      );
    }

    // ==========================================================
    // 2. CAMBIO PIANO (Upgrade o Downgrade dal Portale Stripe)
    // ==========================================================
    if (event.type === "customer.subscription.updated") {
      const subscription = event.data.object;
      const customerId =
        typeof subscription.customer === "string"
          ? subscription.customer
          : subscription.customer?.id;
      const priceId = subscription.items.data[0]?.price?.id;
      const specifiche = ottieniSpecifichePiano(priceId ?? "");

      if (!customerId) {
        throw new Error("subscription.updated senza customer");
      }

      if (
        subscription.status === "active" ||
        subscription.status === "trialing"
      ) {
        // Un prezzo sconosciuto non deve mai azzerare il piano di chi paga.
        if (specifiche.nome === "NESSUNO") {
          throw new Error(
            `Price sconosciuto in subscription.updated: ${priceId}`,
          );
        }

        await aggiornaSocieta(
          supabaseClient,
          "stripe_customer_id",
          customerId,
          {
            piano_attuale: specifiche.nome,
            limite_campi: specifiche.limite,
            status_abbonamento: "active",
          },
        );
      } else if (subscription.status === "past_due") {
        // Pagamento fallito: Stripe ritenta, il gestore mantiene piano e campi.
        await aggiornaSocieta(
          supabaseClient,
          "stripe_customer_id",
          customerId,
          {
            status_abbonamento: "payment_failed",
          },
        );
      } else if (
        subscription.status === "unpaid" ||
        subscription.status === "canceled" ||
        subscription.status === "incomplete_expired"
      ) {
        await aggiornaSocieta(
          supabaseClient,
          "stripe_customer_id",
          customerId,
          {
            piano_attuale: "NESSUNO",
            limite_campi: 0,
            status_abbonamento: "inactive",
          },
        );
      }
      // incomplete, paused: nessuna modifica.
    }

    // ==========================================================
    // 3. ANNULLAMENTO DEFINITIVO (Abbonamento scaduto o cancellato)
    // ==========================================================
    if (event.type === "customer.subscription.deleted") {
      const subscription = event.data.object;
      const customerId =
        typeof subscription.customer === "string"
          ? subscription.customer
          : subscription.customer?.id;

      if (!customerId) {
        throw new Error("subscription.deleted senza customer");
      }

      // Se il cliente ha ancora un altro abbonamento attivo, non azzeriamo nulla.
      const altre = await stripe.subscriptions.list({
        customer: customerId,
        status: "active",
        limit: 1,
      });

      if (altre.data.length === 0) {
        await aggiornaSocieta(
          supabaseClient,
          "stripe_customer_id",
          customerId,
          {
            piano_attuale: "NESSUNO",
            limite_campi: 0,
            status_abbonamento: "inactive",
          },
        );
      }
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

      const subscriptionId =
        typeof invoice.subscription === "string"
          ? invoice.subscription
          : invoice.subscription?.id;

      if (customerId && subscriptionId) {
        // Rileggiamo lo stato reale: un evento in ritardo non deve
        // riattivare un abbonamento nel frattempo annullato.
        const subscription =
          await stripe.subscriptions.retrieve(subscriptionId);

        if (
          subscription.status === "active" ||
          subscription.status === "trialing"
        ) {
          const priceId = subscription.items.data[0]?.price?.id ?? "";
          const specifiche = ottieniSpecifichePiano(priceId);

          if (specifiche.nome === "NESSUNO") {
            throw new Error(
              `Price sconosciuto in payment_succeeded: ${priceId}`,
            );
          }

          await aggiornaSocieta(
            supabaseClient,
            "stripe_customer_id",
            customerId,
            {
              piano_attuale: specifiche.nome,
              limite_campi: specifiche.limite,
              status_abbonamento: "active",
            },
          );
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

      const subscriptionId =
        typeof invoice.subscription === "string"
          ? invoice.subscription
          : invoice.subscription?.id;

      if (customerId && subscriptionId) {
        const subscription =
          await stripe.subscriptions.retrieve(subscriptionId);

        // Solo se è un rinnovo fallito su un abbonamento già esistente.
        if (subscription.status === "past_due") {
          await aggiornaSocieta(
            supabaseClient,
            "stripe_customer_id",
            customerId,
            { status_abbonamento: "payment_failed" },
          );
        }
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
