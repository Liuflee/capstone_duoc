import 'package:frenos_cerna/features/ventas/data/carrito_de_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/formato_venta.dart';
import 'package:material_ui/material_ui.dart';

class CarritoVenta extends StatefulWidget {
  final List<LineaCarritoVenta> lineas;
  final bool habilitado;
  final VoidCallback buscarProductos;
  final void Function(LineaCarritoVenta, int) cambiarCantidad;
  final ValueChanged<LineaCarritoVenta> editarCantidad;

  const CarritoVenta({
    super.key,
    required this.lineas,
    required this.habilitado,
    required this.buscarProductos,
    required this.cambiarCantidad,
    required this.editarCantidad,
  });

  @override
  State<CarritoVenta> createState() => _CarritoVentaState();
}

class _CarritoVentaState extends State<CarritoVenta> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final lineas = widget.lineas;
    final visibles = lineas.where(
      (linea) => linea.producto.coincideCon(_busqueda),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Carrito', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: widget.habilitado ? widget.buscarProductos : null,
            icon: const Icon(Icons.add),
            label: const Text('Añadir productos'),
          ),
        ),
        const SizedBox(height: 12),
        if (lineas.isNotEmpty || _busqueda.isNotEmpty) ...[
          TextField(
            enabled: widget.habilitado,
            onChanged: (valor) =>
                setState(() => _busqueda = valor.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Buscar en el carrito',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (lineas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'El carrito está vacío. Añade los productos de la venta.',
            ),
          )
        else if (visibles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No hay productos que coincidan con la búsqueda.'),
          )
        else
          for (final linea in visibles) ...[
            const Divider(height: 1),
            _FilaCarrito(
              linea: linea,
              habilitado: widget.habilitado,
              cambiarCantidad: (cantidad) =>
                  widget.cambiarCantidad(linea, cantidad),
              editarCantidad: () => widget.editarCantidad(linea),
            ),
          ],
      ],
    );
  }
}

class _FilaCarrito extends StatelessWidget {
  final LineaCarritoVenta linea;
  final bool habilitado;
  final ValueChanged<int> cambiarCantidad;
  final VoidCallback editarCantidad;

  const _FilaCarrito({
    required this.linea,
    required this.habilitado,
    required this.cambiarCantidad,
    required this.editarCantidad,
  });

  @override
  Widget build(BuildContext context) {
    final (:producto, :cantidad) = linea;
    final texto = Theme.of(context).textTheme;
    final descripcion = [
      if (producto.nombre != producto.id) producto.id,
      producto.categoria,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(producto.nombre, style: texto.titleMedium),
                    Text(descripcion, style: texto.bodySmall),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar ${producto.nombre} del carrito',
                onPressed: habilitado ? () => cambiarCantidad(0) : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Disminuir cantidad de ${producto.nombre}',
                    onPressed: habilitado && cantidad > 1
                        ? () => cambiarCantidad(cantidad - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  TextButton(
                    onPressed: habilitado ? editarCantidad : null,
                    child: Text(
                      '$cantidad',
                      semanticsLabel: 'Editar cantidad: $cantidad',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Aumentar cantidad de ${producto.nombre}',
                    onPressed: habilitado && cantidad < producto.stock
                        ? () => cambiarCantidad(cantidad + 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Text(
                '${precioVenta(producto.precio)} c/u',
                style: texto.bodySmall,
              ),
              Text(
                'Subtotal ${precioVenta(producto.precio * cantidad)}',
                style: texto.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
