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
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "", // Usa service role per aggiornare la partita
    );

    // 1. Verifica utente autenticato dal token inviato dal client
    const authHeader = req.headers.get("Authorization")!;
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Non autorizzato" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { id_partita } = await req.json();
    if (!id_partita) {
      return new Response(JSON.stringify({ error: "ID partita mancante" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Recupera la partita da rimborsare
    const { data: partita, error: pError } = await supabaseClient
      .from("partite")
      .select(
        "id, id_organizzatore, data_partita, orario_inizio, stato_partita, is_pagato, stripe_payment_intent_id, importo_rimborsabile_centesimi, is_rimborsata",
      )
      .eq("id", id_partita)
      .single();

    if (pError || !partita) {
      return new Response(JSON.stringify({ error: "Partita non trovata" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Solo l'organizzatore può annullare la partita
    if (partita.id_organizzatore !== user.id) {
      return new Response(
        JSON.stringify({
          error: "Solo l'organizzatore può richiedere il rimborso",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (partita.stato_partita === "annullata") {
      return new Response(
        JSON.stringify({ error: "La partita è già stata annullata" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 3. Controllo limite orario (es. 24 ore prima dell'inizio)
    const orarioParts = partita.orario_inizio.split(":");
    const dataInizio = new Date(partita.data_partita);
    dataInizio.setHours(
      parseInt(orarioParts[0], 10),
      parseInt(orarioParts[1], 10),
      0,
      0,
    );

    const now = new Date();
    const oreDiAnticipo =
      (dataInizio.getTime() - now.getTime()) / (1000 * 60 * 60);

    if (oreDiAnticipo < 24) {
      return new Response(
        JSON.stringify({
          error:
            "Non è possibile annullare e ottenere il rimborso a meno di 24 ore dall'inizio della partita.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 4. Esecuzione Rimborso Stripe (Se era stato pagato online)
    let refundId = null;
    if (
      partita.is_pagato &&
      partita.stripe_payment_intent_id &&
      !partita.is_rimborsata
    ) {
      // Rimborso PARZIALE: importo del campo (es. 6000 centesimi = 60€),
      // trattenendo la commissione della piattaforma.
      // reverse_transfer: true storna l'importo dal conto del circolo
      const refund = await stripe.refunds.create({
        payment_intent: partita.stripe_payment_intent_id,
        amount: partita.importo_rimborsabile_centesimi,
        reverse_transfer: true,
      });
      refundId = refund.id;
    }

    // 5. Aggiornamento stato partita su Supabase
    await supabaseClient
      .from("partite")
      .update({
        stato_partita: "annullata",
        is_rimborsata: partita.is_pagato ? true : false,
      })
      .eq("id", id_partita);

    // 6. Inserisci notifica per l'organizzatore
    const importoRim = partita.importo_rimborsabile_centesimi
      ? (partita.importo_rimborsabile_centesimi / 100).toFixed(2)
      : "0.00";

    await supabaseClient.from("notifiche").insert({
      id_utente: user.id,
      titolo: "Prenotazione Annullata e Rimborsata",
      messaggio: partita.is_pagato
        ? `La tua prenotazione è stata annullata. Ti sono stati riaccreditati ${importoRim}€ sulla carta usata per il pagamento.`
        : "La tua prenotazione al campo è stata annullata con successo.",
      created_at: new Date().toISOString(),
    });

    return new Response(
      JSON.stringify({
        success: true,
        refundId: refundId,
        messaggio: "Partita annullata e rimborso completato con successo.",
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
