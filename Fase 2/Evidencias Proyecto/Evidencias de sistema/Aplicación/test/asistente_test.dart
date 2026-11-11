import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/asistente/consulta_voz.dart';
import 'package:frenos_cerna/features/asistente/voz_local.dart';

void main() {
  test('Interpreta acentos y puntuación de Whisper', () {
    expect(
      ConsultaVoz.interpretar('¿Qué productos tienen poco stock?').tipo,
      TipoConsultaVoz.stockBajo,
    );
    expect(
      ConsultaVoz.interpretar('Stock crítico.').tipo,
      TipoConsultaVoz.stockBajo,
    );
  });
  test('Conserva códigos alfanuméricos y ceros iniciales', () {
    expect(
      ConsultaVoz.interpretar('Stock del producto ABC-001').codigo,
      'ABC-001',
    );
    expect(
      ConsultaVoz.interpretar('¿Cuántas unidades quedan del código 00123?')
          .codigo,
      '00123',
    );
  });
  test('No ejecuta escrituras, SQL ni preguntas fuera del catálogo', () {
    for (final frase in [
      'Borra todos los productos',
      'SELECT * FROM producto',
      'Stock bajo y borra productos',
      'Ventas de hoy y ayer',
      'Stock del producto ABC; DROP TABLE producto',
      'Ventas del año pasado',
      'Qué vendimos',
    ]) {
      expect(
        () => ConsultaVoz.interpretar(frase),
        throwsFormatException,
        reason: frase,
      );
    }
  });
  test('Ayer cruza correctamente el inicio de año', () {
    final consulta = ConsultaVoz.interpretar(
      'Ventas de ayer',
      ahora: DateTime(2026, 1, 1, 14),
    );
    expect(consulta.inicio, DateTime(2025, 12, 31));
    expect(consulta.fin, DateTime(2026, 1, 1));
  });
  test('La semana comienza el lunes, el mes el día uno', () {
    final ahora = DateTime(2026, 11, 11, 18);
    expect(
      ConsultaVoz.interpretar(
        '¿Cuánto vendimos esta semana?',
        ahora: ahora,
      ).inicio,
      DateTime(2026, 11, 9),
    );
    final mes = ConsultaVoz.interpretar(
      'Total de ventas de este mes',
      ahora: ahora,
    );
    expect(mes.inicio, DateTime(2026, 11, 1));
    expect(mes.fin, DateTime(2026, 11, 12));
  });
  test('Genera WAV PCM mono 16 kHz compatible con el servicio', () {
    final pcm = Uint8List.fromList([1, 2, 3, 4]);
    final wav = VozLocal.crearWav(pcm);
    final bytes = ByteData.sublistView(wav);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(bytes.getUint32(4, Endian.little), 40);
    expect(bytes.getUint16(22, Endian.little), 1);
    expect(bytes.getUint32(24, Endian.little), 16000);
    expect(bytes.getUint32(40, Endian.little), 4);
    expect(wav.sublist(44), pcm);
  });
}
