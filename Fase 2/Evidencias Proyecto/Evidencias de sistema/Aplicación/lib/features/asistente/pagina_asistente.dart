import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';

import 'asistente_repository.dart';
import 'consulta_voz.dart';
import 'voz_local.dart';
import 'clasificador_local.dart';
import 'modelos_dispositivo.dart';

class PaginaAsistente extends StatefulWidget {
  const PaginaAsistente({super.key});

  @override
  State<PaginaAsistente> createState() => _PaginaAsistenteState();
}

class _PaginaAsistenteState extends State<PaginaAsistente>
    with WidgetsBindingObserver {
  final _texto = TextEditingController();
  final _voz = VozLocal();
  final _datos = AsistenteRepository();
  final _clasificador = ClasificadorLocal();
  bool _iaLista = false;
  double? _descarga;
  bool _grabando = false;
  bool _ocupado = false;
  String? _aviso;
  ResultadoConsultaVoz? _resultado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ModelosDispositivo.instancia.disponible().then((lista) {
      if (mounted) setState(() => _iaLista = lista);
    });
  }

  Future<void> _prepararIa() async {
    setState(() {
      _ocupado = true;
      _descarga = 0;
      _aviso = null;
    });
    try {
      await ModelosDispositivo.instancia.preparar((avance) {
        if (mounted) setState(() => _descarga = avance);
      });
      if (mounted) {
        setState(() {
          _iaLista = true;
          _aviso = 'IA preparada. Ya puedes hablar o escribir tu consulta.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _aviso = error is StateError ? error.message.toString() : 'No se pudo descargar la IA. Revisa tu conexión y el espacio disponible.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _ocupado = false;
          _descarga = null;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (_grabando && estado == AppLifecycleState.paused) {
      _voz.cancelar();
      setState(() {
        _grabando = false;
        _aviso = 'Grabación cancelada al salir de la aplicación.';
      });
    }
  }

  Future<void> _microfono() async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _aviso = null;
      _resultado = null;
    });
    try {
      if (_grabando) {
        setState(() => _grabando = false);
        final texto = await _voz.detenerYTranscribir();
        if (mounted) _texto.text = texto;
      } else {
        await _voz.iniciar(() {
          if (mounted) _microfono();
        });
        if (mounted) setState(() => _grabando = true);
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _aviso = 'El reconocimiento tardó demasiado. Prueba una pregunta más corta.',
        );
      }
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => _aviso = 'Esta versión abierta necesita reiniciarse. Cierra la aplicación y abre la compilación actualizada para usar la voz.',
        );
      }
    } catch (error) {
      try {
        await _voz.cancelar();
      } catch (_) {
        /* Conserva el error original. */
      }
      if (mounted) {
        setState(() {
          _grabando = false;
          _aviso = error is StateError ? error.message.toString() : 'No se pudo reconocer la voz en este dispositivo. Repite la grabación.';
        });
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _consultar() async {
    var consultandoDatos = false;
    setState(() {
      _ocupado = true;
      _aviso = null;
      _resultado = null;
    });
    try {
      final texto = _texto.text.trim();
      final clasificacion = await _clasificador.clasificar(texto);
      final consulta = ConsultaVoz.desdeCategoria(
        texto,
        clasificacion.categoria,
      );
      consultandoDatos = true;
      final resultado = await _datos.consultar(consulta);
      if (mounted) setState(() => _resultado = resultado);
    } on FormatException catch (error) {
      if (mounted) setState(() => _aviso = error.message);
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => _aviso = 'Esta versión abierta necesita reiniciarse. Cierra la aplicación y abre la compilación actualizada para interpretar la pregunta.',
        );
      }
    } on PostgrestException catch (error) {
      debugPrint('Consulta del asistente: ${error.code}: ${error.message}');
      if (mounted) {
        setState(
          () => _aviso =
              'Supabase rechazó la consulta (${error.code ?? 'sin código'}). Comprueba los permisos y las migraciones de la base de datos.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _aviso = error is StateError
              ? error.message.toString()
              : consultandoDatos
              ? 'No se pudo conectar con la base de datos. Comprueba tu conexión a internet.'
              : 'No se pudo iniciar la interpretación local. Reinicia la aplicación y comprueba que la IA esté descargada.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voz.dispose();
    _clasificador.dispose();
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Consultas por voz',
    activo: 'Asistente',
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pregunta por el inventario o las ventas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (!_iaLista)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descarga la IA una vez (unos 205 MB). Después, la voz y la interpretación funcionan en este dispositivo sin depender de un computador. Usa Wi‑Fi para la descarga.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _ocupado ? null : _prepararIa,
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar IA en este dispositivo'),
                    ),
                    if (_descarga != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _descarga),
                      Text('${(_descarga! * 100).round()} %'),
                    ],
                  ],
                ),
              ),
            ),
          const Text(
            'Presiona el micrófono, habla y detén la grabación. Revisa el texto antes de consultar. Máximo 30 segundos.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ejemplo in [
                'Productos con stock bajo',
                'Stock del producto ABC-123',
                'Ventas de hoy',
                'Ventas de ayer',
                'Ventas de esta semana',
                'Ventas de este mes',
              ])
                ActionChip(
                  label: Text(ejemplo),
                  onPressed: _ocupado || _grabando
                      ? null
                      : () {
                          setState(() {
                            _texto.text = ejemplo;
                            _resultado = null;
                            _aviso = null;
                          });
                        },
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _texto,
            enabled: !_ocupado && !_grabando,
            minLines: 2,
            maxLines: 4,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Tu consulta',
              hintText: 'También puedes escribir tu pregunta',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {
              _resultado = null;
              _aviso = null;
            }),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _ocupado || !_iaLista ? null : _microfono,
                icon: Icon(_grabando ? Icons.stop : Icons.mic),
                label: Text(_grabando ? 'Detener y transcribir' : 'Hablar'),
              ),
              FilledButton.icon(
                onPressed:
                    _ocupado ||
                        _grabando ||
                        !_iaLista ||
                        _texto.text.trim().isEmpty
                    ? null
                    : _consultar,
                icon: const Icon(Icons.search),
                label: const Text('Consultar'),
              ),
            ],
          ),
          if (_grabando)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Grabando… Presiona detener cuando termines.'),
            ),
          if (_ocupado)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
          if (_aviso != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Semantics(liveRegion: true, child: Text(_aviso!)),
            ),
          if (_resultado != null) ...[
            const SizedBox(height: 24),
            Semantics(
              liveRegion: true,
              child: SelectableText(_resultado!.resumen),
            ),
            if (_resultado!.filas.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: _resultado!.columnas
                      .map((titulo) => DataColumn(label: Text(titulo)))
                      .toList(),
                  rows: _resultado!.filas
                      .map(
                        (fila) => DataRow(
                          cells: fila
                              .map((valor) => DataCell(SelectableText(valor)))
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Whisper y MiniLM procesan el audio y el texto en este dispositivo. El audio temporal se elimina al terminar. Para consultar Supabase necesitas internet y una sesión iniciada. Las consultas son de solo lectura y respetan tus permisos.',
          ),
        ],
      ),
    ),
  );
}
