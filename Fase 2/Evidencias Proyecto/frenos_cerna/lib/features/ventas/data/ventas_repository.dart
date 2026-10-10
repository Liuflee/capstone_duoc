import 'package:ferros_cerna/core/data/supabase_database.dart';

class VentaRegistro {
  static const _select =
      'id, iva, rut_cliente, patente_vehiculo, cliente(nombre), '
      'vehiculo_cliente(patente, modelo_vehiculo(modelo, marca_vehiculo(marca))), '
      'detalle_venta_producto(total, producto(codigo_producto, cod_barra)), '
      'detalle_venta_servicio(total, servicio(id, descripcion))';

  final String id;
  final String clienteNombre;
  final String vehiculoNombre;
  final String productosResumen;
  final double total;
  final String fecha;
  final List<Map<String, dynamic>> items;

  const VentaRegistro({
    required this.id,
    required this.clienteNombre,
    required this.vehiculoNombre,
    required this.productosResumen,
    required this.total,
    required this.fecha,
    required this.items,
  });

  factory VentaRegistro.fromJson(Map<String, dynamic> json) {
    final cliente = _map(json['cliente']);
    final vehiculo = _map(json['vehiculo_cliente']);
    final modelo = _map(vehiculo['modelo_vehiculo']);
    final marca = _map(modelo['marca_vehiculo']);
    final productos = _maps(json['detalle_venta_producto']);
    final servicios = _maps(json['detalle_venta_servicio']);
    final items = <Map<String, dynamic>>[];

    for (final detalle in productos) {
      final producto = _map(detalle['producto']);
      final codigo = producto['codigo_producto']?.toString() ?? '';
      items.add({
        'nombre': (producto['cod_barra']?.toString().trim().isNotEmpty ?? false)
            ? producto['cod_barra'].toString()
            : 'Producto $codigo',
        'codigo': codigo,
        'total': _number(detalle['total']),
      });
    }
    for (final detalle in servicios) {
      final servicio = _map(detalle['servicio']);
      items.add({
        'nombre': (servicio['descripcion'] ?? 'Servicio').toString(),
        'codigo': servicio['id']?.toString() ?? '',
        'total': _number(detalle['total']),
      });
    }

    final nombres = items.map((item) => item['nombre']).toSet();
    final partesVehiculo = [
      marca['marca'],
      modelo['modelo'],
      vehiculo['patente'],
    ].where((parte) => parte != null && parte.toString().isNotEmpty);

    return VentaRegistro(
      id: json['id']?.toString() ?? '',
      clienteNombre: (cliente['nombre'] ?? json['rut_cliente'] ?? 'Sin cliente')
          .toString(),
      vehiculoNombre: partesVehiculo.isEmpty
          ? 'Sin vehículo'
          : partesVehiculo.join(' · '),
      productosResumen: nombres.isEmpty ? 'Sin detalle' : nombres.join(', '),
      total: items.fold<double>(
        0,
        (sum, item) => sum + (item['total'] as double),
      ),
      fecha: 'No registrada',
      items: items,
    );
  }

  static Future<List<VentaRegistro>> obtenerTodas() async {
    final data = await SupabaseDatabase.client
        .from(SupabaseTables.ventas)
        .select(_select)
        .order('id', ascending: false);

    return (data as List<dynamic>)
        .map(
          (item) =>
              VentaRegistro.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Future<VentaRegistro> obtenerPorId(String id) async {
    final data = await SupabaseDatabase.client
        .from(SupabaseTables.ventas)
        .select(_select)
        .eq('id', int.parse(id))
        .single();
    return VentaRegistro.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<List<VentaRegistro>> obtenerPorPatente(String patente) async {
    final data = await SupabaseDatabase.client
        .from(SupabaseTables.ventas)
        .select(_select)
        .eq('patente_vehiculo', patente)
        .order('id', ascending: false);
    return (data as List<dynamic>)
        .map(
          (item) =>
              VentaRegistro.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};

  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.map((item) => _map(item)).toList()
      : const <Map<String, dynamic>>[];

  static double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
}
