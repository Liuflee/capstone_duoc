import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'consulta_voz.dart';

typedef ProductoConsultado = ({String codigo, String tipo, int stock});

class AsistenteRepository {
  const AsistenteRepository();

  static const _camposProducto =
      'codigo_producto, stock, tipo_producto(nombre_tipo)';

  Future<ProductoConsultado?> consultarCodigo(
    String codigo,
    String usuarioId,
  ) async {
    final cliente = SupabaseDatabase.client;
    _comprobarSesion(cliente, usuarioId);
    final fila = await cliente
        .from(SupabaseTables.productos)
        .select(_camposProducto)
        .eq('codigo_producto', codigo)
        .maybeSingle();
    _comprobarSesion(cliente, usuarioId);
    if (fila != null) return _producto(fila);

    // Whisper puede cambiar las mayúsculas del identificador.
    final variantes = {codigo.toUpperCase(), codigo.toLowerCase()}
      ..remove(codigo);
    if (variantes.isEmpty) return null;
    final coincidencias = await cliente
        .from(SupabaseTables.productos)
        .select(_camposProducto)
        .inFilter('codigo_producto', variantes.toList());
    _comprobarSesion(cliente, usuarioId);
    if (coincidencias.length > 1) {
      throw StateError('El código coincide con más de un producto.');
    }
    return coincidencias.isEmpty ? null : _producto(coincidencias.single);
  }

  Future<({int cantidad, double total})> consultarVentas(
    PeriodoVentasVoz periodo,
    String usuarioId,
  ) async {
    final cliente = SupabaseDatabase.client;
    final fechas = periodo.fechas(DateTime.now());
    var cantidad = 0;
    var total = 0.0;
    int? ultimoId;
    const pagina = 200;
    while (true) {
      _comprobarSesion(cliente, usuarioId);
      var peticion = cliente
          .from(SupabaseTables.ventas)
          .select(
            'id, detalle_venta_producto(total), detalle_venta_servicio(total)',
          )
          .gte('fecha_registro', fechas.desde)
          .lt('fecha_registro', fechas.hasta);
      if (ultimoId != null) peticion = peticion.gt('id', ultimoId);
      final filas = await peticion.order('id').limit(pagina);
      _comprobarSesion(cliente, usuarioId);
      for (final fila in filas) {
        total += VentaRegistro.fromJson(fila).total;
      }
      cantidad += filas.length;
      if (filas.length < pagina) return (cantidad: cantidad, total: total);
      ultimoId = filas.last['id'] as int;
    }
  }

  ProductoConsultado _producto(Map<String, dynamic> fila) => (
    codigo: fila['codigo_producto'].toString(),
    tipo: (fila['tipo_producto'] as Map?)?['nombre_tipo']?.toString() ?? '',
    stock: (fila['stock'] as num).toInt(),
  );

  Future<List<ProductoConsultado>> consultar(
    ConsultaVoz consulta,
    String usuarioId,
  ) async {
    final cliente = SupabaseDatabase.client;
    final productos = <ProductoConsultado>[];
    String? ultimoCodigo;
    const pagina = 200;
    do {
      _comprobarSesion(cliente, usuarioId);
      var peticion = cliente
          .from(SupabaseTables.productos)
          .select(_camposProducto);
      peticion = switch (consulta) {
        ConsultaVoz.sinStock => peticion.eq('stock', 0),
        ConsultaVoz.stockBajo => peticion.gt('stock', 0).lte('stock', 5),
        ConsultaVoz.stockPorCodigo ||
        ConsultaVoz.ventas => throw ArgumentError.value(consulta, 'consulta'),
      };
      if (ultimoCodigo != null) {
        peticion = peticion.gt('codigo_producto', ultimoCodigo);
      }
      final filas = await peticion.order('codigo_producto').limit(pagina);
      _comprobarSesion(cliente, usuarioId);

      productos.addAll(filas.map(_producto));
      if (filas.length < pagina) break;
      ultimoCodigo = productos.last.codigo;
    } while (true);

    return productos;
  }

  void _comprobarSesion(SupabaseClient cliente, String usuarioId) {
    if (cliente.auth.currentUser?.id != usuarioId) {
      throw StateError('Vuelve a iniciar sesión para consultar los datos.');
    }
  }
}
