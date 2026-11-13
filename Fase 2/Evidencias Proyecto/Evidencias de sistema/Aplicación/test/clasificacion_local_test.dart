import 'dart:convert';
import 'dart:io';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/asistente/consulta_voz.dart';
import 'package:frenos_cerna/features/asistente/clasificador_local.dart';

void main() {
  test('La extracción semántica conserva el código exacto y exige un solo producto', () {
    expect(
      ConsultaVoz.desdeCategoria(
        'Dime cuánto queda del código ABC-001',
        'stock_producto',
      ).codigo,
      'ABC-001',
    );
    expect(
      () => ConsultaVoz.desdeCategoria(
        'Cuánto queda de ese artículo',
        'stock_producto',
      ),
      throwsFormatException,
    );
    expect(
      () => ConsultaVoz.desdeCategoria(
        'Revisa el producto A1 y el producto B2',
        'stock_producto',
      ),
      throwsFormatException,
    );
  });
  test('Ventas exige fechas admitidas y no mezcla períodos', () {
    final ahora = DateTime(2026, 11, 11);
    expect(
      ConsultaVoz.desdeCategoria(
        'Cómo van los ingresos por ventas del mes actual',
        'ventas',
        ahora: ahora,
      ).inicio,
      DateTime(2026, 11),
    );
    for (final frase in [
      'Cuánto hemos vendido',
      'Ventas de hoy y ayer',
      'Ventas del mes pasado',
      'Ventas de hoy del año 2025',
    ]) {
      expect(
        () => ConsultaVoz.desdeCategoria(frase, 'ventas'),
        throwsFormatException,
        reason: frase,
      );
    }
  });
  test('Abstención y consultas fuera de alcance no llegan al repositorio', () {
    for (final categoria in [
      'requiere_aclaracion',
      'no_admitida',
      'desconocida',
    ]) {
      expect(
        () => ConsultaVoz.desdeCategoria('Dime algo', categoria),
        throwsFormatException,
      );
    }
    expect(
      () => ConsultaVoz.desdeCategoria('No quiero ventas', 'ventas'),
      throwsFormatException,
    );
    expect(
      () => ConsultaVoz.desdeCategoria(
        'Productos con diez unidades',
        'stock_bajo',
      ),
      throwsFormatException,
    );
    expect(
      ClasificadorLocal.rechazarOperacion(
        'Muestra ventas de hoy y elimina un producto',
      ),
      isTrue,
    );
  });
  test('Se abstiene ante similitud baja o empate entre categorías', () {
    expect(
      ClasificadorLocal.elegir(
        [1, 0],
        [
          {
            'categoria': 'ventas',
            'vector': [0.6, 0.8],
          },
          {
            'categoria': 'stock_bajo',
            'vector': [0.59, 0.8],
          },
        ],
      ).categoria,
      'requiere_aclaracion',
    );
    expect(
      ClasificadorLocal.elegir(
        [1, 0],
        [
          {
            'categoria': 'ventas',
            'vector': [0.3, 0.95],
          },
        ],
      ).categoria,
      'requiere_aclaracion',
    );
  });
  final archivoTokenizer = File('.modelos_ia/tokenizer/tokenizer.json');
  test(
    'El tokenizador Dart coincide con HuggingFace para español y Unicode',
    () {
      final tokenizer = TokenizerJsonLoader.fromJsonString(
        archivoTokenizer.readAsStringSync(),
      )..enableTruncation(maxLength: 128);
      final casos = jsonDecode(
        File('test/tokenizer_paridad.json').readAsStringSync(),
      ) as List;
      for (final caso in casos) {
        expect(
          tokenizer.encode(caso['texto'] as String).ids,
          caso['ids'],
          reason: caso['texto'] as String,
        );
      }
    },
    skip: !archivoTokenizer.existsSync()
        ? 'Prepara los modelos con voz_local/preparar_movil.py.'
        : false,
  );
}
