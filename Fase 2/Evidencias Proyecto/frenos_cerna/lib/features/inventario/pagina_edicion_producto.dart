import 'package:flutter/material.dart'; // Construye el acceso al formulario de edición.
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart'; // Recibe el producto seleccionado en la tabla.
import 'package:frenos_cerna/features/inventario/pagina_crear_producto.dart'; // Reutiliza exactamente el formulario de Añadir producto.

class PaginaEdicionProducto extends StatelessWidget {
  final Producto producto; // Conserva la identidad y los datos existentes.
  final Future<Map<String, List<Map<String, dynamic>>>> Function()?
  cargarCatalogos; // Permite verificar las selecciones sin modificar la base.
  const PaginaEdicionProducto({
    super.key,
    required this.producto,
    this.cargarCatalogos,
  }); // Mantiene las llamadas existentes desde Inventario.
  @override
  Widget build(BuildContext context) => PaginaCrearProducto(
    cargarCatalogos: cargarCatalogos, // Conserva la carga habitual de categorías y calidades.
    productoInicial: {
      'codigo_producto': producto
          .id, // Muestra el código sin modificar las referencias de ventas.
      'cod_barra':
          producto.codigoBarra, // Muestra el código de barras al final.
      'precio': producto.precio.toStringAsFixed(
        0,
      ), // Respeta el precio entero del esquema.
      'stock': producto.cantidad, // Precarga la cantidad actual.
      'tipo': producto.tipoId, // Precarga la categoría seleccionada.
      'calidad': producto.calidadId, // Precarga la calidad correspondiente.
      'nombre_tipo': producto
          .categoria, // Conserva el nombre mientras se consulta el catálogo.
    }, // La edición guarda cambios sobre este registro y no ofrece eliminar.
  );
}
