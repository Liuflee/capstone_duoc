class ProductoVenta {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final String sku;

  const ProductoVenta({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    this.sku = '',
  });

  factory ProductoVenta.fromJson(Map<String, dynamic> json) {
    final codigo = json['codigo_producto']?.toString() ?? 'sin-codigo';
    final codigoBarra = json['cod_barra']?.toString() ?? '';
    final tipo = json['tipo_producto'];

    return ProductoVenta(
      id: codigo,
      nombre: codigoBarra.isEmpty ? codigo : codigoBarra,
      sku: json['sku']?.toString() ?? '',
      categoria: tipo is Map
          ? (tipo['nombre_tipo'] ?? 'Sin categoría').toString()
          : (json['tipo']?.toString() ?? 'Sin categoría'),
      precio: double.tryParse(json['precio']?.toString() ?? '') ?? 0,
      stock: int.tryParse(json['stock']?.toString() ?? '') ?? 0,
    );
  }

  bool coincideCon(String texto) => [
    id,
    nombre,
    sku,
    categoria,
    precio.toStringAsFixed(0),
  ].any((campo) => campo.toLowerCase().contains(texto));
}
