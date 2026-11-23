import { createClient } from "npm:@supabase/supabase-js@2";

const modelo = "models/gemini-3.8-live";
const headers = { "Cache-Control": "no-store" };

Deno.serve(async (request) => {
  const responder = (status: number, body: Record<string, unknown>) =>
    Response.json(body, { status, headers });

  if (request.method !== "POST") return responder(405, { error: "Método inválido" });
  const jwt = /^Bearer (\S+)$/i.exec(request.headers.get("authorization") ?? "")?.[1];
  if (!jwt) return responder(401, { error: "Inicia sesión" });

  const clave = Deno.env.get("GEMINI_API_KEY");
  if (!clave) return responder(503, { error: "Gemini no está configurado" });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: `Bearer ${jwt}` } } },
  );

  try {
    const { data: { user }, error } = await supabase.auth.getUser(jwt);
    if (error || !user) return responder(401, { error: "Sesión inválida" });

    const { data: rol, error: errorRol } = await supabase.rpc("rol_actual");
    if (errorRol || !["empleado", "administrador"].includes(rol)) {
      return responder(403, { error: "Tu cuenta no tiene acceso al asistente" });
    }

    const ahora = Date.now();
    const respuesta = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/auth_tokens",
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": clave },
        body: JSON.stringify({
          uses: 1,
          expireTime: new Date(ahora + 120_000).toISOString(),
          newSessionExpireTime: new Date(ahora + 30_000).toISOString(),
          // Bloquea el modelo y permite que Flutter aporte el resto de la configuración.
          bidiGenerateContentSetup: { model: modelo },
          fieldMask: "model",
        }),
        signal: AbortSignal.timeout(8_000),
      },
    );

    if (!respuesta.ok) {
      const cuerpo = await respuesta.json().catch(() => null);
      const estado = cuerpo?.error?.status;
      const codigo = typeof estado === "string" && /^[A-Z_]{1,40}$/.test(estado)
        ? estado
        : "sin código";
      console.error("La emisión del token de Gemini falló", respuesta.status, codigo);
      return responder(502, { error: "Gemini no está disponible" });
    }
    const { name } = await respuesta.json();
    if (typeof name !== "string" || name.length === 0) {
      return responder(502, { error: "Gemini devolvió un token inválido" });
    }
    return responder(200, { token: name });
  } catch (error) {
    console.error("Error al solicitar el token de Gemini", error instanceof Error ? error.name : "desconocido");
    return responder(502, { error: "No se pudo abrir la sesión de voz" });
  }
});
