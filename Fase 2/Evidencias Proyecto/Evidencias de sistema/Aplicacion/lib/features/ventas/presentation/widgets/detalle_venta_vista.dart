import 'package:frenos_cerna/features/ventas/presentation/formato_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/panel_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/tema_venta.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
import 'package:frenos_cerna/shared/widgets/panel_filtros.dart';
import 'package:material_ui/material_ui.dart';

class LineaDetalleVenta {
  final String nombre;
  final String codigo;
  final String categoria;
  final String? unidades;
  final double subtotal;

  const LineaDetalleVenta({
    required this.nombre,
    required this.subtotal,
    this.codigo = '',
    this.categoria = '',
    this.unidades,
  });
}

class DetalleVentaVista extends StatefulWidget {
  final String titulo;
  final String estado;
  final double total;
  final String cliente;
  final String rut;
  final String vehiculo;
  final List<LineaDetalleVenta> lineas;
  final VoidCallback? verCliente;
  final String tituloLista;
  final Widget? estadoLista;
  final Widget? aviso;
  final List<Widget> acciones;
  final bool mostrarProgreso;
  final bool mostrarNavegacionMovil;

  const DetalleVentaVista({
    super.key,
    required this.titulo,
    required this.estado,
    required this.total,
    required this.cliente,
    required this.rut,
    required this.vehiculo,
    required this.lineas,
    required this.verCliente,
    this.tituloLista = 'Productos',
    this.estadoLista,
    this.aviso,
    this.acciones = const [],
    this.mostrarProgreso = false,
    this.mostrarNavegacionMovil = false,
  });

  @override
  State<DetalleVentaVista> createState() => _DetalleVentaVistaState();
}

class _DetalleVentaVistaState extends State<DetalleVentaVista> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conTeclado = MediaQuery.viewInsetsOf(context).bottom > 0;
    return EstructuraPagina(
      titulo: widget.titulo,
      activo: 'Ventas',
      mostrarVolver: true,
      mostrarNavegacionMovil: widget.mostrarNavegacionMovil,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: TemaVenta(
        child: LayoutBuilder(
          builder: (context, espacio) {
            final resumen = conTeclado
                ? null
                : _resumen(context, espacio.maxWidth);
            final resumenDesplazable = espacio.maxHeight < 350;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _detalle(
                    context,
                    espacio.maxWidth,
                    resumen: resumenDesplazable ? resumen : null,
                  ),
                ),
                if (!resumenDesplazable && resumen != null) resumen,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _detalle(BuildContext context, double ancho, {Widget? resumen}) {
    final productos = _productos(context);
    final cliente = _datosCliente(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.aviso case final aviso?) ...[
            aviso,
            const SizedBox(height: 12),
          ],
          if (ancho >= 840)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: productos),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: cliente),
              ],
            )
          else ...[
            cliente,
            const SizedBox(height: 12),
            productos,
          ],
          if (resumen != null) ...[const SizedBox(height: 12), resumen],
        ],
      ),
    );
  }

  Widget _datosCliente(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return PanelVenta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cliente y vehículo', style: texto.titleLarge),
          const SizedBox(height: 12),
          Text(widget.cliente, style: texto.titleMedium),
          if (widget.rut.isNotEmpty)
            Text('RUT ${widget.rut}', style: texto.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.directions_car_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.vehiculo)),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.verCliente,
            icon: const Icon(Icons.person_outline),
            label: const Text('Ver cliente'),
          ),
        ],
      ),
    );
  }

  Widget _productos(BuildContext context) {
    final filtro = normalizarFiltro(_busqueda.text.trim());
    final lineas = widget.lineas.where(
      (linea) => [
        linea.nombre,
        linea.codigo,
        linea.categoria,
        precioVenta(linea.subtotal),
      ].any((valor) => normalizarFiltro(valor).contains(filtro)),
    );
    return PanelVenta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.tituloLista,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (widget.estadoLista case final estado?)
            estado
          else ...[
            if (widget.lineas.isNotEmpty) ...[
              CampoBusqueda(
                controlador: _busqueda,
                textoAyuda: 'Buscar en la venta',
                alCambiar: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
            ],
            if (lineas.isEmpty)
              Text(
                widget.lineas.isEmpty
                    ? 'La venta no tiene artículos registrados.'
                    : 'No hay productos que coincidan.',
              ),
            for (final linea in lineas) ...[
              const Divider(height: 1),
              _FilaDetalleVenta(linea: linea),
            ],
          ],
        ],
      ),
    );
  }

  Widget _resumen(BuildContext context, double ancho) {
    final texto = Theme.of(context).textTheme;
    final total = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.estado, style: texto.labelLarge),
        Text('Total ${precioVenta(widget.total)}', style: texto.headlineSmall),
      ],
    );
    final acciones = Wrap(spacing: 8, runSpacing: 6, children: widget.acciones);
    return PanelVenta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.mostrarProgreso) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
          ],
          if (widget.acciones.isEmpty)
            total
          else if (ancho < 550)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [total, const SizedBox(height: 8), acciones],
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [total, acciones],
            ),
        ],
      ),
    );
  }
}

class _FilaDetalleVenta extends StatelessWidget {
  final LineaDetalleVenta linea;

  const _FilaDetalleVenta({required this.linea});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final datos = [
      if (linea.codigo.isNotEmpty && linea.codigo != linea.nombre) linea.codigo,
      if (linea.categoria.isNotEmpty) linea.categoria,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(linea.nombre, style: texto.titleMedium),
          if (datos.isNotEmpty) Text(datos, style: texto.bodySmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (linea.unidades case final unidades?)
                Text(unidades, style: texto.bodyMedium),
              Text(
                'Subtotal ${precioVenta(linea.subtotal)}',
                style: texto.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
