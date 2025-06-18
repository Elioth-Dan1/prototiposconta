// ── DEPENDENCIAS ─────────────────────────────────────────────
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  encodeBase64,
  decodeBase64,
} from "https://deno.land/std@0.224.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

// ── SUPABASE ─────────────────────────────────────────────────
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// ── CUENTA DE SERVICIO ───────────────────────────────────────
const serviceJson = JSON.parse(
  new TextDecoder().decode(decodeBase64(Deno.env.get("GOOGLE_SERVICE_ACCOUNT_B64")!))
);

const projectId   = serviceJson.project_id;

/** Firma un JWT y devuelve un access-token válido 1 h */
async function getAccessToken(): Promise<string> {
  const iat = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceJson.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud : "https://oauth2.googleapis.com/token",
    iat,
    exp: iat + 3600,
  };

  const header   = encodeBase64(new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claim    = encodeBase64(new TextEncoder().encode(JSON.stringify(payload)));
  const unsigned = `${header}.${claim}`;

  // Quitar cabeceras PEM y decodificar
  const pem     = serviceJson.private_key.replace(/-----[^-]+-----/g, "").replace(/\n/g, "");
  const keyData = decodeBase64(pem);

  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );

  const jwt = `${unsigned}.${encodeBase64(new Uint8Array(sig))}`;

  // Intercambiar JWT por access-token
  const { access_token } = await fetch("https://oauth2.googleapis.com/token", {
    method : "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body   : new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion : jwt,
    }),
  }).then(r => r.json());

  return access_token as string;
}

// ── FUNCIÓN PRINCIPAL ────────────────────────────────────────
serve(async () => {
  const today = new Date().toISOString().substring(0, 10);

  const { data: users, error } = await supabase
    .from("usuarios")
    .select("id, fcm_token")
    .not("fcm_token", "is", null);

  if (error) {
    console.error("DB:", error);
    return new Response("db error", { status: 500 });
  }

  const accessToken = await getAccessToken();

  for (const u of users ?? []) {
    const { data: registro } = await supabase
      .from("registro_consumo")
      .select("id")
      .eq("usuario_id", u.id)
      .eq("fecha", today)
      .maybeSingle();

    if (registro) continue;            // ya registró hoy → omite

    console.log("Recordatorio a", u.id);

    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method : "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type" : "application/json; charset=utf-8",
        },
        body: JSON.stringify({
          message: {
            token: u.fcm_token,
            notification: {
              title: "¡No olvides tu registro de hoy!",
              body : "Abre la app y marca tu día sin consumo 💪",
            },
          },
        }),
      },
    );

    console.log("FCM →", res.status, await res.text());
  }

  return new Response("ok");
});
