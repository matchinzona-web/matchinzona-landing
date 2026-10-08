import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    // ---------------------------------------------------------
    // 1. VERIFICA UTENTE AUTENTICATO
    // ---------------------------------------------------------

    const authorization = req.headers.get("Authorization");

    if (!authorization) {
      return new Response(
        JSON.stringify({
          error: "Utente non autenticato",
        }),
        {
          status: 401,
          headers: corsHeaders,
        },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: {
            Authorization: authorization,
          },
        },
      },
    );

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({
          error: "Sessione utente non valida",
        }),
        {
          status: 401,
          headers: corsHeaders,
        },
      );
    }

    // ---------------------------------------------------------
    // 2. SESSION ID
    // ---------------------------------------------------------

    const { session_id } = await req.json();

    if (!session_id) {
      return new Response(
        JSON.stringify({
          error: "session_id mancante",
        }),
        {
          status: 400,
          headers: corsHeaders,
        },
      );
    }

    // ---------------------------------------------------------
    // 3. RECUPERO CHECKOUT STRIPE
    // ---------------------------------------------------------

    const session = await stripe.checkout.sessions.retrieve(session_id);

    // La Checkout Session deve appartenere
    // all'utente attualmente autenticato.
    if (session.client_reference_id !== user.id) {
      return new Response(
        JSON.stringify({
          error: "Checkout non autorizzato",
        }),
        {
          status: 403,
          headers: corsHeaders,
        },
      );
    }

    const idSocieta = session.metadata?.id_societa ?? null;

    const idUtenteMetadata = session.metadata?.id_utente ?? null;

    const pianoMetadata = session.metadata?.piano ?? null;

    if (!idSocieta) {
      return new Response(
        JSON.stringify({
          error: "Società non associata al checkout",
        }),
        {
          status: 400,
          headers: corsHeaders,
        },
      );
    }

    if (idUtenteMetadata && idUtenteMetadata !== user.id) {
      return new Response(
        JSON.stringify({
          error: "Checkout non autorizzato",
        }),
        {
          status: 403,
          headers: corsHeaders,
        },
      );
    }

    // ---------------------------------------------------------
    // 4. VERIFICA PAGAMENTO
    // ---------------------------------------------------------

    const sessionStatus = session.status ?? null;

    const paymentStatus = session.payment_status ?? null;

    const completata =
      sessionStatus === "complete" &&
      (paymentStatus === "paid" || paymentStatus === "no_payment_required");

    if (!completata) {
      return new Response(
        JSON.stringify({
          completed: false,
          session_status: sessionStatus,
          payment_status: paymentStatus,
        }),
        {
          status: 200,
          headers: corsHeaders,
        },
      );
    }

    // ---------------------------------------------------------
    // 5. VERIFICA SUBSCRIPTION
    // ---------------------------------------------------------

    if (!session.subscription) {
      return new Response(
        JSON.stringify({
          completed: false,
          session_status: sessionStatus,
          payment_status: paymentStatus,
          error: "Subscription non ancora disponibile.",
        }),
        {
          status: 200,
          headers: corsHeaders,
        },
      );
    }

    const subscription = await stripe.subscriptions.retrieve(
      session.subscription as string,
    );

    const priceId = subscription.items.data[0]?.price.id;

    if (!priceId) {
      return new Response(
        JSON.stringify({
          error: "Price ID non trovato nella subscription.",
        }),
        {
          status: 500,
          headers: corsHeaders,
        },
      );
    }

    // ---------------------------------------------------------
    // 6. RISPOSTA
    // ---------------------------------------------------------

    const customerId =
      typeof session.customer === "string"
        ? session.customer
        : (session.customer?.id ?? null);

    return new Response(
      JSON.stringify({
        completed: true,
        session_status: sessionStatus,
        payment_status: paymentStatus,

        id_societa: idSocieta,
        piano: pianoMetadata,

        stripe_customer_id: customerId,
        price_id: priceId,
      }),
      {
        status: 200,
        headers: corsHeaders,
      },
    );
  } catch (error) {
    console.error("ottieni-dati-sessione:", error);

    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Errore sconosciuto",
      }),
      {
        status: 500,
        headers: corsHeaders,
      },
    );
  }
});
