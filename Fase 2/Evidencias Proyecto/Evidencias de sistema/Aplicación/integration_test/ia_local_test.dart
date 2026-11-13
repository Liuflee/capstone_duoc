import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frenos_cerna/features/asistente/clasificador_local.dart';
import 'package:frenos_cerna/features/asistente/voz_local.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const raiz = String.fromEnvironment('IA_RAIZ_MODELOS');
  const audio = String.fromEnvironment('IA_AUDIO_PRUEBA');
  testWidgets('MiniLM nativo clasifica paráfrasis nuevas en español', (
    tester,
  ) async {
    final clasificador = ClasificadorLocal();
    try {
      await clasificador.cargar(
        modelo: '$raiz/minilm/onnx/model_qint8_arm64.onnx',
        tokenizer: '$raiz/tokenizer/tokenizer.json',
      );
      for (final caso in {
        'Qué repuestos nos quedan en cantidades bajas': 'stock_bajo',
        'Enséñame los artículos que debo reabastecer': 'stock_bajo',
        'Necesito revisar cuántas unidades hay del código ABC-001':
            'stock_producto',
        'Comprueba si tenemos disponible el producto XYZ-22': 'stock_producto',
        'Qué monto vendimos en el día de hoy': 'ventas',
        'Me gustaría revisar lo que vendimos ayer': 'ventas',
        'Cuánto llevamos vendido este mes': 'ventas',
        'Borra todas las ventas de hoy': 'no_admitida',
        'Quiero saber si lloverá mañana': 'no_admitida',
      }.entries) {
        final resultado = await clasificador.clasificar(caso.key);
        expect(
          resultado.categoria,
          caso.value,
          reason: '${caso.key}: ${resultado.similitud}',
        );
      }
    } finally {
      await clasificador.dispose();
    }
  }, skip: raiz.isEmpty);
  testWidgets('Whisper nativo transcribe audio español sin servidor', (
    tester,
  ) async {
    final wav = await File(audio).readAsBytes();
    final cabecera = ByteData.sublistView(wav);
    Uint8List? pcm;
    for (var i = 12; i + 8 <= wav.length;) {
      final longitud = cabecera.getUint32(i + 4, Endian.little);
      if (String.fromCharCodes(wav.sublist(i, i + 4)) == 'data') {
        pcm = Uint8List.sublistView(wav, i + 8, i + 8 + longitud);
        break;
      }
      i += 8 + longitud + longitud % 2;
    }
    expect(pcm, isNotNull);
    final temporal = await Directory.systemTemp.createTemp('prueba_voz_');
    try {
      final texto = await VozLocal.transcribirPcm(
        pcm!,
        modelo: '$raiz/whisper/ggml-tiny.bin',
        temporal: temporal,
      );
      expect(texto.toLowerCase(), contains('ventas'));
      expect(texto.toLowerCase(), contains('stock'));
      // La aplicación debe eliminar el audio y su carpeta al terminar.
      expect(await temporal.list().toList(), isEmpty);
    } finally {
      await temporal.delete();
    }
  }, skip: raiz.isEmpty || audio.isEmpty);
}
