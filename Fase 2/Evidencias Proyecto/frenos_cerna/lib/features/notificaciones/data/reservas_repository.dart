// Reutiliza la conexión existente para consultar productos reales.
import 'package:frenos_cerna/core/data/supabase_database.dart';

// Conserva la selección temporal sin crear tablas fuera del esquema autorizado.
class ReservasRepository {
  static final Map<String, Map<String, dynamic>> _seleccion =
      {}; // Mantiene solo las reservas de esta sesión.
  static Future<List<Map<String, dynamic>>> catalogo() async {
    final datos = await SupabaseDatabase.client
        .from(SupabaseTables.productos)
        .select('codigo_producto, cod_barra, precio, stock')
        .order(
          'codigo_producto',
        ); // Consulta exclusivamente columnas existentes.
    return List<Map<String, dynamic>>.from(
      datos,
    ); // Conserva los identificadores originales.
  } // Finaliza el catálogo.

  static Future<List<Map<String, dynamic>>> reservados() async => _seleccion
      .values
      .map((fila) => Map<String, dynamic>.from(fila))
      .toList(); // Devuelve únicamente la selección temporal.
  static Future<void> reservar(String codigo) async {
    final producto = await SupabaseDatabase.client
        .from(SupabaseTables.productos)
        .select('codigo_producto, cod_barra, precio, stock')
        .eq('codigo_producto', codigo)
        .single(); // Verifica el producto existente.
    _seleccion[codigo] = {
      ...producto,
      'id': codigo,
    }; // Evita duplicados sin guardar campos nuevos en la base.
  } // Finaliza la selección temporal.

  static Future<void> remover(String id) async {
    _seleccion.remove(id);
  } // Quita un producto de esta sesión.
} // Finaliza el acceso temporal a reservas.
