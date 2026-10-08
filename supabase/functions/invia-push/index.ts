import { createClient } from "npm:@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "npm:jose@5";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;

const FIREBASE_CLIENT_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL")!;

const FIREBASE_PRIVATE_KEY = Deno.env
  .get("FIREBASE_PRIVATE_KEY")!
  .replace(/\\n/g, "\n");

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function getGoogleAccessToken(): Promise<string> {
  const privateKey = await importPKCS8(FIREBASE_PRIVATE_KEY, "RS256");

  const now = Math.floor(Date.now() / 1000);

  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({
      alg: "RS256",
      typ: "JWT",
    })
    .setIssuer(FIREBASE_CLIENT_EMAIL)
    .setSubject(FIREBASE_CLIENT_EMAIL)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await response.json();

  if (!response.ok || !data.access_token) {
    throw new Error(`Errore token Google: ${JSON.stringify(data)}`);
  }

  return data.access_token;
}

Deno.serve(async (req) => {
  try {
    const payload = await req.json();

    const record = payload.record;

    if (!record) {
      return new Response(
        JSON.stringify({
          error: "Record notifica mancante",
        }),
        {
          status: 400,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    const idUtente = record.id_utente;
    const titolo = record.titolo ?? "MatchInZona";
    const messaggio = record.messaggio ?? "Hai una nuova notifica.";
    const tipo = record.tipo ?? "notifica";
    const idPartita = record.id_partita ?? "";

    if (!idUtente) {
      return new Response(
        JSON.stringify({
          error: "id_utente mancante",
        }),
        {
          status: 400,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    const { data: tokens, error: tokenError } = await supabase
      .from("push_tokens")
      .select("token")
      .eq("id_utente", idUtente);

    if (tokenError) {
      throw tokenError;
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "Nessun token registrato",
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    const accessToken = await getGoogleAccessToken();

    const risultati = [];

    for (const item of tokens) {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: item.token,

              notification: {
                title: titolo,
                body: messaggio,
              },

              data: {
                tipo: String(tipo),
                notifica_id: String(record.id ?? ""),
                id_partita: String(idPartita),
              },

              android: {
                priority: "high",
                notification: {
                  sound: "default",
                },
              },

              apns: {
                payload: {
                  aps: {
                    sound: "default",
                    badge: 1,
                  },
                },
              },
            },
          }),
        },
      );

      const data = await response.json();

      risultati.push({
        status: response.status,
        response: data,
      });

      if (!response.ok) {
        const errorCode = data?.error?.details?.[0]?.errorCode;

        if (errorCode === "UNREGISTERED" || errorCode === "INVALID_ARGUMENT") {
          await supabase.from("push_tokens").delete().eq("token", item.token);
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        risultati,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  } catch (e) {
    console.error(e);

    return new Response(
      JSON.stringify({
        error: e instanceof Error ? e.message : String(e),
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  }
});
