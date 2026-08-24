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

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } },
    );

    let id_societa: string | null = null;

    try {
      const contentType = req.headers.get("content-type") ?? "";

      if (contentType.includes("application/json")) {
        const body = await req.json();
        id_societa = body?.id_societa ?? null;
      }
    } catch (e) {
      console.error("Errore lettura body:", e);
    }

    if (!id_societa) {
      return new Response(
        JSON.stringify({
          error: "ID Società mancante nel body della richiesta",
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    if (!id_societa) {
      return new Response(JSON.stringify({ error: "ID Società mancante" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Recupero di tutti i dati anagrafici già presenti nel database
    const { data: societa, error: dbError } = await supabaseClient
      .from("societa")
      .select(
        "id, nome_societa, p_iva, indirizzo, nome_proprietario, telefono, cellulare, email, stripe_account_id",
      )
      .eq("id", id_societa)
      .single();

    if (dbError || !societa) {
      return new Response(JSON.stringify({ error: "Società non trovata" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let stripeAccountId = societa.stripe_account_id;

    // 2. Se non ha ancora un account Stripe Connect, lo creiamo precompilato al 100%
    if (!stripeAccountId) {
      // Parsing nome e cognome proprietario

      const recapitoTelefonico =
        societa.cellulare || societa.telefono || undefined;

      const accountParams: Stripe.AccountCreateParams = {
        type: "express",
        country: "IT",
        email: societa.email || undefined,
        business_type: "company", // o 'individual' se ditta individuale
        company: {
          name: societa.nome_societa || undefined,
          tax_id: societa.p_iva || undefined,
          phone: recapitoTelefonico,
          address: {
            line1: societa.indirizzo || undefined,
            country: "IT",
          },
        },
        business_profile: {
          name: societa.nome_societa || undefined,
          mcc: "7997", // Clubs - Sports, Membership (centri sportivi)
          support_email: societa.email || undefined,
          support_phone: recapitoTelefonico,
        },
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
      };

      const newAccount = await stripe.accounts.create(accountParams);
      stripeAccountId = newAccount.id;

      // Salvataggio immediato dell'ID generato su Supabase
      await supabaseClient
        .from("societa")
        .update({ stripe_account_id: stripeAccountId })
        .eq("id", id_societa);
    }

    // 3. Generazione link di Onboarding
    const accountLink = await stripe.accountLinks.create({
      account: stripeAccountId,
      refresh_url: "https://appcampi.com/reauth",
      return_url: "https://appcampi.com/return",
      type: "account_onboarding",
    });

    return new Response(JSON.stringify({ url: accountLink.url }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
