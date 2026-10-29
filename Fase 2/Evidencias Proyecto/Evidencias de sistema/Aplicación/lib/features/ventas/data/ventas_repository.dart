import 'package:frenos_cerna/core/data/supabase_database.dart';

class VentaRegistro {
  static const _select =
      '*, cliente(nombre), '
      'vehiculo_cliente(patente, modelo_vehiculo(modelo, marca_vehiculo(marca))), '
      'detalle_venta_producto(total, producto(codigo_producto, cod_barra)), '
      'detalle_venta_servicio(total, servicio(id, descripcion))';

  final String id;
  final String
  rutCliente; // Conserva la relación para abrir el perfil correcto.
  final String clienteNombre;
  final String vehiculoNombre;
  final String productosResumen;
  final double total;
  final String fecha;
  final DateTime?
  fechaRegistro; // Conserva la fecha del servidor cuando está disponible.

  final List<Map<String, dynamic>> items;

  const VentaRegistro({
    required this.id,
    this.rutCliente =
        '', // Mantiene compatibilidad con registros de prueba anteriores.
    required this.clienteNombre,
    required this.vehiculoNombre,
    required this.productosResumen,
    required this.total,
    required this.fecha,
    this.fechaRegistro, // Las ventas antiguas pueden no tener una fecha conocida.

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
            : codigo,
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
      rutCliente:
          json['rut_cliente']?.toString() ??
          '', // Obtiene la clave real del cliente.
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
      fecha: json['fecha_registro']?.toString() ?? 'No registrada', // Conserva explícitamente la ausencia de fecha en ventas antiguas.
      fechaRegistro: DateTime.tryParse(json['fecha_registro']?.toString() ?? '')
          ?.toLocal(), // Compara días en la zona horaria del dispositivo.
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

  static Future<List<VentaRegistro>> obtenerPorCliente(String rut) async {
    final datos = await SupabaseDatabase.client
        .from(SupabaseTables.ventas)
        .select(_select)
        .eq('rut_cliente', int.parse(rut))
        .order(
          'id',
          ascending: false,
        ); // Recupera el historial real del cliente.
    return datos
        .map((fila) => VentaRegistro.fromJson(Map<String, dynamic>.from(fila)))
        .toList(); // Convierte las ventas del cliente.
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
