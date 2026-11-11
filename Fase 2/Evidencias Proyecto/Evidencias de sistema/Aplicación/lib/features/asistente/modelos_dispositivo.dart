import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Solo descarga los archivos fijados en el manifiesto, con revisión y SHA-256.
class ModelosDispositivo {
  static final instancia = ModelosDispositivo();
  Future<void>? _preparacion;
  Map<String, String>? _rutas;

  Future<List<Map<String, dynamic>>> _manifiesto() async => (jsonDecode(
    await rootBundle.loadString('assets/ia/modelos.json'),
  ) as List).map((dato) => Map<String, dynamic>.from(dato as Map)).toList();

  Future<Directory> _carpeta() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/ia_taller_v1').create(recursive: true);
  }

  Future<bool> disponible() async {
    try {
      await ruta('minilm');
      return true;
    } on StateError {
      return false;
    } on FileSystemException {
      return false;
    }
  }

  Future<String> ruta(String nombre) async {
    if (_rutas == null) {
      final carpeta = await _carpeta();
      final rutas = <String, String>{};
      for (final modelo in await _manifiesto()) {
        final archivo = File('${carpeta.path}/${modelo['archivo']}');
        if (!await archivo.exists() ||
            await archivo.length() != modelo['bytes']) {
          throw StateError('Primero descarga la IA en este dispositivo.');
        }
        if ((await sha256.bind(archivo.openRead()).first).toString() !=
            modelo['sha256']) {
          throw StateError(
            'Un modelo está dañado. Pulsa Descargar IA para repararlo.',
          );
        }
        rutas[modelo['nombre'] as String] = archivo.path;
      }
      _rutas = rutas;
    }
    return _rutas![nombre]!;
  }

  Future<void> preparar(void Function(double avance) progreso) {
    return _preparacion ??= _descargar(progreso)
        .whenComplete(() => _preparacion = null);
  }

  Future<void> _descargar(void Function(double) progreso) async {
    _rutas = null;
    final manifiesto = await _manifiesto();
    final total = manifiesto.fold<int>(
      0,
      (suma, dato) => suma + (dato['bytes'] as int),
    );
    var completados = 0;
    final carpeta = await _carpeta();
    final cliente = http.Client();
    try {
      for (final modelo in manifiesto) {
        final archivo = File('${carpeta.path}/${modelo['archivo']}');
        final bytes = modelo['bytes'] as int;
        if (await archivo.exists() &&
            await archivo.length() == bytes &&
            (await sha256.bind(archivo.openRead()).first).toString() ==
                modelo['sha256']) {
          completados += bytes;
          progreso(completados / total);
          continue;
        }
        final parcial = File('${archivo.path}.parcial');
        IOSink? salida;
        try {
          final respuesta = await cliente
              .send(http.Request('GET', Uri.parse(modelo['url'] as String)))
              .timeout(const Duration(seconds: 45));
          if (respuesta.statusCode != 200) {
            throw StateError(
              'No se pudo descargar la IA. Intenta nuevamente con conexión a internet.',
            );
          }
          salida = parcial.openWrite();
          var recibidos = 0;
          await for (final parte in respuesta.stream.timeout(
            const Duration(seconds: 60),
          )) {
            recibidos += parte.length;
            if (recibidos > bytes) {
              throw StateError('La descarga del modelo no es válida.');
            }
            salida.add(parte);
            progreso((completados + recibidos) / total);
          }
          await salida.close();
          salida = null;
          if (recibidos != bytes ||
              (await sha256.bind(parcial.openRead()).first).toString() !=
                  modelo['sha256']) {
            throw StateError(
              'La descarga quedó incompleta. Intenta nuevamente.',
            );
          }
          // Elimina únicamente el archivo concreto de caché de este modelo.
          if (await archivo.exists()) await archivo.delete();
          await parcial.rename(archivo.path);
          completados += bytes;
        } finally {
          await salida?.close();
          if (await parcial.exists()) await parcial.delete();
        }
      }
    } finally {
      cliente.close();
    }
  }
}
