import io
import unittest
from unittest.mock import patch, AsyncMock
import wave

from fastapi.testclient import TestClient
import servidor


def wav(segundos=1, frecuencia=16000):
    salida = io.BytesIO()
    with wave.open(salida, "wb") as archivo:
        archivo.setnchannels(1)
        archivo.setsampwidth(2)
        archivo.setframerate(frecuencia)
        archivo.writeframes(b"\0\0" * frecuencia * segundos)
    return salida.getvalue()


class PruebasVoz(unittest.TestCase):
    def setUp(self):
        self.cliente = TestClient(servidor.app)

    def tearDown(self):
        servidor.app.dependency_overrides.clear()
        self.cliente.close()

    def autorizar(self):
        servidor.app.dependency_overrides[servidor.autenticar] = lambda: None

    def test_exige_sesion_antes_de_cargar_modelo(self):
        with patch.object(servidor, "transcribir") as modelo:
            self.assertEqual(self.cliente.post('/transcribir', content=wav()).status_code, 401)
            modelo.assert_not_called()

    def test_rechaza_token_invalido(self):
        respuesta = AsyncMock()
        respuesta.get.return_value = type('Respuesta', (), {'status_code': 401})()
        with patch.object(servidor, 'configuracion', return_value=('https://ejemplo.supabase.co', 'publica')):
            with patch('servidor.httpx.AsyncClient') as cliente:
                cliente.return_value.__aenter__.return_value = respuesta
                self.assertEqual(self.cliente.post('/transcribir', content=wav(), headers={'Authorization': 'Bearer invalido'}).status_code, 401)

    def test_valida_audio_y_duracion(self):
        self.autorizar()
        for audio in (b'no es audio', wav(frecuencia=8000), wav(segundos=0)):
            self.assertEqual(self.cliente.post('/transcribir', content=audio).status_code, 400)
        self.assertEqual(self.cliente.post('/transcribir', content=wav(segundos=31)).status_code, 413)

    def test_texto_y_silencio(self):
        self.autorizar()
        with patch.object(servidor, 'transcribir', return_value='Ventas de hoy'):
            self.assertEqual(self.cliente.post('/transcribir', content=wav()).json(), {'texto': 'Ventas de hoy'})
        with patch.object(servidor, 'transcribir', return_value=''):
            self.assertEqual(self.cliente.post('/transcribir', content=wav()).status_code, 422)

    def test_fallo_modelo_no_expone_informacion_interna(self):
        self.autorizar()
        with patch.object(servidor, 'transcribir', side_effect=RuntimeError('secreto')):
            respuesta = self.cliente.post('/transcribir', content=wav())
            self.assertEqual(respuesta.status_code, 503)
            self.assertNotIn('secreto', respuesta.text)


if __name__ == '__main__':
    unittest.main()
