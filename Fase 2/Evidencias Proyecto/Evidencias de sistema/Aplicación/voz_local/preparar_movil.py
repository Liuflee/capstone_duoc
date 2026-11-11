"""Descarga los modelos originales y fija URL, tamaño y hash para la app."""
import hashlib
import json
import numpy as np
import onnxruntime as ort
from tokenizers import Tokenizer
from pathlib import Path
from huggingface_hub import HfApi, hf_hub_download

RAIZ = Path(__file__).resolve().parent.parent
DESTINO = RAIZ / '.modelos_ia'
ASSETS = RAIZ / 'assets' / 'ia'


def preparar():
    modelos = [
        ('minilm', 'sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2', 'onnx/model_qint8_arm64.onnx'),
        ('tokenizer', 'sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2', 'tokenizer.json'),
        ('whisper', 'ggerganov/whisper.cpp', 'ggml-tiny.bin'),
    ]
    manifiesto = []
    api = HfApi()
    for nombre, repo, archivo in modelos:
        revision = api.model_info(repo).sha
        ruta = Path(hf_hub_download(repo, archivo, revision=revision, local_dir=str(DESTINO / nombre)))
        with ruta.open('rb') as entrada:
            sha = hashlib.file_digest(entrada, 'sha256').hexdigest()
        manifiesto.append(dict(nombre=nombre,
            url=f'https://huggingface.co/{repo}/resolve/{revision}/{archivo}',
            archivo=ruta.name, bytes=ruta.stat().st_size, sha256=sha))
        print(nombre, ruta.stat().st_size, flush=True)
    ASSETS.mkdir(parents=True, exist_ok=True)
    (ASSETS / 'modelos.json').write_text(json.dumps(manifiesto, indent=2), encoding='utf-8')
    generar_vectores()


def generar_vectores():
    tokenizer = Tokenizer.from_file(str(DESTINO / 'tokenizer' / 'tokenizer.json'))
    tokenizer.enable_truncation(max_length=128)
    opciones = ort.SessionOptions()
    opciones.intra_op_num_threads = 2
    opciones.inter_op_num_threads = 1
    sesion = ort.InferenceSession(str(DESTINO / 'minilm' / 'onnx' / 'model_qint8_arm64.onnx'),
        sess_options=opciones, providers=['CPUExecutionProvider'])
    ejemplos = json.loads((ASSETS / 'ejemplos.json').read_text(encoding='utf-8'))
    vectores, paridad = [], []
    for categoria, frases in ejemplos.items():
        for texto in frases:
            codificado = tokenizer.encode(texto)
            ids = np.array([codificado.ids], dtype=np.int64)
            salida = sesion.run(None, dict(input_ids=ids,
                attention_mask=np.ones_like(ids), token_type_ids=np.zeros_like(ids)))[0]
            vector = salida[0].mean(axis=0)
            vector /= np.linalg.norm(vector)
            vectores.append(dict(categoria=categoria, texto=texto,
                vector=[round(float(x), 8) for x in vector]))
            paridad.append(dict(texto=texto, ids=codificado.ids))
    # Casos con acentos, códigos y normalización Unicode para comprobar paridad Dart/Rust.
    for texto in ['¿Cuánto vendimos hoy?', 'Código ABC-001', 'reposición de artículos',
                  'cafe\u0301', 'ABC—123', '¿Y ayer?', 'stock\u00a0bajo', 'No quiero ventas, necesito inventario']:
        paridad.append(dict(texto=texto, ids=tokenizer.encode(texto).ids))
    (ASSETS / 'vectores.json').write_text(json.dumps(vectores, ensure_ascii=False), encoding='utf-8')
    (RAIZ / 'test' / 'tokenizer_paridad.json').write_text(json.dumps(paridad, ensure_ascii=False), encoding='utf-8')
    print(f'Generados {len(vectores)} ejemplos y {len(paridad)} casos de paridad.', flush=True)


if __name__ == '__main__':
    preparar()
