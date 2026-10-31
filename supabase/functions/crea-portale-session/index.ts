import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@12.0.0?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
  httpClient: Stripe.createFetchHttpClient(),
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Gestione preflight CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Utente loggato
    const token = req.headers
      .get("Authorization")
      ?.replace("Bearer ", "")
      .trim();
    if (!token) {
      return new Response(JSON.stringify({ error: "Utente non autenticato" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
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
      return new Response(JSON.stringify({ error: "Sessione non valida" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Il customer si ricava dal database, non dal client
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );
    const { data: societa, error: societaError } = await supabaseAdmin
      .from("societa")
      .select("stripe_customer_id")
      .eq("id_utente", user.id)
      .maybeSingle();

    if (societaError || !societa?.stripe_customer_id) {
      return new Response(
        JSON.stringify({ error: "Nessun abbonamento Stripe associato" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 3. Origine di ritorno (solo tra quelle consentite)
    const body = await req.json().catch(() => ({}));
    const ORIGINI_CONSENTITE = [
      "https://matchinzona.it",
      "http://localhost:3000",
    ];
    const origineRichiesta = body.origin?.toString();
    const origine =
      origineRichiesta && ORIGINI_CONSENTITE.includes(origineRichiesta)
        ? origineRichiesta
        : "https://matchinzona.it";

    const session = await stripe.billingPortal.sessions.create({
      customer: societa.stripe_customer_id,
      return_url: `${origine}/?portale=chiuso`,
    });

    return new Response(JSON.stringify({ url: session.url }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
