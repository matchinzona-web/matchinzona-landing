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

function separaIndirizzo(indirizzo: string | null) {
  if (!indirizzo) {
    return {
      line1: undefined,
      city: undefined,
      state: undefined,
    };
  }

  const parti = indirizzo
    .split(",")
    .map((p) => p.trim())
    .filter((p) => p.length > 0);

  return {
    line1: parti[0] || undefined,
    city: parti[1] || undefined,
    state: parti[2] || undefined,
  };
}

function separaNome(nomeCompleto: string | null) {
  const nome = (nomeCompleto ?? "").trim();

  if (!nome) {
    return {
      first_name: undefined,
      last_name: undefined,
    };
  }

  const parti = nome.split(/\s+/);

  if (parti.length === 1) {
    return {
      first_name: parti[0],
      last_name: undefined,
    };
  }

  return {
    first_name: parti[0],
    last_name: parti.slice(1).join(" "),
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    // ------------------------------------------------------------
    // 1. VERIFICA UTENTE AUTENTICATO
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

    const supabaseAuth = createClient(
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
    } = await supabaseAuth.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({
          error: "Utente non autorizzato",
        }),
        {
          status: 401,
          headers: corsHeaders,
        },
      );
    }

    // ------------------------------------------------------------
    // 2. LEGGE ID SOCIETÀ
    // ------------------------------------------------------------

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
          headers: corsHeaders,
        },
      );
    }

    // ------------------------------------------------------------
    // 3. CLIENT ADMIN
    // ------------------------------------------------------------

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // ------------------------------------------------------------
    // 4. RECUPERA LA SOCIETÀ DELL'UTENTE
    // ------------------------------------------------------------

    const { data: societa, error: dbError } = await supabaseAdmin
      .from("societa")
      .select(
        `
        id,
        id_utente,
        nome_societa,
        p_iva,
        indirizzo,
        nome_proprietario,
        telefono,
        cellulare,
        email,
        stripe_account_id
        `,
      )
      .eq("id", id_societa)
      .eq("id_utente", user.id)
      .single();

    if (dbError || !societa) {
      return new Response(
        JSON.stringify({
          error: "Società non trovata o non autorizzata",
        }),
        {
          status: 404,
          headers: corsHeaders,
        },
      );
    }

    // ------------------------------------------------------------
    // 5. SEPARA L'INDIRIZZO
    // ------------------------------------------------------------

    const indirizzo = separaIndirizzo(societa.indirizzo);

    // ------------------------------------------------------------
    // 6. SEPARA NOME E COGNOME DEL PROPRIETARIO
    // ------------------------------------------------------------

    const proprietario = separaNome(societa.nome_proprietario);

    const recapitoTelefonico =
      societa.cellulare || societa.telefono || undefined;

    // ------------------------------------------------------------
    // 7. CREA O RECUPERA ACCOUNT STRIPE
    // ------------------------------------------------------------

    let stripeAccountId = societa.stripe_account_id;

    if (!stripeAccountId) {
      const accountParams: Stripe.AccountCreateParams = {
        type: "express",
        country: "IT",

        email: societa.email || undefined,

        business_type: "company",

        company: {
          name: societa.nome_societa || undefined,

          tax_id: societa.p_iva || undefined,

          phone: recapitoTelefonico,

          address: {
            line1: indirizzo.line1,
            city: indirizzo.city,
            state: indirizzo.state,
            country: "IT",
          },
        },

        business_profile: {
          name: societa.nome_societa || undefined,
          mcc: "7997",
          support_email: societa.email || undefined,
          support_phone: recapitoTelefonico,
        },

        capabilities: {
          card_payments: {
            requested: true,
          },
          transfers: {
            requested: true,
          },
        },
      };

      const newAccount = await stripe.accounts.create(accountParams);

      stripeAccountId = newAccount.id;

      const { error: updateError } = await supabaseAdmin
        .from("societa")
        .update({
          stripe_account_id: stripeAccountId,
        })
        .eq("id", id_societa);

      if (updateError) {
        console.error("Errore salvataggio stripe_account_id:", updateError);
      }
    } else {
      // ----------------------------------------------------------
      // 8. ACCOUNT GIÀ ESISTENTE:
      //    aggiorniamo comunque l'indirizzo strutturato
      // ----------------------------------------------------------

      await stripe.accounts.update(stripeAccountId, {
        company: {
          name: societa.nome_societa || undefined,
          tax_id: societa.p_iva || undefined,
          phone: recapitoTelefonico,
          address: {
            line1: indirizzo.line1,
            city: indirizzo.city,
            state: indirizzo.state,
            country: "IT",
          },
        },
      });
    }

    // ------------------------------------------------------------
    // 9. CREA IL TITOLARE EFFETTIVO SE NON ESISTE GIÀ
    // ------------------------------------------------------------

    const persone = await stripe.accounts.listPersons(stripeAccountId, {
      limit: 100,
    });

    const esistePersona = persone.data.some((persona) => {
      return (
        persona.relationship?.owner === true ||
        persona.relationship?.representative === true
      );
    });

    if (!esistePersona && proprietario.first_name) {
      await stripe.accounts.createPerson(stripeAccountId, {
        first_name: proprietario.first_name,
        last_name: proprietario.last_name,

        email: societa.email || undefined,

        phone: recapitoTelefonico,

        relationship: {
          representative: true,
          owner: true,
          percent_ownership: 100,
        },
      });
    }

    // ------------------------------------------------------------
    // 10. CREA LINK ONBOARDING
    // ------------------------------------------------------------

    const accountLink = await stripe.accountLinks.create({
      account: stripeAccountId,

      refresh_url: "https://appcampi.com/reauth",

      return_url: "https://appcampi.com/return",

      type: "account_onboarding",
    });

    // ------------------------------------------------------------
    // 11. RISPOSTA
    // ------------------------------------------------------------

    return new Response(
      JSON.stringify({
        url: accountLink.url,
        stripe_account_id: stripeAccountId,
      }),
      {
        status: 200,
        headers: corsHeaders,
      },
    );
  } catch (error) {
    console.error("Errore crea-account-connect:", error);

    return new Response(
      JSON.stringify({
        error:
          error instanceof Error
            ? error.message
            : "Errore durante la creazione dell'account Stripe",
      }),
      {
        status: 500,
        headers: corsHeaders,
      },
    );
  }
});
