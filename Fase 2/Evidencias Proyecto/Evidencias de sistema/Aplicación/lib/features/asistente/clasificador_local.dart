import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'consulta_voz.dart';
import 'modelos_dispositivo.dart';

class ClasificadorLocal {
  OrtSession? _sesion;
  SentencePieceTokenizer? _tokenizer;
  Map<String, List<List<double>>>? _ejemplos;

  Future<ConsultaVoz?> clasificar(String texto) async {
    if (texto.trim().isEmpty || texto.length > 200) return null;
    if (RegExp(
      r'\b(borra\w*|elimina\w*|modifica\w*|actualiza\w*|agrega\w*|crea\w*|registra\w*|cancela\w*|reserva\w*|excepto|ignora)\b',
      caseSensitive: false,
    ).hasMatch(texto)) {
      return null;
    }

    await _cargar();
    final vector = (await _vectores([texto])).single;
    final puntajes = _ejemplos!.entries.map((categoria) {
      final mejor = categoria.value
          .map((ejemplo) {
            var similitud = 0.0;
            for (var i = 0; i < vector.length; i++) {
              similitud += vector[i] * ejemplo[i];
            }
            return similitud;
          })
          .reduce(max);
      return MapEntry(categoria.key, mejor);
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    final mejor = puntajes.first;
    if (mejor.value < 0.50 || mejor.value - puntajes[1].value < 0.04) {
      return null;
    }
    return switch (mejor.key) {
      'sin_stock' => ConsultaVoz.sinStock,
      'stock_bajo' => ConsultaVoz.stockBajo,
      'stock_por_codigo' => ConsultaVoz.stockPorCodigo,
      'ventas' => ConsultaVoz.ventas,
      _ => null,
    };
  }

  Future<void> _cargar() async {
    if (_ejemplos != null) return;

    if (_sesion == null) {
      final modelos = ModelosDispositivo.instancia;
      final tokenizer = await File(await modelos.ruta('tokenizer'))
          .readAsString();
      _tokenizer = await compute(TokenizerJsonLoader.fromJsonString, tokenizer);
      _tokenizer!.enableTruncation(maxLength: 128);
      _sesion = await OnnxRuntime().createSession(
        await modelos.ruta('minilm'),
        options: OrtSessionOptions(intraOpNumThreads: 2, interOpNumThreads: 1),
      );
    }

    final ejemplos = jsonDecode(
      await rootBundle.loadString('assets/ia/ejemplos.json'),
    ) as Map<String, dynamic>;
    final vectores = <String, List<List<double>>>{};
    for (final categoria in ejemplos.entries) {
      vectores[categoria.key] = await _vectores(
        (categoria.value as List).cast<String>(),
      );
    }
    _ejemplos = vectores;
  }

  Future<List<List<double>>> _vectores(List<String> textos) async {
    final codificados = textos
        .map((texto) => _tokenizer!.encode(texto))
        .toList();
    final ancho = codificados.map((entrada) => entrada.ids.length).reduce(max);
    final forma = [textos.length, ancho];
    final ids = Int64List(textos.length * ancho)
      ..fillRange(0, textos.length * ancho, 1);
    final mascara = Int64List(ids.length);
    for (var fila = 0; fila < codificados.length; fila++) {
      final entrada = codificados[fila];
      final inicio = fila * ancho;
      final fin = inicio + entrada.ids.length;
      ids.setRange(inicio, fin, entrada.ids);
      mascara.setRange(inicio, fin, entrada.attentionMask);
    }

    final entradas = <String, OrtValue>{};
    Map<String, OrtValue> salidas = {};
    try {
      entradas['input_ids'] = await OrtValue.fromList(ids, forma);
      entradas['attention_mask'] = await OrtValue.fromList(mascara, forma);
      entradas['token_type_ids'] = await OrtValue.fromList(
        Int64List(ids.length),
        forma,
      );
      salidas = await _sesion!.run(entradas);
      final valores = await salidas['last_hidden_state']!.asFlattenedList();
      const dimensiones = 384;
      return List.generate(textos.length, (fila) {
        final vector = List<double>.filled(dimensiones, 0);
        for (var columna = 0; columna < ancho; columna++) {
          final token = fila * ancho + columna;
          if (mascara[token] == 0) continue;
          for (var i = 0; i < dimensiones; i++) {
            vector[i] += (valores[token * dimensiones + i] as num).toDouble();
          }
        }
        final norma = sqrt(vector.fold<double>(0, (suma, x) => suma + x * x));
        if (norma == 0 || !norma.isFinite) return vector;
        return vector.map((x) => x / norma).toList();
      });
    } finally {
      for (final tensor in [...entradas.values, ...salidas.values]) {
        await tensor.dispose();
      }
    }
  }

  Future<void> dispose() async {
    await _sesion?.close();
  }
}
