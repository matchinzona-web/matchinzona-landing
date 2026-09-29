import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@13.6.0?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
});

serve(async (req) => {
  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Non autorizzato" }), {
        status: 401,
      });
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const {
      data: { user },
    } = await supabaseClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Utente non trovato" }), {
        status: 401,
      });
    }

    // 1. Recupera la società collegata a questo utente
    const { data: societa, error: societaError } = await supabaseAdmin
      .from("societa")
      .select("id, stripe_customer_id, stripe_account_id")
      .eq("id_utente", user.id)
      .maybeSingle();

    if (societaError) {
      return new Response(JSON.stringify({ error: societaError.message }), {
        status: 500,
      });
    }

    // 2. Se ha un abbonamento Stripe attivo, cancella tutto su Stripe
    if (societa?.stripe_customer_id) {
      try {
        const subscriptions = await stripe.subscriptions.list({
          customer: societa.stripe_customer_id,
          status: "active",
        });
        for (const sub of subscriptions.data) {
          await stripe.subscriptions.cancel(sub.id);
        }
        await stripe.customers.del(societa.stripe_customer_id);
      } catch (stripeErr) {
        console.error("Errore Stripe:", stripeErr);
        // Non blocchiamo l'eliminazione se Stripe fallisce (es. customer già cancellato)
      }
    }

    // 2b. Se esiste un account Stripe Connect Express,
    // prova a eliminarlo/disconnetterlo dalla piattaforma.
    if (societa?.stripe_account_id) {
      try {
        await stripe.accounts.del(societa.stripe_account_id);
      } catch (stripeConnectErr) {
        console.error("Errore eliminazione Stripe Connect:", stripeConnectErr);

        // Non blocchiamo l'eliminazione Matchly:
        // l'account può avere vincoli Stripe, saldo,
        // payout pendenti o essere già stato rimosso.
      }
    }

    // 3. Se esiste una società, elimina tutti i dati collegati (campi, partite, orari, ecc.)
    if (societa) {
      const { error: cleanupSocietaError } = await supabaseAdmin.rpc(
        "elimina_dati_societa",
        {
          p_id_societa: societa.id,
        },
      );
      if (cleanupSocietaError) {
        return new Response(
          JSON.stringify({ error: cleanupSocietaError.message }),
          { status: 500 },
        );
      }
    }

    // 4. Pulisce anche i dati da "utente giocatore" (partite giocate, preferiti, notifiche)
    const { error: cleanupUtenteError } = await supabaseAdmin.rpc(
      "elimina_dati_gestore",
      {
        p_id_utente: user.id,
      },
    );
    if (cleanupUtenteError) {
      return new Response(
        JSON.stringify({ error: cleanupUtenteError.message }),
        { status: 500 },
      );
    }

    // 5. Elimina l'utente da auth.users (CASCADE elimina la riga 'utenti')
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
      user.id,
    );
    if (deleteError) {
      return new Response(JSON.stringify({ error: deleteError.message }), {
        status: 500,
      });
    }

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
});
