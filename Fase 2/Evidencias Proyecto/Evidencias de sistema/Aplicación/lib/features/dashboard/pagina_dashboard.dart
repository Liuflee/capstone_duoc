import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frenos_cerna/features/dashboard/data/dashboard_repository.dart';
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart';
import 'package:frenos_cerna/features/inventario/pagina_edicion_producto.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas_historial.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';

const _rojo = Color(0xFFCF5151);
const _tinta = Color(0xFF721919);

String _pesos(double valor) =>
    '\$${valor.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
String _fecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}';

class PaginaDashboard extends StatefulWidget {
  final Future<DatosDashboard> Function()? cargarDatos;
  final DateTime Function()? ahora;

  const PaginaDashboard({super.key, this.cargarDatos, this.ahora});

  @override
  State<PaginaDashboard> createState() => _PaginaDashboardState();
}

class _PaginaDashboardState extends State<PaginaDashboard> {
  late Future<DatosDashboard> _datos;
  late DateTime _actualizado;
  PeriodoDashboard _periodo = PeriodoDashboard.semana;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  void _consultar() {
    _actualizado = (widget.ahora ?? DateTime.now)();
    _datos = (widget.cargarDatos ?? const DashboardRepository().cargar)();
  }

  Future<void> _abrir(Widget pagina) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => pagina));
    if (mounted) setState(_consultar);
  }

  @override
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Dashboard',
    activo: 'Dashboard',
    padding: const EdgeInsets.all(24),
    child: FutureBuilder<DatosDashboard>(
      future: _datos,
      builder: (context, estado) {
        final cargando = estado.connectionState != ConnectionState.done;
        final datos = cargando
            ? const DatosDashboard()
            : estado.data ?? const DatosDashboard();
        final ventas = datos.ventasDelPeriodo(_periodo, _actualizado);
        final ingresos = ventas.fold<double>(
          0,
          (suma, venta) => suma + venta.total,
        );
        final sinFecha = (datos.ventas ?? [])
            .where((venta) => venta.fechaRegistro == null)
            .length;
        final criticos = datos.stockCritico;
        final fallos = [
          if (datos.ventas == null) 'ventas',
          if (datos.productos == null) 'inventario',
          if (datos.pendientes == null) 'pendientes',
        ];
        final indicadores = [
          _Indicador(
            titulo: 'INGRESOS DEL PERÍODO',
            valor: datos.ventas == null ? '—' : _pesos(ingresos),
            detalle: 'Ventas confirmadas · CLP',
            icono: Icons.attach_money,
            destacado: true,
          ),
          _Indicador(
            titulo: 'VENTAS CONFIRMADAS',
            valor: datos.ventas == null ? '—' : '${ventas.length}',
            detalle:
                'Promedio: ${datos.ventas == null ? '—' : _pesos(ventas.isEmpty ? 0 : ingresos / ventas.length)}',
            icono: Icons.receipt_long_outlined,
          ),
          _Indicador(
            titulo: 'POR COBRAR',
            valor: datos.pendientes == null
                ? '—'
                : _pesos(
                    datos.pendientes!.fold<double>(
                      0,
                      (suma, venta) => suma + venta.total,
                    ),
                  ),
            detalle:
                '${datos.pendientes?.length ?? '—'} pendientes en este dispositivo',
            icono: Icons.schedule_outlined,
          ),
          _Indicador(
            titulo: 'REPOSICIÓN DE STOCK',
            valor: datos.productos == null ? '—' : '${criticos.length}',
            detalle: 'Productos con 5 unidades o menos',
            icono: Icons.inventory_2_outlined,
          ),
        ];
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RESUMEN DEL NEGOCIO',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text('Ventas, cobros y disponibilidad de productos.'),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PeriodoDashboard.values
                        .map(
                          (periodo) => ChoiceChip(
                            label: Text(periodo.etiqueta),
                            selected: _periodo == periodo,
                            selectedColor: const Color(0xFFF7DCDC),
                            backgroundColor: const Color(0xFFF1F1F1),
                            labelStyle: const TextStyle(color: Colors.black),
                            onSelected: (_) =>
                                setState(() => _periodo = periodo),
                          ),
                        )
                        .toList(),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_fecha(_periodo.inicio(_actualizado))} – ${_fecha(_actualizado)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      IconButton(
                        tooltip: 'Actualizar dashboard',
                        onPressed: cargando ? null : () => setState(_consultar),
                        icon: const Icon(Icons.refresh, color: _tinta),
                      ),
                    ],
                  ),
                ],
              ),
              if (cargando) const LinearProgressIndicator(color: _rojo),
              if (!cargando && fallos.isNotEmpty)
                _Aviso(
                  texto:
                      'No se pudo cargar: ${fallos.join(', ')}. Pulsa actualizar para reintentar. Los valores no disponibles se muestran con —.',
                ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, limites) {
                  final columnas = limites.maxWidth >= 1050
                      ? 4
                      : limites.maxWidth >= 550
                      ? 2
                      : 1;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: indicadores
                        .map(
                          (indicador) => SizedBox(
                            width:
                                (limites.maxWidth - (columnas - 1) * 16) /
                                columnas,
                            child: indicador,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, limites) {
                  final grafico = _Panel(
                    titulo: 'INGRESOS POR DÍA',
                    subtitulo:
                        'Ventas confirmadas del período seleccionado · CLP',
                    child: datos.ventas == null
                        ? const _Vacio('Ingresos no disponibles.')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (ventas.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    'No hay ventas confirmadas en este período.',
                                  ),
                                ),
                              _GraficoIngresos(
                                datos: datos,
                                periodo: _periodo,
                                ahora: _actualizado,
                              ),
                            ],
                          ),
                  );
                  final stock = _Panel(
                    titulo: 'PRODUCTOS POR REPONER',
                    subtitulo:
                        'Prioridad: sin stock y luego stock bajo (1 a 5).',
                    accion: 'VER INVENTARIO',
                    alPresionar: () => _abrir(const PaginaInventario()),
                    child: datos.productos == null
                        ? const _Vacio('Inventario no disponible.')
                        : criticos.isEmpty
                        ? const _Vacio(
                            'No hay productos con stock crítico.',
                            icono: Icons.check_circle_outline,
                          )
                        : Column(
                            children: criticos
                                .take(4)
                                .map(
                                  (producto) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      producto.nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      producto.categoria,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      producto.cantidad <= 0
                                          ? 'SIN STOCK'
                                          : '${producto.cantidad} unid.',
                                      style: const TextStyle(
                                        color: _tinta,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onTap: () => _abrir(
                                      PaginaEdicionProducto(producto: producto),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  );
                  if (limites.maxWidth < 1000) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [grafico, const SizedBox(height: 20), stock],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: grafico),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: stock),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _Panel(
                titulo: 'ÚLTIMAS VENTAS DEL PERÍODO',
                subtitulo: 'Hasta 5 ventas confirmadas, ordenadas por fecha.',
                accion: 'VER HISTORIAL',
                alPresionar: () => _abrir(const PaginaVentasHistorial()),
                child: datos.ventas == null
                    ? const _Vacio('Ventas no disponibles.')
                    : ventas.isEmpty
                    ? const _Vacio('No hay ventas para mostrar.')
                    : Column(
                        children: ventas
                            .take(5)
                            .map(
                              (venta) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.receipt_long_outlined,
                                  color: _tinta,
                                ),
                                title: Text(
                                  venta.clienteNombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_fecha(venta.fechaRegistro!)} · ${venta.vehiculoNombre}',
                                ),
                                trailing: Text(
                                  _pesos(venta.total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () => _abrir(
                                  PaginaDetalleVenta(
                                    idVenta: venta.id,
                                    clienteNombre: venta.clienteNombre,
                                    vehiculoNombre: venta.vehiculoNombre,
                                    total: venta.total,
                                    ventaInicial: venta,
                                    desdeHistorial: true,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              if (sinFecha > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '$sinFecha ventas sin fecha registrada quedan fuera del período. Puedes consultarlas en el historial completo.',
                    style: const TextStyle(fontSize: 12, color: _tinta),
                  ),
                ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Stock y pendientes muestran el estado actual;\nno cambian con el período.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  CartaNavegacion.accion(
                    onPressed: () =>
                        _abrir(const PaginaVentas(mostrarHistorial: true)),
                    icon: const Icon(Icons.schedule),
                    label: const Text('VER VENTAS'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Indicador extends StatelessWidget {
  final String titulo, valor, detalle;
  final IconData icono;
  final bool destacado;
  const _Indicador({
    required this.titulo,
    required this.valor,
    required this.detalle,
    required this.icono,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: destacado ? const Color(0xFFF7DCDC) : const Color(0xFFF1F1F1),
      borderRadius: BorderRadius.circular(10),
      border: Border(
        top: BorderSide(
          color: destacado ? _rojo : const Color(0xFFBDBDBD),
          width: 4,
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: _tinta, size: 28),
        const SizedBox(height: 12),
        Text(
          titulo,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(detalle, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  final String titulo, subtitulo;
  final String? accion;
  final VoidCallback? alPresionar;
  final Widget child;
  const _Panel({
    required this.titulo,
    required this.subtitulo,
    required this.child,
    this.accion,
    this.alPresionar,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFD6D6D6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (accion != null)
              TextButton(
                onPressed: alPresionar,
                style: TextButton.styleFrom(foregroundColor: _tinta),
                child: Text(
                  accion!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitulo,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Material(color: Colors.white, child: child),
      ],
    ),
  );
}

class _GraficoIngresos extends StatelessWidget {
  final DatosDashboard datos;
  final PeriodoDashboard periodo;
  final DateTime ahora;
  const _GraficoIngresos({
    required this.datos,
    required this.periodo,
    required this.ahora,
  });

  @override
  Widget build(BuildContext context) {
    final inicio = periodo.inicio(ahora);
    final fechas = <DateTime>[];
    for (
      var dia = inicio;
      !dia.isAfter(DateTime(ahora.year, ahora.month, ahora.day));
      dia = DateTime(dia.year, dia.month, dia.day + 1)
    ) {
      fechas.add(dia);
    }
    final ventas = datos.ventasDelPeriodo(periodo, ahora);
    final totales = fechas
        .map(
          (dia) => ventas
              .where((venta) {
                final fecha = venta.fechaRegistro!.toLocal();
                return fecha.year == dia.year &&
                    fecha.month == dia.month &&
                    fecha.day == dia.day;
              })
              .fold<double>(0, (suma, venta) => suma + venta.total),
        )
        .toList();
    final maximo = totales.fold<double>(0, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Máximo diario: ${_pesos(maximo)}',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, limites) {
            final anchoDia = limites.maxWidth / fechas.length;
            final anchoEtiqueta =
                54.0 * MediaQuery.textScalerOf(context).scale(1);
            final paso = math.max(1, (anchoEtiqueta / anchoDia).ceil());
            // Todas las barras permanecen visibles; solo se espacian las fechas.
            final etiquetas = [
              for (var i = 0; i < fechas.length - 1; i += paso)
                if (i == 0 ||
                    (fechas.length - 1 - i) * anchoDia >= anchoEtiqueta)
                  i,
              fechas.length - 1,
            ];
            return Column(
              key: const ValueKey('grafico_ingresos'),
              children: [
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      fechas.length,
                      (i) => Expanded(
                        child: Semantics(
                          label: '${_fecha(fechas[i])}: ${_pesos(totales[i])}',
                          child: Tooltip(
                            message:
                                '${_fecha(fechas[i])} · ${_pesos(totales[i])}',
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                key: ValueKey(
                                  'ingresos_${fechas[i].toIso8601String()}',
                                ),
                                width: math.min(28, anchoDia * 0.6),
                                height: maximo == 0
                                    ? 2
                                    : math.max(2, totales[i] / maximo * 130),
                                decoration: BoxDecoration(
                                  color: totales[i] == 0
                                      ? const Color(0xFFD6D6D6)
                                      : _rojo,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 12 + MediaQuery.textScalerOf(context).scale(16),
                  child: Stack(
                    children: etiquetas
                        .map(
                          (i) => Positioned(
                            top: 8,
                            left: ((i + 0.5) * anchoDia - anchoEtiqueta / 2)
                                .clamp(
                                  0.0,
                                  math.max(
                                    0.0,
                                    limites.maxWidth - anchoEtiqueta,
                                  ),
                                ),
                            width: math.min(anchoEtiqueta, limites.maxWidth),
                            child: Text(
                              _fecha(fechas[i]),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Vacio extends StatelessWidget {
  final String texto;
  final IconData icono;
  const _Vacio(this.texto, {this.icono = Icons.info_outline});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        Icon(icono, color: Colors.black45, size: 32),
        const SizedBox(height: 12),
        Text(texto, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _Aviso extends StatelessWidget {
  final String texto;
  const _Aviso({required this.texto});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF7DCDC),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(texto, style: const TextStyle(color: _tinta)),
  );
}
