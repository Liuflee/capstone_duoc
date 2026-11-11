import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'consulta_voz.dart';

class ResultadoConsultaVoz {
  final String resumen;
  final List<String> columnas;
  final List<List<String>> filas;
  const ResultadoConsultaVoz(this.resumen, this.columnas, this.filas);
}

class AsistenteRepository {
  final SupabaseClient? _cliente;
  AsistenteRepository({SupabaseClient? cliente}) : _cliente = cliente;

  Future<ResultadoConsultaVoz> consultar(ConsultaVoz consulta) async {
    final cliente = _cliente ?? SupabaseDatabase.client;
    final usuario = cliente.auth.currentUser?.id;
    if (usuario == null) {
      throw StateError('Inicia sesión para consultar los datos.');
    }
    // Usa la sesión del usuario: todas las lecturas siguen sujetas a RLS.
    if (consulta.tipo != TipoConsultaVoz.ventas) {
      var peticion = cliente
          .from(SupabaseTables.productos)
          .select('codigo_producto, stock, precio');
      peticion = consulta.tipo == TipoConsultaVoz.stockBajo
          ? peticion.lte('stock', 5)
          : peticion.eq('codigo_producto', consulta.codigo!);
      final filas = await peticion.order('codigo_producto').limit(51);
      if (cliente.auth.currentUser?.id != usuario) {
        throw StateError('La sesión cambió. Repite la consulta.');
      }
      return ResultadoConsultaVoz(
        filas.isEmpty
            ? 'No se encontraron productos visibles para tu cuenta.'
            : '${consulta.descripcion}.${filas.length > 50 ? ' Se muestran los primeros 50 resultados.' : ''}',
        const ['Código', 'Unidades', 'Precio CLP'],
        filas
            .take(50)
            .map(
              (fila) => [
                fila['codigo_producto'].toString(),
                fila['stock']?.toString() ?? 'Sin registro',
                fila['precio']?.toString() ?? 'Sin registro',
              ],
            )
            .toList(),
      );
    }
    var total = 0.0;
    var cantidad = 0;
    // Pagina antes de sumar para no truncar silenciosamente las ventas.
    for (var desde = 0; ; desde += 500) {
      final filas = await cliente
          .from(SupabaseTables.ventas)
          .select(
            'id, detalle_venta_producto(total), detalle_venta_servicio(total)',
          )
          .gte('fecha_registro', consulta.inicio!.toUtc().toIso8601String())
          .lt('fecha_registro', consulta.fin!.toUtc().toIso8601String())
          .order('id')
          .range(desde, desde + 499);
      if (cliente.auth.currentUser?.id != usuario) {
        throw StateError('La sesión cambió. Repite la consulta.');
      }
      cantidad += filas.length;
      for (final venta in filas) {
        for (final clave in [
          'detalle_venta_producto',
          'detalle_venta_servicio',
        ]) {
          for (final detalle in (venta[clave] as List? ?? const [])) {
            final importe = num.tryParse(detalle['total'].toString());
            if (importe == null) {
              throw StateError(
                'Hay un importe sin registrar. No se puede calcular el total.',
              );
            }
            total += importe;
          }
        }
      }
      if (filas.length < 500) break;
    }
    return ResultadoConsultaVoz(
      '${consulta.descripcion}: $cantidad ventas, total CLP ${total.toStringAsFixed(0)}. '
      'Solo incluye ventas visibles para tu cuenta y con fecha registrada. '
      'El período usa la hora del dispositivo.',
      const [],
      const [],
    );
  }
}
