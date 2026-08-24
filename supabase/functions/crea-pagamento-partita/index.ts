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
};

// PERCENTUALE E TARIFFA PIATTAFORMA
const FEE_PERCENTUALE = 0.035; // 3.5%
const FEE_FISSA_CENTESIMI = 35; // 0.35€

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      },
    );

    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Non autorizzato" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { id_campo, prezzo_base_euro } = await req.json();

    if (!id_campo || !prezzo_base_euro) {
      return new Response(JSON.stringify({ error: "Parametri mancanti" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Recupera l'account Stripe Connect della società proprietaria del campo
    const { data: campo, error: campoError } = await supabaseClient
      .from("campi")
      .select(
        "id, id_societa, societa:id_societa(stripe_account_id, stripe_charges_enabled, nome_societa)",
      )
      .eq("id", id_campo)
      .single();

    if (campoError || !campo || !campo.societa) {
      return new Response(
        JSON.stringify({ error: "Campo o società non trovata" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const stripeAccountId = campo.societa.stripe_account_id;
    const chargesEnabled = campo.societa.stripe_charges_enabled;

    if (!stripeAccountId || !chargesEnabled) {
      return new Response(
        JSON.stringify({
          error:
            "Il centro sportivo non ha ancora abilitato i pagamenti in app.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 2. Calcolo importi in centesimi
    const prezzoBaseCentesimi = Math.round(prezzo_base_euro * 100);
    const platformFee =
      Math.round(prezzoBaseCentesimi * FEE_PERCENTUALE) + FEE_FISSA_CENTESIMI;
    const totaleUtenteCentesimi = prezzoBaseCentesimi + platformFee;

    // 3. Crea il PaymentIntent verso il gestore trattenendo l'application_fee
    const paymentIntent = await stripe.paymentIntents.create({
      amount: totaleUtenteCentesimi,
      currency: "eur",
      payment_method_types: ["card"],
      application_fee_amount: platformFee,
      transfer_data: {
        destination: stripeAccountId,
      },
      metadata: {
        id_utente: user.id,
        id_campo: id_campo,
        id_societa: campo.id_societa,
      },
    });

    return new Response(
      JSON.stringify({
        paymentIntent: paymentIntent.client_secret,
        totaleEuro: (totaleUtenteCentesimi / 100).toFixed(2),
        feeEuro: (platformFee / 100).toFixed(2),
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
