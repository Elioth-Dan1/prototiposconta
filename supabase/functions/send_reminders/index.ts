import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { encodeBase64, decodeBase64 } from "https://deno.land/std@0.224.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

/* ── ENV & SUPABASE ───────────────────────────────────────── */
const supabase = createClient(
  Deno.env.get("URL")!,
  Deno.env.get("SERVICE_ROLE_KEY")!,
);

/* ── Config FCM (service account en B64) ───────────────────── */
const serviceJson = JSON.parse(
  new TextDecoder().decode(decodeBase64(Deno.env.get("GOOGLE_SERVICE_ACCOUNT_B64")!)),
);
const projectId = serviceJson.project_id;

/* ---------- genera un access-token FCM válido 1 h ---------- */
async function getAccessToken(): Promise<string> {
  const iat = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceJson.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat,
    exp: iat + 3600,
  };

  const header  = encodeBase64(new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claim   = encodeBase64(new TextEncoder().encode(JSON.stringify(payload)));
  const unsigned = `${header}.${claim}`;

  const pem   = serviceJson.private_key.replace(/-----[^-]+-----/g, "").replace(/\n/g, "");
  const key   = await crypto.subtle.importKey(
    "pkcs8",
    decodeBase64(pem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig   = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  const jwt   = `${unsigned}.${encodeBase64(new Uint8Array(sig))}`;

  const { access_token } = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion : jwt,
    }),
  }).then((r) => r.json());

  return access_token as string;
}

/* ---------- helper para enviar push ---------- */
async function sendPush(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
) {
  return fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json; charset=utf-8",
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: { title, body },
        data,
      },
    }),
  });
}

/* ── Textos para estado de ánimo ───────────────────────────── */
const moodTexts = {
  morning:   { title: "¿Cómo amaneciste?",      body: "Registra tu estado de ánimo de la mañana ☀️" },
  afternoon: { title: "¿Cómo va tu tarde?",     body: "Cuéntanos tu estado de ánimo de la tarde 😊" },
  evening:   { title: "Antes de dormir…",       body: "Registra tu estado de ánimo de la noche 🌙" },
} as const;

type Slot = keyof typeof moodTexts;

/* ── FUNCIÓN PRINCIPAL ─────────────────────────────────────── */
serve(async (req) => {
  const url  = new URL(req.url);

  /* 1. Parámetros */
  const kind = url.searchParams.get("kind")   ?? "consumo"; // consumo | mood
  const slot = url.searchParams.get("slot")   ?? "morning"; // sólo usado si kind=mood
  const today = new Date().toISOString().substring(0, 10);

  /* 2. Obtiene usuarios con token */
  const { data: users, error } = await supabase
    .from("usuarios")
    .select("id, fcm_token")
    .not("fcm_token", "is", null);

  if (error) {
    console.error(error);
    return new Response("db error", { status: 500 });
  }

  const accessToken = await getAccessToken();

  /* 3. Lógica según tipo de recordatorio */
  for (const u of users ?? []) {
    if (kind === "consumo") {
      // --- días sin consumo ---------------------------------
      const { data: registro } = await supabase
        .from("registro_consumo")
        .select("id")
        .eq("usuario_id", u.id)
        .eq("fecha", today)
        .maybeSingle();

      if (registro) continue; // ya marcó

      const res = await sendPush(
        accessToken,
        u.fcm_token,
        "¡No olvides tu registro de hoy!",
        "Abre la app y marca tu día sin consumo 💪",
        { route: "days" },
      );
      console.log("push consumo", u.id, res.status);

    } else if (kind === "mood") {
      // --- estado de ánimo ----------------------------------
      if (!(slot in moodTexts)) return new Response("invalid slot", { status: 400 });

      const { data: mood } = await supabase
        .from("estado_animo")
        .select("id")
        .eq("usuario_id", u.id)
        .eq("fecha", today)
        .eq("franja", slot)
        .maybeSingle();

      if (mood) continue; // ya registró esa franja

      const res = await sendPush(
        accessToken,
        u.fcm_token,
        moodTexts[slot as Slot].title,
        moodTexts[slot as Slot].body,
        { route: "mood" },
      );
      console.log(`push mood ${slot}`, u.id, res.status);

    } else {
      return new Response("invalid kind", { status: 400 });
    }
  }

  return new Response("ok");
});
