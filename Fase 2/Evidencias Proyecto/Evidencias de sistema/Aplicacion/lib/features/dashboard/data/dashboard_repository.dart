import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';

enum PeriodoDashboard {
  hoy('Hoy'),
  semana('Últimos 7 días'),
  mes('Este mes');

  const PeriodoDashboard(this.etiqueta);
  final String etiqueta;

  DateTime inicio(DateTime ahora) {
    final dia = DateTime(ahora.year, ahora.month, ahora.day);
    return switch (this) {
      hoy => dia,
      semana => DateTime(dia.year, dia.month, dia.day - 6),
      mes => DateTime(dia.year, dia.month),
    };
  }
}

/// Cada fuente puede fallar sin convertir los otros indicadores en ceros.
class DatosDashboard {
  final List<VentaRegistro>? ventas;
  final List<Producto>? productos;
  final List<VentaPendiente>? pendientes;

  const DatosDashboard({this.ventas, this.productos, this.pendientes});

  List<VentaRegistro> ventasDelPeriodo(
    PeriodoDashboard periodo,
    DateTime ahora,
  ) {
    final inicio = periodo.inicio(ahora);
    final fin = DateTime(ahora.year, ahora.month, ahora.day + 1);
    return (ventas ?? []).where((venta) {
      final fecha = venta.fechaRegistro?.toLocal();
      return fecha != null && !fecha.isBefore(inicio) && fecha.isBefore(fin);
    }).toList()..sort((a, b) => b.fechaRegistro!.compareTo(a.fechaRegistro!));
  }

  List<Producto> get stockCritico =>
      (productos ?? []).where((producto) => producto.cantidad <= 5).toList()
        ..sort((a, b) {
          final cantidad = a.cantidad.compareTo(b.cantidad);
          return cantidad == 0 ? a.id.compareTo(b.id) : cantidad;
        });
}

class DashboardRepository {
  const DashboardRepository();

  Future<DatosDashboard> cargar() async {
    // Respeta RLS y recupera todas las páginas para no truncar los indicadores.
    Future<List<T>> paginas<T>(
      String tabla,
      String seleccion,
      String orden,
      T Function(Map<String, dynamic>) convertir,
    ) async {
      final resultado = <T>[];
      const tamano = 500;
      for (var desde = 0; ; desde += tamano) {
        final filas = await SupabaseDatabase.client
            .from(tabla)
            .select(seleccion)
            .order(orden)
            .range(desde, desde + tamano - 1);
        resultado.addAll(filas.map(convertir));
        if (filas.length < tamano) return resultado;
      }
    }

    Future<List<T>?> consultar<T>(Future<List<T>> Function() obtener) async {
      try {
        return await obtener();
      } catch (_) {
        return null;
      }
    }

    final resultados = await Future.wait<Object?>([
      consultar(
        () => paginas(
          SupabaseTables.ventas,
          '*, cliente(nombre), '
              'vehiculo_cliente(patente, modelo_vehiculo(modelo, marca_vehiculo(marca))), '
              'detalle_venta_producto(total, producto(codigo_producto, cod_barra)), '
              'detalle_venta_servicio(total, servicio(id, descripcion))',
          'id',
          VentaRegistro.fromJson,
        ),
      ),
      consultar(
        () => paginas(
          SupabaseTables.productos,
          '*, tipo_producto(nombre_tipo)',
          'codigo_producto',
          Producto.fromJson,
        ),
      ),
      consultar(() => VentasPendientesRepository.instancia.obtenerTodas()),
    ]);
    return DatosDashboard(
      ventas: resultados[0] as List<VentaRegistro>?,
      productos: resultados[1] as List<Producto>?,
      pendientes: resultados[2] as List<VentaPendiente>?,
    );
  }
}
