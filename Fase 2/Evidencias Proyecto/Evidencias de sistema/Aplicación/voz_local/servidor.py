"""Transcripción local: no guarda audio ni recibe datos de las consultas."""
import asyncio
import io
import json
import os
from pathlib import Path
import threading
import wave

import httpx
import numpy as np
from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

RAIZ = Path(__file__).resolve().parent
MAX_AUDIO = 16000 * 2 * 30 + 44
app = FastAPI(title="Voz local Frenos Cerna")
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["POST", "GET"],
    allow_headers=["Authorization", "Content-Type"],
)
_modelo = None
_cerrojo = threading.Lock()
_turno = asyncio.Semaphore(1)
_bearer = HTTPBearer(auto_error=False)


def configuracion():
    archivo = RAIZ.parent / "supabase.config.json"
    datos = json.loads(archivo.read_text(encoding="utf-8-sig")) if archivo.exists() else {}
    url = os.getenv("SUPABASE_URL", datos.get("SUPABASE_URL", ""))
    clave = os.getenv("SUPABASE_PUBLISHABLE_KEY", datos.get("SUPABASE_PUBLISHABLE_KEY", ""))
    if not url.startswith("https://") or not clave:
        raise HTTPException(503, "Configura Supabase en el servidor de voz.")
    return url.rstrip("/"), clave


async def autenticar(credenciales: HTTPAuthorizationCredentials | None = Depends(_bearer)):
    if credenciales is None:
        raise HTTPException(401, "Inicia sesión antes de usar el micrófono.")
    url, clave = configuracion()
    try:
        async with httpx.AsyncClient(timeout=10) as cliente:
            respuesta = await cliente.get(
                f"{url}/auth/v1/user",
                headers={"apikey": clave, "Authorization": f"Bearer {credenciales.credentials}"},
            )
        if respuesta.status_code in (401, 403):
            raise HTTPException(401, "La sesión expiró. Vuelve a iniciar sesión.")
        if respuesta.status_code != 200:
            raise HTTPException(503, "No se pudo verificar la sesión.")
    except httpx.HTTPError:
        raise HTTPException(503, "No se pudo verificar la sesión con Supabase.") from None


def leer_audio(datos: bytes) -> np.ndarray:
    try:
        with wave.open(io.BytesIO(datos), "rb") as archivo:
            if (archivo.getnchannels(), archivo.getsampwidth(), archivo.getframerate()) != (1, 2, 16000):
                raise ValueError()
            if not 1600 <= archivo.getnframes() <= 16000 * 30:
                raise ValueError()
            cuadros = archivo.readframes(archivo.getnframes())
            if len(cuadros) != archivo.getnframes() * 2:
                raise ValueError()
        return np.frombuffer(cuadros, dtype="<i2").astype(np.float32) / 32768.0
    except (wave.Error, EOFError, ValueError):
        raise HTTPException(400, "Envía audio WAV mono de 16 kHz, entre 0,1 y 30 segundos.") from None


def transcribir(audio):
    global _modelo
    with _cerrojo:
        if _modelo is None:
            from faster_whisper import WhisperModel
            _modelo = WhisperModel(
                os.getenv("WHISPER_MODEL", "base"), device="cpu", compute_type="int8",
                download_root=str(RAIZ / "modelos"),
            )
        segmentos, _ = _modelo.transcribe(
            audio, language="es", beam_size=5, vad_filter=True,
            initial_prompt="Consultas de un taller: productos con stock bajo, código de producto, inventario, ventas de hoy.",
        )
        return " ".join(segmento.text.strip() for segmento in segmentos).strip()


@app.get("/salud")
def salud():
    return {"estado": "disponible", "modelo_cargado": _modelo is not None}


@app.post("/transcribir", dependencies=[Depends(autenticar)])
async def recibir(request: Request):
    if _turno.locked():
        raise HTTPException(429, "El reconocedor está ocupado. Intenta nuevamente.")
    async with _turno:
        datos = bytearray()
        async for parte in request.stream():
            datos.extend(parte)
            if len(datos) > MAX_AUDIO:
                raise HTTPException(413, "La grabación supera los 30 segundos.")
        audio = leer_audio(bytes(datos))
        try:
            texto = await asyncio.to_thread(transcribir, audio)
        except Exception:
            raise HTTPException(503, "No se pudo cargar o ejecutar Whisper. Revisa el servidor local.") from None
        if not texto:
            raise HTTPException(422, "No se detectó voz. Acércate al micrófono y vuelve a intentar.")
        return {"texto": texto}
