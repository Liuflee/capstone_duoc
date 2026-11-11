import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import 'modelos_dispositivo.dart';

class VozLocal {
  final _grabador = AudioRecorder();
  final _audio = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _suscripcion;
  Timer? _limite;
  bool _cerrado = false;
  Object? _errorAudio;

  Future<void> iniciar(void Function() alLimite) async {
    await ModelosDispositivo.instancia.ruta('whisper');
    if (!await _grabador.hasPermission()) {
      throw StateError(
        'Permite el acceso al micrófono en la configuración de tu dispositivo.',
      );
    }
    _audio.clear();
    _errorAudio = null;
    final flujo = await _grabador.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    if (_cerrado) {
      await _grabador.stop();
      return;
    }
    _suscripcion = flujo.listen(
      (parte) {
        // Nunca acumula más de 30 segundos, incluso si se retrasa el temporizador.
        final disponibles = 960000 - _audio.length;
        if (disponibles > 0) _audio.add(parte.take(disponibles).toList());
      },
      onError: (Object error) {
        _errorAudio = error;
      },
    );
    _limite = Timer(const Duration(seconds: 30), alLimite);
  }

  Future<String> detenerYTranscribir() async {
    _limite?.cancel();
    await _grabador.stop();
    await _suscripcion?.cancel();
    _suscripcion = null;
    final pcm = _audio.takeBytes();
    if (_errorAudio != null) {
      throw StateError('Se interrumpió el micrófono. Repite la grabación.');
    }
    return transcribirPcm(
      pcm,
      modelo: await ModelosDispositivo.instancia.ruta('whisper'),
      temporal: await getTemporaryDirectory(),
    );
  }

  /// Usa el mismo recorrido para el micrófono y las pruebas de audio nativas.
  static Future<String> transcribirPcm(
    Uint8List pcm, {
    required String modelo,
    required Directory temporal,
  }) async {
    if (pcm.length < 3200) {
      throw StateError('La grabación es muy corta. Vuelve a intentarlo.');
    }
    final muestras = ByteData.sublistView(pcm);
    var energia = 0.0;
    for (var i = 0; i + 1 < pcm.length; i += 2) {
      final valor = muestras.getInt16(i, Endian.little) / 32768;
      energia += valor * valor;
    }
    if (energia / (pcm.length / 2) < 0.000009) {
      throw StateError(
        'No se detectó voz. Acércate al micrófono y vuelve a intentar.',
      );
    }
    final carpeta = await temporal.createTemp('consulta_voz_');
    final archivo = File('${carpeta.path}/audio.wav');
    try {
      await archivo.writeAsBytes(crearWav(pcm), flush: true);
      final respuesta = await const Whisper(model: WhisperModel.tiny)
          .transcribe(
            modelPath: modelo,
            transcribeRequest: TranscribeRequest(
              audio: archivo.path,
              language: 'es',
              threads: 2,
              isNoTimestamps: true,
              noContext: true,
              suppressNonSpeechTokens: true,
              keepModelLoaded: false,
              initialPrompt: 'Productos con stock bajo. Ventas de hoy.',
            ),
          );
      final texto = respuesta.text.trim();
      if (texto.isEmpty) {
        throw StateError('No se reconoció la pregunta. Vuelve a intentar.');
      }
      return texto;
    } finally {
      for (final ruta in [archivo.path, '${archivo.path}.wav']) {
        final audio = File(ruta);
        if (await audio.exists()) await audio.delete();
      }
      await carpeta.delete();
    }
  }

  static Uint8List crearWav(Uint8List pcm) {
    final resultado = Uint8List(44 + pcm.length);
    final cabecera = ByteData.sublistView(resultado);
    resultado.setRange(0, 4, ascii.encode('RIFF'));
    cabecera.setUint32(4, 36 + pcm.length, Endian.little);
    resultado.setRange(8, 16, ascii.encode('WAVEfmt '));
    cabecera.setUint32(16, 16, Endian.little);
    cabecera.setUint16(20, 1, Endian.little);
    cabecera.setUint16(22, 1, Endian.little);
    cabecera.setUint32(24, 16000, Endian.little);
    cabecera.setUint32(28, 32000, Endian.little);
    cabecera.setUint16(32, 2, Endian.little);
    cabecera.setUint16(34, 16, Endian.little);
    resultado.setRange(36, 40, ascii.encode('data'));
    cabecera.setUint32(40, pcm.length, Endian.little);
    resultado.setRange(44, resultado.length, pcm);
    return resultado;
  }

  Future<void> cancelar() async {
    _limite?.cancel();
    await _grabador.stop();
    await _suscripcion?.cancel();
    _suscripcion = null;
    _audio.clear();
  }

  void dispose() {
    _cerrado = true;
    _limite?.cancel();
    _suscripcion?.cancel();
    _grabador.dispose();
  }
}
