import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import 'modelos_dispositivo.dart';

class VozLocal {
  final _grabador = AudioRecorder();
  WhisperLiveSession? _sesion;
  StreamSubscription<String>? _texto;
  StreamSubscription<Uint8List>? _audio;
  bool _modeloCargado = false;
  bool _grabando = false;

  Future<void> iniciar({
    required void Function(String) alTranscribir,
    required void Function(Object) alFallar,
    required bool Function() vigente,
  }) async {
    final modelo = await ModelosDispositivo.instancia.ruta('whisper');
    if (!vigente()) return;
    if (!await _grabador.hasPermission()) {
      throw StateError(
        'Permite el acceso al micrófono para usar el asistente.',
      );
    }
    if (!vigente()) return;
    final audio = await _grabador.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _grabando = true;
    if (!vigente()) return;
    // Carga Whisper antes de suscribirse al audio. Si se interrumpe la
    // inicialización, detener() también cierra el grabador.
    final sesion = await startWhisperLiveSession(
      modelPath: modelo,
      lang: 'es',
      threads: 2,
      keepModelLoaded: true,
    );
    _sesion = sesion;
    _modeloCargado = true;
    if (!vigente()) return;
    _texto = sesion.partials.listen(alTranscribir, onError: alFallar);
    _audio = audio.listen(sesion.feed, onError: alFallar);
  }

  Future<String> detener() async {
    final sesion = _sesion;
    _sesion = null;
    var transcripcion = '';
    try {
      if (_grabando) {
        _grabando = false;
        await _grabador.stop();
      }
    } finally {
      await _audio?.cancel();
      _audio = null;
      await _texto?.cancel();
      _texto = null;
      if (sesion != null) {
        transcripcion = await sesion.stop();
      }
    }
    return transcripcion;
  }

  Future<void> liberarModelo() async {
    if (!_modeloCargado) return;
    await const Whisper(model: WhisperModel.tiny).releaseModel();
    _modeloCargado = false;
  }

  Future<void> dispose() async {
    try {
      await detener();
      await liberarModelo();
    } finally {
      await _grabador.dispose();
    }
  }
}
