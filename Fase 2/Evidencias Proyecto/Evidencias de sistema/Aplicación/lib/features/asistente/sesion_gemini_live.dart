import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import 'acciones_cerna.dart';

class SesionGeminiLive {
  SesionGeminiLive({
    required this.acciones,
    required this.alConectar,
    required this.alResponder,
    required this.alTerminar,
    required this.alCancelarHerramienta,
  });

  final AccionesCerna acciones;
  final void Function() alConectar;
  final void Function(String) alResponder;
  final void Function(String?) alTerminar;
  final void Function(String) alCancelarHerramienta;
  final _audio = SoLoud.instance;
  final _canceladas = <String>{};
  WebSocket? _socket;
  AudioSource? _fuente;
  Timer? _espera, _duracion, _finAudio;
  bool _cerrada = false;
  bool _lista = false;
  bool _turnoTerminado = false;
  int _operaciones = 0;
  String _respuesta = '';

  bool get lista => _lista && !_cerrada;

  Future<void> conectar() async {
    _duracion = Timer(const Duration(seconds: 95), () => cerrar());
    _espera = Timer(
      const Duration(seconds: 15),
      () => cerrar('Gemini no respondió a tiempo.'),
    );
    final token = await _pedirToken();
    if (_cerrada || token == null) return;

    try {
      if (!_audio.isInitialized) await _audio.init();
    } catch (error) {
      debugPrint(
        'Cerna: inicialización de audio fallida (${error.runtimeType}).',
      );
      cerrar('No se pudo iniciar la reproducción de audio de Cerna.');
      return;
    }
    if (_cerrada) return;

    try {
      final direccion = Uri.https(
        'generativelanguage.googleapis.com',
        '/ws/google.ai.generativelanguage.v1beta.GenerativeService.'
            'BidiGenerateContentConstrained',
        {'access_token': token},
      ).replace(scheme: 'wss');
      final socket = await WebSocket.connect(direccion.toString());
      if (_cerrada) {
        unawaited(socket.close());
        return;
      }
      _socket = socket;
      socket.listen(
        (mensaje) {
          try {
            _recibir(mensaje);
          } catch (_) {
            cerrar('No se pudo reproducir la respuesta de Cerna.');
          }
        },
        onDone: () {
          debugPrint(
            'Cerna: Gemini cerró la conexión (código ${socket.closeCode}, sesión lista: $_lista).',
          );
          cerrar(
            _lista
                ? 'Terminó la conexión con Gemini.'
                : 'Gemini rechazó el inicio de la sesión (código ${socket.closeCode ?? 'desconocido'}).',
          );
        },
        onError: (Object _) => cerrar('Se perdió la conexión con Gemini.'),
        cancelOnError: true,
      );
      _enviar({
        'setup': {
          'model': 'models/gemini-3.8-live',
          'generationConfig': {
            'responseModalities': ['AUDIO'],
          },
          'systemInstruction': {
            'parts': [
              {'text': instruccionesCerna},
            ],
          },
          'outputAudioTranscription': {},
          'tools': [
            {'functionDeclarations': herramientasCerna},
          ],
        },
      });
    } on WebSocketException catch (error) {
      final estado = error.httpStatusCode;
      debugPrint(
        'Cerna: apertura de Gemini Live fallida (HTTP ${estado ?? 'sin respuesta'}).',
      );
      cerrar(
        estado == null
            ? 'Supabase entregó el token, pero no se pudo abrir Gemini Live.'
            : 'Gemini Live rechazó la conexión (HTTP $estado).',
      );
    } catch (error) {
      debugPrint(
        'Cerna: apertura de Gemini Live fallida (${error.runtimeType}).',
      );
      cerrar('Supabase entregó el token, pero no se pudo abrir Gemini Live.');
    }
  }

  Future<String?> _pedirToken() async {
    try {
      final respuesta = await SupabaseDatabase.client.functions
          .invoke('cerna-live-token')
          .timeout(const Duration(seconds: 10));
      final datos = respuesta.data;
      final token = datos is Map ? datos['token'] : null;
      if (token is String && token.isNotEmpty) return token;
      cerrar('Supabase devolvió una respuesta sin el token de Cerna.');
    } on FunctionException catch (error) {
      debugPrint('Cerna: cerna-live-token devolvió HTTP ${error.status}.');
      cerrar(switch (error.status) {
        401 => 'Tu sesión de Supabase no es válida. Vuelve a iniciar sesión.',
        403 => 'Tu cuenta de Supabase no tiene acceso al asistente de voz.',
        404 =>
          'La función cerna-live-token no está desplegada en este proyecto.',
        502 => 'Supabase no pudo obtener el token de Google. Revisa los logs de cerna-live-token.',
        503 => 'Falta configurar GEMINI_API_KEY en Supabase.',
        _ =>
          'Supabase devolvió un error al preparar Cerna (HTTP ${error.status}).',
      });
    } on TimeoutException {
      cerrar('Supabase no respondió a tiempo al pedir el token de Cerna.');
    } catch (error) {
      debugPrint('Cerna: solicitud a Supabase fallida (${error.runtimeType}).');
      cerrar('No se pudo contactar con Supabase para iniciar Cerna.');
    }
    return null;
  }

  void enviarAudio(Uint8List pcm) {
    if (!lista || _fuente != null || _operaciones > 0 || pcm.isEmpty) return;
    _enviar({
      'realtimeInput': {
        'audio': {
          'data': base64Encode(pcm),
          'mimeType': 'audio/pcm;rate=16000',
        },
      },
    });
  }

  void _enviar(Map<String, Object?> paquete) {
    final socket = _socket;
    if (_cerrada || socket == null || socket.readyState != WebSocket.open)
      return;
    try {
      socket.add(jsonEncode(paquete));
    } catch (_) {
      cerrar('Se perdió la conexión con Gemini.');
    }
  }

  void _recibir(dynamic mensaje) {
    if (_cerrada) return;
    final texto = mensaje is String
        ? mensaje
        : utf8.decode(mensaje as List<int>);
    final datos = jsonDecode(texto) as Map<String, dynamic>;
    if (datos.containsKey('setupComplete')) {
      _lista = true;
      _reiniciarEspera();
      alConectar();
    }

    final cancelacion = datos['toolCallCancellation'];
    if (cancelacion is Map && cancelacion['ids'] is List) {
      for (final id in (cancelacion['ids'] as List).whereType<String>()) {
        _canceladas.add(id);
        alCancelarHerramienta(id);
      }
    }
    final llamada = datos['toolCall'];
    if (llamada is Map && llamada['functionCalls'] is List) {
      unawaited(_responderHerramientas(llamada['functionCalls'] as List));
    }

    final contenido = datos['serverContent'];
    if (contenido is! Map) return;
    if (contenido['interrupted'] == true) {
      _terminarAudio();
      _reiniciarEspera();
      return;
    }
    final turn = contenido['modelTurn'];
    if (turn is Map && turn['parts'] is List) {
      for (final parte in turn['parts'] as List) {
        final audio = parte is Map ? parte['inlineData'] : null;
        if (audio is Map &&
            (audio['mimeType']?.toString().startsWith('audio/pcm') ?? false) &&
            audio['data'] is String) {
          _reproducir(base64Decode(audio['data'] as String));
        }
      }
    }
    final transcripcion = contenido['outputTranscription'];
    if (transcripcion is Map && transcripcion['text'] is String) {
      _respuesta += transcripcion['text'] as String;
      alResponder(_respuesta);
    }
    final turnoCompleto = contenido['turnComplete'] == true;
    if (contenido['generationComplete'] == true || turnoCompleto) {
      final fuente = _fuente;
      if (fuente != null && !_turnoTerminado) {
        _turnoTerminado = true;
        _audio.setDataIsEnded(fuente);
      }
    }
    if (turnoCompleto) {
      _respuesta = '';
      _reiniciarEspera();
    }
  }

  Future<void> _responderHerramientas(List<dynamic> llamadas) async {
    _operaciones++;
    _espera?.cancel();
    final respuestas = <Map<String, Object?>>[];
    try {
      for (final llamada in llamadas.whereType<Map>()) {
        final id = llamada['id'];
        final nombre = llamada['name'];
        final args = llamada['args'];
        if (_cerrada ||
            id is! String ||
            nombre is! String ||
            _canceladas.contains(id)) {
          continue;
        }
        final respuesta = await acciones.ejecutar(
          nombre,
          args is Map ? Map<String, dynamic>.from(args) : {},
          id,
          () => !_cerrada && !_canceladas.contains(id),
        );
        if (!_cerrada && !_canceladas.contains(id)) {
          respuestas.add({'id': id, 'name': nombre, 'response': respuesta});
        }
      }
      if (respuestas.isNotEmpty) {
        _enviar({
          'toolResponse': {'functionResponses': respuestas},
        });
      }
    } finally {
      _operaciones--;
      _reiniciarEspera();
    }
  }

  void _reproducir(Uint8List pcm) {
    final fuente = _fuente;
    if (fuente != null) {
      _audio.addAudioDataStream(fuente, pcm);
      return;
    }
    _espera?.cancel();
    _turnoTerminado = false;
    final nueva = _audio.setBufferStream(
      sampleRate: 24000,
      bufferingTimeNeeds: .15,
      bufferingType: BufferingType.released,
      maxBufferSizeDuration: const Duration(seconds: 30),
    );
    _fuente = nueva;
    _audio.addAudioDataStream(nueva, pcm);
    final handle = _audio.play(nueva);
    _finAudio = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_turnoTerminado && !_audio.getIsValidVoiceHandle(handle)) {
        _terminarAudio();
        _reiniciarEspera();
      }
    });
  }

  void _terminarAudio() {
    _finAudio?.cancel();
    _finAudio = null;
    final fuente = _fuente;
    _fuente = null;
    if (fuente != null)
      unawaited(_audio.disposeSource(fuente).catchError((Object _) {}));
  }

  void _reiniciarEspera() {
    if (_cerrada || _operaciones > 0 || _fuente != null) return;
    _espera?.cancel();
    _espera = Timer(const Duration(seconds: 20), () => cerrar());
  }

  void cerrar([String? aviso]) {
    if (_cerrada) return;
    _cerrada = true;
    _espera?.cancel();
    _duracion?.cancel();
    _terminarAudio();
    final socket = _socket;
    if (socket != null) unawaited(socket.close());
    alTerminar(aviso);
  }
}
