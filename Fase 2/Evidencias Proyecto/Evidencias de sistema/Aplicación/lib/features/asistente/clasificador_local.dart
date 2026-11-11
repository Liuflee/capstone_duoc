import 'dart:convert';
import 'dart:math';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'dart:io';

import 'modelos_dispositivo.dart';

class ClasificacionVoz {
  final String categoria;
  final double similitud;
  const ClasificacionVoz(this.categoria, this.similitud);
}

class ClasificadorLocal {
  OrtSession? _sesion;
  SentencePieceTokenizer? _tokenizer;
  List<Map<String, dynamic>>? _ejemplos;
  Future<ClasificacionVoz>? _enCurso;
  bool _cerrado = false;

  Future<void> cargar({String? modelo, String? tokenizer}) async {
    if (_sesion != null) return;
    final rutaModelo =
        modelo ?? await ModelosDispositivo.instancia.ruta('minilm');
    final rutaTokenizer =
        tokenizer ?? await ModelosDispositivo.instancia.ruta('tokenizer');
    final json = await File(rutaTokenizer).readAsString();
    _tokenizer = await compute(TokenizerJsonLoader.fromJsonString, json);
    _tokenizer!.enableTruncation(maxLength: 128);
    _ejemplos = (jsonDecode(
      await rootBundle.loadString('assets/ia/vectores.json'),
    ) as List).map((fila) => Map<String, dynamic>.from(fila as Map)).toList();
    _sesion = await OnnxRuntime().createSession(
      rutaModelo,
      options: OrtSessionOptions(
        intraOpNumThreads: 2,
        interOpNumThreads: 1,
        useArena: false,
      ),
    );
  }

  Future<ClasificacionVoz> clasificar(String texto) {
    if (_cerrado) throw StateError('El asistente se cerró. Vuelve a abrirlo.');
    return _enCurso ??= _clasificar(texto).whenComplete(() => _enCurso = null);
  }

  Future<ClasificacionVoz> _clasificar(String texto) async {
    if (texto.trim().isEmpty || texto.length > 200) {
      return const ClasificacionVoz('requiere_aclaracion', 0);
    }
    if (rechazarOperacion(texto)) {
      return const ClasificacionVoz('no_admitida', 0);
    }
    await cargar();
    final codificado = _tokenizer!.encode(texto);
    final ids = Int64List.fromList(codificado.ids);
    final entradas = <String, OrtValue>{};
    Map<String, OrtValue> salidas = {};
    try {
      entradas['input_ids'] = await OrtValue.fromList(ids, [1, ids.length]);
      entradas['attention_mask'] = await OrtValue.fromList(
        Int64List.fromList(codificado.attentionMask),
        [1, ids.length],
      );
      entradas['token_type_ids'] = await OrtValue.fromList(
        Int64List(ids.length),
        [1, ids.length],
      );
      salidas = await _sesion!.run(entradas);
      final valores = await salidas['last_hidden_state']!.asFlattenedList();
      final vector = List<double>.filled(384, 0);
      for (var token = 0; token < ids.length; token++) {
        for (var i = 0; i < 384; i++) {
          vector[i] += (valores[token * 384 + i] as num).toDouble();
        }
      }
      final norma = sqrt(vector.fold<double>(0, (s, x) => s + x * x));
      if (norma == 0) return const ClasificacionVoz('requiere_aclaracion', 0);
      for (var i = 0; i < vector.length; i++) {
        vector[i] /= norma;
      }
      return elegir(vector, _ejemplos!);
    } finally {
      for (final tensor in [...entradas.values, ...salidas.values]) {
        await tensor.dispose();
      }
    }
  }

  static bool rechazarOperacion(String texto) => RegExp(
    r'\b(borra\w*|elimina\w*|modifica\w*|actualiza\w*|agrega\w*|crea\w*|registra\w*|cancela\w*|reserva\w*|insert|update|delete|drop|select)\b',
    caseSensitive: false,
  ).hasMatch(texto);

  /// Son similitudes, no probabilidades. Margen y mínimo permiten abstenerse.
  static ClasificacionVoz elegir(
    List<double> vector,
    List<Map<String, dynamic>> ejemplos,
  ) {
    final mejores = <String, double>{};
    for (final ejemplo in ejemplos) {
      final comparado = ejemplo['vector'] as List;
      var similitud = 0.0;
      for (var i = 0; i < vector.length; i++) {
        similitud += vector[i] * (comparado[i] as num);
      }
      final categoria = ejemplo['categoria'] as String;
      mejores[categoria] = max(mejores[categoria] ?? -1, similitud);
    }
    final orden = mejores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (orden.isEmpty ||
        orden.first.value < 0.50 ||
        (orden.length > 1 && orden.first.value - orden[1].value < 0.06)) {
      return ClasificacionVoz(
        'requiere_aclaracion',
        orden.isEmpty ? 0 : orden.first.value,
      );
    }
    return ClasificacionVoz(orden.first.key, orden.first.value);
  }

  Future<void> dispose() async {
    _cerrado = true;
    try {
      await _enCurso;
    } catch (_) {
      /* El llamador presenta el error. */
    }
    await _sesion?.close();
    _sesion = null;
    _tokenizer = null;
  }
}
