import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import Stripe from "https://esm.sh/stripe@13.6.0?target=deno";

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

const PRICE_IDS: Record<string, string> = {
  BASE: "price_1UGdGWFxZCOuiQIA42y8kWez",
  PRO: "price_1UGdHNFxZCOuiQIAbHY8idXK",
  BUSINESS: "price_1UGdHzFxZCOuiQIARoCgLykS",
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

    const token = authorization.replace("Bearer ", "").trim();

    if (!token) {
      return new Response(
        JSON.stringify({
          error: "Token utente mancante",
        }),
        {
          status: 401,
          headers: corsHeaders,
        },
      );
    }

    const supabaseAuth = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    );

    const {
      data: { user },
      error: userError,
    } = await supabaseAuth.auth.getUser(token);

    if (userError || !user) {
      console.error("Errore autenticazione utente:", userError);

      return new Response(
        JSON.stringify({
          error: "Sessione utente non valida",
          dettaglio: userError?.message ?? null,
        }),
        {
          status: 401,
          headers: corsHeaders,
        },
      );
    }

    // ---------------------------------------------------------
    // 2. DATI RICEVUTI DALL'APP
    // ---------------------------------------------------------

    const body = await req.json();

    const idSocieta = body.idSocieta?.toString();
    const piano = body.piano?.toString().trim().toUpperCase();

    if (!idSocieta) {
      return new Response(
        JSON.stringify({
          error: "idSocieta mancante",
        }),
        {
          status: 400,
          headers: corsHeaders,
        },
      );
    }

    if (!piano || !PRICE_IDS[piano]) {
      return new Response(
        JSON.stringify({
          error: "Piano non valido",
        }),
        {
          status: 400,
          headers: corsHeaders,
        },
      );
    }

    const priceId = PRICE_IDS[piano];

    // ---------------------------------------------------------
    // 3. VERIFICA CHE LA SOCIETÀ APPARTENGA ALL'UTENTE
    // ---------------------------------------------------------

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: societa, error: societaError } = await supabaseAdmin
      .from("societa")
      .select(
        "id, id_utente, stripe_customer_id, piano_attuale, status_abbonamento",
      )
      .eq("id", idSocieta)
      .eq("id_utente", user.id)
      .maybeSingle();

    if (societaError) {
      console.error("Errore recupero società:", societaError);

      return new Response(
        JSON.stringify({
          error: "Errore verifica società",
        }),
        {
          status: 500,
          headers: corsHeaders,
        },
      );
    }

    if (!societa) {
      return new Response(
        JSON.stringify({
          error: "Società non trovata o non autorizzata",
        }),
        {
          status: 403,
          headers: corsHeaders,
        },
      );
    }

    // ---------------------------------------------------------
    // 4. CREA CHECKOUT STRIPE
    // ---------------------------------------------------------

    const sessionConfig: Stripe.Checkout.SessionCreateParams = {
      mode: "subscription",

      payment_method_types: ["card"],

      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],

      // Ora contiene DAVVERO l'ID dell'utente Matchly.
      client_reference_id: user.id,

      metadata: {
        id_societa: idSocieta,
        id_utente: user.id,
        piano: piano,
      },

      subscription_data: {
        metadata: {
          id_societa: idSocieta,
          id_utente: user.id,
          piano: piano,
        },
      },

      success_url:
        "myapp://abbonamento?session_id={CHECKOUT_SESSION_ID}&status=success",

      cancel_url: "myapp://abbonamento?status=cancel",
    };

    // Se questo gestore possiede già un Customer Stripe,
    // riutilizziamo quello.
    if (
      societa.stripe_customer_id &&
      societa.stripe_customer_id.toString().trim().isNotEmpty
    ) {
      sessionConfig.customer = societa.stripe_customer_id.toString();
    } else {
      sessionConfig.customer_email = user.email ?? undefined;
    }

    const session = await stripe.checkout.sessions.create(sessionConfig);

    if (!session.url) {
      throw new Error("Stripe non ha restituito l'URL del checkout");
    }

    return new Response(
      JSON.stringify({
        url: session.url,
        session_id: session.id,
      }),
      {
        status: 200,
        headers: corsHeaders,
      },
    );
  } catch (err) {
    console.error("crea-checkout-session:", err);

    const message = err instanceof Error ? err.message : "Errore sconosciuto";

    return new Response(
      JSON.stringify({
        error: message,
      }),
      {
        status: 500,
        headers: corsHeaders,
      },
    );
  }
});
