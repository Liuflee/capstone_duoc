import 'dart:math' show max;

import 'producto_venta.dart';

typedef LineaCarritoVenta = ({ProductoVenta producto, int cantidad});

class CarritoDeVenta {
  final _lineas = <String, LineaCarritoVenta>{};

  Iterable<LineaCarritoVenta> get lineas => _lineas.values;
  bool get isEmpty => _lineas.isEmpty;
  int get unidades => lineas.fold(0, (suma, linea) => suma + linea.cantidad);
  double get total => lineas.fold(
    0,
    (suma, linea) => suma + linea.producto.precio * linea.cantidad,
  );

  LineaCarritoVenta? operator [](String codigo) => _lineas[codigo];

  int disponibles(ProductoVenta producto) =>
      max(0, producto.stock - (_lineas[producto.id]?.cantidad ?? 0));

  bool agregar(ProductoVenta producto, int cantidad) {
    if (cantidad < 1 || cantidad > disponibles(producto)) return false;
    final anterior = _lineas[producto.id];
    _lineas[producto.id] = (
      producto: anterior == null
          ? producto
          : ProductoVenta(
              id: producto.id,
              nombre: producto.nombre,
              categoria: producto.categoria,
              precio: anterior.producto.precio,
              stock: producto.stock,
              sku: producto.sku,
            ),
      cantidad: (anterior?.cantidad ?? 0) + cantidad,
    );
    return true;
  }

  void restaurar(ProductoVenta producto, int cantidad) {
    if (cantidad < 1) return;
    final anterior = _lineas[producto.id];
    _lineas[producto.id] = (
      producto: anterior?.producto ?? producto,
      cantidad: (anterior?.cantidad ?? 0) + cantidad,
    );
  }

  void fijarCantidad(String codigo, int cantidad) {
    final linea = _lineas[codigo];
    if (linea == null || cantidad < 0) return;
    if (cantidad == 0) {
      _lineas.remove(codigo);
    } else if (cantidad <= linea.producto.stock || cantidad < linea.cantidad) {
      _lineas[codigo] = (producto: linea.producto, cantidad: cantidad);
    }
  }
}
