import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class NarradorLocal {
  final _tts = FlutterTts();
  bool _configurado = false;

  Future<bool> narrar(
    String resumen,
    Iterable<String> productos, {
    required bool Function() vigente,
  }) async {
    if (!_configurado) {
      final voces = ((await _tts.getVoices) as List).whereType<Map>().where((
        voz,
      ) {
        final idioma = voz['locale'].toString().toLowerCase();
        final espanol = idioma == 'es' || idioma.startsWith('es-');
        return espanol &&
            (defaultTargetPlatform != TargetPlatform.android ||
                (voz['network_required'] == '0' &&
                    !voz['features'].toString().contains('notInstalled')));
      }).toList();
      if (voces.isEmpty) return false;
      final voz = voces.firstWhere(
        (voz) => voz['locale'] == 'es-CL',
        orElse: () => voces.first,
      );
      if (await _tts.setVoice({
            'name': voz['name'] as String,
            'locale': voz['locale'] as String,
            if (voz['identifier'] case final String id) 'identifier': id,
          }) !=
          1) {
        return false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [],
        );
      }
      await _tts.awaitSpeakCompletion(true);
      _configurado = true;
    }
    final frases = [resumen];
    for (final producto in productos) {
      if (frases.last.length + producto.length > 800) {
        frases.add(producto);
      } else {
        frases[frases.length - 1] += ' $producto';
      }
    }
    for (final frase in frases) {
      if (!vigente()) return false;
      if (await _tts.speak(frase) != 1) return false;
    }
    return true;
  }

  Future<void> detener() async {
    await _tts.stop();
  }
}
