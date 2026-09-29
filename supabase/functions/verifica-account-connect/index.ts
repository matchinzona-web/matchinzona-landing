import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") as string, {
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
    // ------------------------------------------------------------
    // 1. AUTENTICAZIONE UTENTE
    // ------------------------------------------------------------

    const authorization = req.headers.get("Authorization");

    if (!authorization) {
      return new Response(
        JSON.stringify({
          error: "Token di autorizzazione mancante",
        }),
        {
          status: 401,
          headers: corsHeaders,
        },
      );
    }

    const supabaseClient = createClient(
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
    } = await supabaseClient.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({
          error: "Non autorizzato",
        }),
        {
          status: 401,
          headers: corsHeaders,
        },
      );
    }

    // ------------------------------------------------------------
    // 2. RECUPERO SOCIETÀ DELL'UTENTE
    // ------------------------------------------------------------

    const { data: societa, error: societaError } = await supabaseClient
      .from("societa")
      .select(
        "id, stripe_account_id, stripe_charges_enabled, stripe_payouts_enabled",
      )
      .eq("id_utente", user.id)
      .single();

    if (societaError || !societa) {
      return new Response(
        JSON.stringify({
          error: "Società non trovata",
        }),
        {
          status: 404,
          headers: corsHeaders,
        },
      );
    }

    // ------------------------------------------------------------
    // 3. ACCOUNT STRIPE NON ANCORA CREATO
    // ------------------------------------------------------------

    if (!societa.stripe_account_id) {
      return new Response(
        JSON.stringify({
          has_stripe_account: false,
          stripe_account_id: null,
          charges_enabled: false,
          payouts_enabled: false,
          details_submitted: false,
          is_fully_active: false,
          currently_due: [],
          eventually_due: [],
          past_due: [],
          disabled_reason: null,
        }),
        {
          status: 200,
          headers: corsHeaders,
        },
      );
    }

    // ------------------------------------------------------------
    // 4. RECUPERO STATO REALE DA STRIPE
    // ------------------------------------------------------------

    const account = await stripe.accounts.retrieve(societa.stripe_account_id);

    const chargesEnabled = account.charges_enabled === true;
    const payoutsEnabled = account.payouts_enabled === true;
    const detailsSubmitted = account.details_submitted === true;

    const currentlyDue = account.requirements?.currently_due ?? [];

    const eventuallyDue = account.requirements?.eventually_due ?? [];

    const pastDue = account.requirements?.past_due ?? [];

    const disabledReason = account.requirements?.disabled_reason ?? null;

    // Un account è realmente pronto per Matchly
    // quando può ricevere pagamenti e ricevere payout.
    const isFullyActive = chargesEnabled && payoutsEnabled;

    // ------------------------------------------------------------
    // 5. SINCRONIZZAZIONE CON SUPABASE
    // ------------------------------------------------------------

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { error: updateError } = await supabaseAdmin
      .from("societa")
      .update({
        stripe_charges_enabled: chargesEnabled,
        stripe_payouts_enabled: payoutsEnabled,
      })
      .eq("id", societa.id);

    if (updateError) {
      console.error(
        "Errore aggiornamento stato Stripe su Supabase:",
        updateError,
      );
    }

    // ------------------------------------------------------------
    // 6. RISPOSTA COMPLETA A FLUTTER
    // ------------------------------------------------------------

    return new Response(
      JSON.stringify({
        has_stripe_account: true,
        stripe_account_id: societa.stripe_account_id,

        charges_enabled: chargesEnabled,
        payouts_enabled: payoutsEnabled,
        details_submitted: detailsSubmitted,

        is_fully_active: isFullyActive,

        currently_due: currentlyDue,
        eventually_due: eventuallyDue,
        past_due: pastDue,

        disabled_reason: disabledReason,
      }),
      {
        status: 200,
        headers: corsHeaders,
      },
    );
  } catch (error) {
    console.error("Errore verifica-account-connect:", error);

    return new Response(
      JSON.stringify({
        error:
          error instanceof Error
            ? error.message
            : "Errore durante la verifica dell'account Stripe",
      }),
      {
        status: 500,
        headers: corsHeaders,
      },
    );
  }
});
