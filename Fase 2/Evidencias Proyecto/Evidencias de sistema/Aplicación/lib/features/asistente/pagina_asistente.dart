import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';

import 'asistente_repository.dart';
import 'clasificador_local.dart';
import 'consulta_voz.dart';
import 'modelos_dispositivo.dart';
import 'narrador_local.dart';
import 'voz_local.dart';

bool get asistenteVozDisponible =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

enum _Estado { listo, preparando, esperando, escuchando, consultando }

class PaginaAsistente extends StatelessWidget {
  const PaginaAsistente({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = asistenteVozDisponible && SupabaseDatabase.isConfigured
        ? SupabaseDatabase.client.auth.currentUser?.id
        : null;
    if (usuario != null) return _AsistenteMovil(usuarioId: usuario);
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente Cerna')),
      body: const Center(
        child: Text('Inicia sesión desde la app móvil para consultar por voz.'),
      ),
    );
  }
}

class _AsistenteMovil extends StatefulWidget {
  const _AsistenteMovil({required this.usuarioId});
  final String usuarioId;

  @override
  State<_AsistenteMovil> createState() => _AsistenteMovilState();
}

class _AsistenteMovilState extends State<_AsistenteMovil>
    with WidgetsBindingObserver {
  final _voz = VozLocal();
  final _clasificador = ClasificadorLocal();
  final _narrador = NarradorLocal();
  final _modelos = ModelosDispositivo.instancia;
  Future<void> _operacion = Future.value();
  var _estado = _Estado.listo;
  var _version = 0;
  var _modelosListos = false;
  var _continuo = false;
  Timer? _limite;
  Timer? _pausa;
  VoidCallback? _finalizar;
  double? _progreso;
  String? _mensaje;
  String? _pregunta;
  String? _tituloResultado;
  List<ProductoConsultado> _productos = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _operacion = _modelos
        .disponible()
        .then((disponible) {
          if (mounted) setState(() => _modelosListos = disponible);
        })
        .catchError((Object error) {
          debugPrint('No se pudo comprobar la caché: $error');
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.isCurrentOf(context) == false && _estado != _Estado.listo) {
      _detener();
    }
  }

  bool _vigente(int version) =>
      mounted &&
      version == _version &&
      SupabaseDatabase.client.auth.currentUser?.id == widget.usuarioId;

  void _ejecutar(Future<void> Function(int) accion) {
    final version = _version;
    _operacion = _operacion.then((_) async {
      if (!_vigente(version)) return;
      try {
        await accion(version);
      } catch (error, stack) {
        debugPrintStack(label: 'Asistente Cerna: $error', stackTrace: stack);
        if (!_vigente(version)) return;
        _cancelarTemporizadores();
        await _limpiarAudio();
        if (_vigente(version)) {
          setState(() {
            _estado = _Estado.listo;
            _progreso = null;
            _mensaje = error is StateError ? error.message : 'No pude completar la consulta. Revisa la conexión e inténtalo de nuevo.';
          });
        }
      }
    });
  }

  void _activar(bool porVoz) {
    setState(() {
      _estado = _Estado.preparando;
      _continuo = porVoz;
      _mensaje = null;
    });
    _ejecutar((version) async {
      if (!_modelosListos) {
        await _modelos.preparar((avance) {
          if (_vigente(version)) setState(() => _progreso = avance);
        });
        if (!_vigente(version)) return;
        setState(() {
          _modelosListos = true;
          _progreso = null;
        });
      }
      await _escuchar(version, esperarActivacion: porVoz);
    });
  }

  Future<void> _escuchar(int version, {required bool esperarActivacion}) async {
    if (!_vigente(version)) return;
    var ultima = '';
    var preguntaDetectada = '';
    var activado = !esperarActivacion;
    var finalizando = false;

    void finalizar() {
      if (!_vigente(version) || finalizando) return;
      finalizando = true;
      _cancelarTemporizadores();
      if (activado) setState(() => _estado = _Estado.consultando);
      _ejecutar((version) async {
        final finalWhisper = (await _voz.detener()).trim();
        if (!_vigente(version)) return;
        final texto = finalWhisper.isEmpty ? ultima : finalWhisper;
        final pregunta = esperarActivacion
            ? quitarActivacion(texto) ?? (activado ? preguntaDetectada : null)
            : quitarActivacion(texto) ?? texto;
        if (esperarActivacion && pregunta != null && pregunta.isEmpty) {
          await _escuchar(version, esperarActivacion: false);
          return;
        }
        if (pregunta != null) await _consultar(version, pregunta);
        if (!_vigente(version)) return;
        if (_continuo) {
          await _escuchar(version, esperarActivacion: true);
        } else {
          await _voz.liberarModelo();
          if (_vigente(version)) setState(() => _estado = _Estado.listo);
        }
      });
    }

    setState(() {
      _estado = esperarActivacion ? _Estado.esperando : _Estado.escuchando;
      _finalizar = finalizar;
    });
    await _voz.iniciar(
      vigente: () => _vigente(version),
      alTranscribir: (texto) {
        if (!_vigente(version) || finalizando || texto == ultima) return;
        ultima = texto;
        final pregunta = esperarActivacion ? quitarActivacion(texto) : texto;
        if (pregunta == null) return;
        preguntaDetectada = pregunta;
        if (!activado) {
          activado = true;
          setState(() {
            _estado = _Estado.escuchando;
            _mensaje = null;
          });
        }
        _pausa?.cancel();
        _pausa = Timer(
          Duration(milliseconds: pregunta.trim().isEmpty ? 2500 : 1600),
          finalizar,
        );
      },
      alFallar: (_) {
        if (!_vigente(version) || finalizando) return;
        finalizando = true;
        _ejecutar((_) async {
          throw StateError('Se interrumpió el micrófono. Actívalo nuevamente.');
        });
      },
    );
    if (_vigente(version) && !finalizando) {
      _limite = Timer(
        Duration(seconds: esperarActivacion ? 20 : 10),
        finalizar,
      );
    }
  }

  Future<void> _consultar(int version, String pregunta) async {
    setState(() {
      _estado = _Estado.consultando;
      _pregunta = pregunta;
      _tituloResultado = null;
      _productos = const [];
      _mensaje = null;
    });
    final categoria = await _clasificador.clasificar(pregunta);
    if (!_vigente(version)) return;
    if (categoria == null) {
      await _mostrarAyuda(
        version,
        'Prueba «Productos sin stock», «Stock del código ABC-123» o «¿Cuánto vendimos hoy?».',
        narrar: pregunta.isNotEmpty,
      );
      return;
    }
    const repositorio = AsistenteRepository();
    if (categoria == ConsultaVoz.ventas) {
      final periodo = PeriodoVentasVoz.desdeFrase(pregunta);
      if (periodo == null) {
        await _mostrarAyuda(
          version,
          'Indica si quieres las ventas de hoy o las de este mes.',
        );
        return;
      }
      final ventas = await repositorio.consultarVentas(
        periodo,
        widget.usuarioId,
      );
      if (!_vigente(version)) return;
      final importe = ventas.total.round();
      final monto = importe.toString().replaceAllMapped(
        RegExp(r'\d(?=(\d{3})+$)'),
        (coincidencia) => '${coincidencia[0]}.',
      );
      final cantidad = ventas.cantidad == 1
          ? 'Una venta'
          : '${ventas.cantidad} ventas';
      final resumen = '$cantidad por un total de CLP $monto.';
      setState(() {
        _tituloResultado = 'Ventas ${periodo.etiqueta}';
        _mensaje = resumen;
      });
      await _narrar(
        version,
        resumen,
        const [],
        textoHablado: '$cantidad por un total de $importe pesos chilenos.',
      );
      return;
    }
    if (categoria == ConsultaVoz.stockPorCodigo) {
      final codigo = codigoProductoDesdeFrase(pregunta);
      if (codigo == null) {
        await _mostrarAyuda(
          version,
          'Indica un solo código. Por ejemplo, «stock del código ABC guion uno dos tres».',
        );
        return;
      }
      final producto = await repositorio.consultarCodigo(
        codigo,
        widget.usuarioId,
      );
      if (!_vigente(version)) return;
      final resumen = producto == null
          ? 'No encontré el código $codigo.'
          : 'El producto ${producto.codigo} tiene ${producto.stock} ${producto.stock == 1 ? 'unidad disponible' : 'unidades disponibles'}.';
      setState(() {
        _tituloResultado = categoria.titulo;
        _productos = producto == null ? const [] : [producto];
        _mensaje = resumen;
      });
      await _narrar(version, resumen, const []);
      return;
    }
    final productos = await repositorio.consultar(categoria, widget.usuarioId);
    if (!_vigente(version)) return;
    final condicion = categoria == ConsultaVoz.sinStock
        ? 'sin stock'
        : 'con stock bajo';
    final resumen = switch (productos.length) {
      0 => 'No hay productos $condicion.',
      1 => 'Encontré un producto $condicion.',
      final cantidad => 'Encontré $cantidad productos $condicion.',
    };
    setState(() {
      _tituloResultado = categoria.titulo;
      _productos = productos;
      _mensaje = resumen;
    });
    await _narrar(
      version,
      resumen,
      productos.map((producto) {
        final tipo = producto.tipo.isEmpty ? 'Producto' : producto.tipo;
        final unidades = categoria == ConsultaVoz.stockBajo
            ? ', stock ${producto.stock}'
            : '';
        return '$tipo, código ${producto.codigo}$unidades.';
      }),
    );
  }

  Future<void> _mostrarAyuda(
    int version,
    String ayuda, {
    bool narrar = true,
  }) async {
    setState(() => _mensaje = ayuda);
    if (narrar) await _narrar(version, ayuda, const []);
  }

  Future<void> _narrar(
    int version,
    String resumen,
    Iterable<String> productos, {
    String? textoHablado,
  }) async {
    var narrado = false;
    try {
      narrado = await _narrador.narrar(
        textoHablado ?? resumen,
        productos,
        vigente: () => _vigente(version),
      );
    } catch (error) {
      debugPrint('Error del narrador: $error');
    }
    if (!narrado && _vigente(version)) {
      setState(
        () => _mensaje =
            '$resumen Para oír la respuesta, revisa la voz en español instalada en el dispositivo.',
      );
    }
  }

  void _cancelarTemporizadores() {
    _limite?.cancel();
    _pausa?.cancel();
    _finalizar = null;
  }

  Future<void> _limpiarAudio() async {
    try {
      await _voz.detener();
      await _voz.liberarModelo();
    } catch (error) {
      debugPrint('No se pudo cerrar el audio: $error');
    }
  }

  void _detener() {
    ++_version;
    _cancelarTemporizadores();
    unawaited(_narrador.detener().catchError((Object _) {}));
    _operacion = _operacion.then((_) => _limpiarAudio());
    setState(() {
      _estado = _Estado.listo;
      _progreso = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if ((estado == AppLifecycleState.hidden ||
            estado == AppLifecycleState.paused ||
            estado == AppLifecycleState.detached) &&
        _estado != _Estado.listo) {
      _detener();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_version;
    _cancelarTemporizadores();
    unawaited(_narrador.detener().catchError((Object _) {}));
    unawaited(
      _operacion
          .whenComplete(() async {
            try {
              await _voz.dispose();
            } finally {
              await _clasificador.dispose();
            }
          })
          .catchError((Object error) {
            debugPrint('No se pudo cerrar el asistente: $error');
          }),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PaginaTematica(builder: _pagina);

  Widget _pagina(BuildContext context) {
    final paleta = PaletaTaller.de(context);
    final estado = switch (_estado) {
      _Estado.listo =>
        _modelosListos ? 'Listo para escuchar' : 'Descarga inicial de 205 MB',
      _Estado.preparando => 'Preparando modelos en el dispositivo…',
      _Estado.esperando => 'Di «Hey Cerna» u «Oye Cerna»',
      _Estado.escuchando => 'Escuchando tu consulta…',
      _Estado.consultando => 'Procesando la consulta…',
    };
    return EstructuraPagina(
      titulo: 'Asistente Cerna',
      activo: 'Asistente Cerna',
      child: ListView.builder(
        itemCount: 1 + _productos.length,
        itemBuilder: (context, indice) {
          if (indice > 0) {
            final producto = _productos[indice - 1];
            return ListTile(
              title: Text(producto.codigo),
              subtitle: producto.tipo.isEmpty ? null : Text(producto.tipo),
              trailing: Text('${producto.stock} u.'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: paleta.tarjeta,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estado,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Consulta productos sin stock, stock bajo, stock por código o ventas de hoy y del mes.',
                      ),
                      if (_estado == _Estado.preparando) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _progreso,
                          color: paleta.acento,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_estado == _Estado.listo) ...[
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: paleta.acento,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _activar(false),
                              icon: const Icon(Icons.mic),
                              label: const Text('Hablar ahora'),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: paleta.oscura
                                    ? paleta.texto
                                    : paleta.acento,
                              ),
                              onPressed: () => _activar(true),
                              icon: const Icon(Icons.hearing),
                              label: const Text('Escuchar «Oye Cerna»'),
                            ),
                          ] else ...[
                            if (_estado == _Estado.escuchando)
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: paleta.acento,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _finalizar,
                                child: const Text('Terminé de hablar'),
                              ),
                            OutlinedButton.icon(
                              onPressed: _detener,
                              icon: const Icon(Icons.stop),
                              label: const Text('Detener'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_pregunta?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Text('Dijiste «$_pregunta»'),
              ],
              if (_tituloResultado case final titulo?) ...[
                const SizedBox(height: 12),
                Text(titulo, style: Theme.of(context).textTheme.titleLarge),
              ],
              if (_mensaje case final mensaje?)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(mensaje),
                ),
            ],
          );
        },
      ),
    );
  }
}
