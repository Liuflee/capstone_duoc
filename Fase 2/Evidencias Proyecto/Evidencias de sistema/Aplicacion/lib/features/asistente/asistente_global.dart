import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:frenos_cerna/core/navigation/dimensiones_navegacion.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vosk_flutter_fixed/vosk_flutter.dart';

import 'acciones_cerna.dart';
import 'sesion_gemini_live.dart';

class AsistenteGlobal extends StatefulWidget {
  const AsistenteGlobal({super.key, required this.paleta, required this.child});

  static bool get disponible =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  final PaletaTaller paleta;
  final Widget child;

  @override
  State<AsistenteGlobal> createState() => _AsistenteGlobalState();
}

class _AsistenteGlobalState extends State<AsistenteGlobal>
    with WidgetsBindingObserver {
  static const _frecuencia = 16000;
  static const _frases = [
    'oye cerna',
    'oye serna',
    'hey cerna',
    'hey serna',
    'ey cerna',
    'ey serna',
  ];
  static const _modeloUrl =
      'https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip';

  AudioRecorder? _grabador;
  final _previo = Queue<Uint8List>();
  final _esperandoConexion = Queue<Uint8List>();
  StreamSubscription<AuthState>? _auth;
  StreamSubscription<Uint8List>? _microfono;
  Future<void> _ajusteMicrofono = Future.value();
  Future<void>? _deteccion;
  Future<void>? _cargaModelo;
  Model? _modelo;
  Recognizer? _detector;
  SesionGeminiLive? _sesion;
  ({VentaPendiente venta, String id, Completer<bool> decision})? _confirmacion;
  String? _usuario, _aviso, _resultado;
  bool _primerPlano = true;
  bool _pausada = false;
  bool _terminando = false;
  bool _cargando = false;
  int _bytesPrevios = 0;
  int _bytesConexion = 0;

  bool get _escuchar =>
      !_terminando && _primerPlano && !_pausada && _usuario != null;

  @override
  void initState() {
    super.initState();
    if (!AsistenteGlobal.disponible || !SupabaseDatabase.isConfigured) return;
    WidgetsBinding.instance.addObserver(this);
    final cliente = SupabaseDatabase.client;
    _usuario = cliente.auth.currentUser?.id;
    _auth = cliente.auth.onAuthStateChange.listen((estado) {
      final usuario = estado.session?.user.id;
      if (!mounted ||
          _terminando ||
          (usuario == null && estado.event != AuthChangeEvent.signedOut) ||
          usuario == _usuario) {
        return;
      }
      _sesion?.cerrar();
      _limpiarAudio();
      setState(() {
        _usuario = usuario;
        _pausada = false;
        _aviso = null;
        _resultado = null;
      });
      _ajustarMicrofono(reiniciar: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ajustarMicrofono();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) return;
    _primerPlano = state == AppLifecycleState.resumed;
    if (!_primerPlano) {
      _sesion?.cerrar();
      _limpiarAudio();
    }
    _ajustarMicrofono(reiniciar: !_primerPlano);
  }

  void _ajustarMicrofono({bool reiniciar = false}) {
    _ajusteMicrofono = _ajusteMicrofono.then((_) async {
      try {
        if (reiniciar || !_escuchar) await _detenerMicrofono();
        if (!_escuchar || _microfono != null) return;
        _estado(() => _cargando = true);
        final grabador = _grabador ??= AudioRecorder();
        if (!await grabador.hasPermission()) {
          _estado(() => _aviso = 'Permite el micrófono para usar Cerna.');
          return;
        }
        if (!_escuchar) return;
        final audio = await grabador.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _frecuencia,
            numChannels: 1,
            echoCancel: true,
            noiseSuppress: true,
            streamBufferSize: 3200,
          ),
        );
        if (!_escuchar) {
          await grabador.stop();
          return;
        }
        _microfono = audio.listen(
          _recibirAudio,
          onError: (Object _) => _falloMicrofono(),
          onDone: _falloMicrofono,
        );
        _estado(() => _aviso = null);
        if (_detector == null) {
          _cargaModelo ??= _cargarDetector().whenComplete(
            () => _cargaModelo = null,
          );
        }
      } catch (_) {
        _estado(() => _aviso = 'No se pudo iniciar el micrófono de Cerna.');
      } finally {
        _estado(() => _cargando = false);
      }
    });
  }

  void _falloMicrofono() {
    _sesion?.cerrar();
    _estado(() {
      _pausada = true;
      _aviso = 'El micrófono se desconectó. Pulsa para reintentar.';
    });
    _ajustarMicrofono(reiniciar: true);
  }

  Future<void> _detenerMicrofono() async {
    final anterior = _microfono;
    _microfono = null;
    if (anterior != null) {
      await anterior.cancel();
      await _grabador?.stop();
    }
    _limpiarAudio();
  }

  Future<void> _cargarDetector() async {
    try {
      final vosk = VoskFlutterPlugin.instance();
      final ruta = await ModelLoader().loadFromNetwork(_modeloUrl);
      if (_terminando) return;
      _modelo ??= await vosk.createModel(ruta);
      _detector = await vosk.createRecognizer(
        model: _modelo!,
        sampleRate: _frecuencia,
        grammar: [..._frases, '[unk]'],
      );
      _estado(() {});
    } catch (_) {
      _estado(
        () => _aviso = 'La activación por voz no está disponible. Puedes abrir Cerna con el micrófono.',
      );
    }
  }

  void _recibirAudio(Uint8List pcm) {
    if (!_escuchar) return;
    final sesion = _sesion;
    if (sesion != null) {
      if (sesion.lista) {
        sesion.enviarAudio(pcm);
      } else {
        _esperandoConexion.add(pcm);
        _bytesConexion += pcm.length;
        while (_bytesConexion > _frecuencia * 2 * 12) {
          _bytesConexion -= _esperandoConexion.removeFirst().length;
        }
      }
      return;
    }
    _previo.add(pcm);
    _bytesPrevios += pcm.length;
    while (_bytesPrevios > _frecuencia * 2 * 2) {
      _bytesPrevios -= _previo.removeFirst().length;
    }
    final detector = _detector;
    if (detector != null && _deteccion == null) {
      _deteccion = _detectar(
        detector,
        pcm,
      ).whenComplete(() => _deteccion = null);
    }
  }

  Future<void> _detectar(Recognizer detector, Uint8List pcm) async {
    final usuario = _usuario;
    try {
      final completo = await detector.acceptWaveformBytes(pcm);
      final datos = jsonDecode(
        completo
            ? await detector.getResult()
            : await detector.getPartialResult(),
      ) as Map<String, dynamic>;
      final texto = datos[completo ? 'text' : 'partial'];
      if (texto is! String) return;
      final frase = texto.trim().toLowerCase();
      if (_frases.any(
        (clave) => frase == clave || frase.startsWith('$clave '),
      )) {
        await detector.reset();
        if (_escuchar && _usuario == usuario && _sesion == null) {
          _activar(incluirAudioPrevio: true);
        }
      }
    } catch (_) {
      _detector = null;
      try {
        await detector.dispose();
      } finally {
        _estado(
          () => _aviso =
              'Falló la activación por voz. Pulsa el micrófono para hablar.',
        );
      }
    }
  }

  void _activar({bool incluirAudioPrevio = false}) {
    final usuario = _usuario;
    if (usuario == null || !_escuchar || _microfono == null || _sesion != null)
      return;
    if (incluirAudioPrevio) {
      _esperandoConexion.addAll(_previo);
      _bytesConexion = _bytesPrevios;
    }
    _previo.clear();
    _bytesPrevios = 0;
    final sesion = SesionGeminiLive(
      acciones: AccionesCerna(usuario, _pedirConfirmacion),
      alConectar: () {
        final sesion = _sesion;
        while (_esperandoConexion.isNotEmpty &&
            sesion != null &&
            sesion.lista) {
          sesion.enviarAudio(_esperandoConexion.removeFirst());
        }
        _limpiarAudio();
        _estado(() {});
      },
      alResponder: (respuesta) => _estado(() => _resultado = respuesta),
      alCancelarHerramienta: (id) {
        if (_confirmacion?.id == id) _decidir(false);
      },
      alTerminar: (aviso) {
        _decidir(false);
        _limpiarAudio();
        _sesion = null;
        _estado(() => _aviso = aviso);
      },
    );
    _estado(() {
      _sesion = sesion;
      _aviso = null;
      _resultado = null;
    });
    unawaited(sesion.conectar());
  }

  Future<bool> _pedirConfirmacion(VentaPendiente venta, String id) {
    if (!mounted || !_escuchar || _sesion == null || _confirmacion != null) {
      return Future.value(false);
    }
    final decision = Completer<bool>();
    _estado(() => _confirmacion = (venta: venta, id: id, decision: decision));
    return decision.future;
  }

  void _decidir(bool guardar) {
    final confirmacion = _confirmacion;
    if (confirmacion == null) return;
    _confirmacion = null;
    confirmacion.decision.complete(guardar);
    _estado(() {});
  }

  void _limpiarAudio() {
    _previo.clear();
    _esperandoConexion.clear();
    _bytesPrevios = 0;
    _bytesConexion = 0;
  }

  void _estado(VoidCallback actualizar) {
    if (mounted && !_terminando) setState(actualizar);
  }

  void _alternarEscucha() {
    _sesion?.cerrar();
    _estado(() {
      _pausada = !_pausada;
      _aviso = null;
      _resultado = null;
    });
    _ajustarMicrofono(reiniciar: _pausada);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _terminando = true;
    unawaited(_auth?.cancel());
    _sesion?.cerrar();
    unawaited(
      _ajusteMicrofono
          .then((_) async {
            try {
              await _detenerMicrofono();
              await _deteccion;
              await _cargaModelo;
              await _detector?.dispose();
              _modelo?.dispose();
            } finally {
              await _grabador?.dispose();
            }
          })
          .catchError((Object _) {}),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AsistenteGlobal.disponible || _usuario == null) return widget.child;
    final paleta = widget.paleta;
    final superficie = paleta.oscura ? paleta.tarjeta : paleta.fondo;
    final sobreAcento = paleta.acento.computeLuminance() > 0.179
        ? Colors.black
        : Colors.white;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: paleta.borde),
    );
    final escuchaActiva = !_pausada && _microfono != null;
    final sesion = _sesion;
    final venta = _confirmacion?.venta;
    final mensaje =
        _aviso ??
        _resultado ??
        (sesion == null
            ? null
            : sesion.lista
            ? 'Te escucho…'
            : 'Conectando con Cerna…');
    final descripcion = _pausada
        ? 'Reanudar escucha de Cerna'
        : _cargando
        ? 'Preparando micrófono de Cerna'
        : sesion != null
        ? 'Cerrar conversación con Cerna'
        : _microfono == null
        ? 'Activar micrófono de Cerna'
        : _detector == null
        ? 'Hablar con Cerna'
        : 'Hablar con Cerna · Oye Cerna / Hey Cerna';
    final margenInferior =
        MediaQuery.paddingOf(context).bottom +
        (DimensionesNavegacion.usaBarraInferior(context)
            ? DimensionesNavegacion.altoBarraInferior
            : 0);
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 12,
          bottom: margenInferior + 12,
          child: Material(
            color: superficie,
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            shape: forma,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BotonCerna(
                    etiqueta: descripcion,
                    color: escuchaActiva ? sobreAcento : paleta.texto,
                    fondo: escuchaActiva ? paleta.acento : null,
                    icon: Icon(
                      _pausada
                          ? Icons.mic_off_outlined
                          : sesion != null
                          ? Icons.close
                          : Icons.mic_none,
                    ),
                    onPressed: _cargando
                        ? null
                        : () {
                            if (_pausada) {
                              _alternarEscucha();
                            } else if (_sesion != null) {
                              _sesion!.cerrar();
                            } else if (_microfono == null) {
                              _ajustarMicrofono();
                            } else {
                              if (_detector == null && _cargaModelo == null) {
                                _cargaModelo = _cargarDetector().whenComplete(
                                  () => _cargaModelo = null,
                                );
                              }
                              _activar();
                            }
                          },
                  ),
                  if (!_pausada && (_microfono != null || _cargando))
                    _BotonCerna(
                      etiqueta: 'Pausar escucha de Cerna',
                      color: paleta.texto,
                      onPressed: _alternarEscucha,
                      icon: const Icon(Icons.pause, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (mensaje != null || venta != null)
          Positioned(
            bottom: margenInferior + 68,
            right: 12,
            width: (MediaQuery.sizeOf(context).width - 24)
                .clamp(0.0, 360.0)
                .toDouble(),
            child: Material(
              color: superficie,
              surfaceTintColor: Colors.transparent,
              textStyle: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: paleta.texto),
              elevation: 6,
              shape: forma,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 10, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Cerna',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _BotonCerna(
                          etiqueta: 'Cerrar aviso de Cerna',
                          color: paleta.texto,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _sesion?.cerrar();
                            _estado(() {
                              _aviso = null;
                              _resultado = null;
                            });
                          },
                        ),
                      ],
                    ),
                    if (venta == null)
                      Text(
                        mensaje!,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (venta != null) ...[
                      Text(
                        '¿Guardar venta pendiente para ${venta.nombreCliente}?',
                      ),
                      if (venta.patente.isNotEmpty)
                        Text('Patente ${venta.patente}'),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: SingleChildScrollView(
                          child: Text(
                            venta.articulos
                                .map((a) => '${a.cantidad} × ${a.codigo}')
                                .join('\n'),
                          ),
                        ),
                      ),
                      Text('Total: ${venta.total.toStringAsFixed(0)} CLP'),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: paleta.texto,
                            ),
                            onPressed: () => _decidir(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: paleta.acento,
                              foregroundColor: sobreAcento,
                            ),
                            onPressed: () => _decidir(true),
                            child: const Text('Guardar pendiente'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Los controles globales se crean por encima del Navigator. Semantics les da
// un nombre accesible sin depender del Overlay que usa el tooltip de Material.
class _BotonCerna extends StatelessWidget {
  const _BotonCerna({
    required this.etiqueta,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.fondo,
  });

  final String etiqueta;
  final Icon icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color? fondo;

  @override
  Widget build(BuildContext context) => Semantics(
    label: etiqueta,
    child: IconButton(
      style: IconButton.styleFrom(
        foregroundColor: color,
        backgroundColor: fondo,
      ),
      icon: icon,
      onPressed: onPressed,
    ),
  );
}
