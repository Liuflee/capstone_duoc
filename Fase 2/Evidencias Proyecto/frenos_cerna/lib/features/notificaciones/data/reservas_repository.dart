import 'package:frenos_cerna/core/data/supabase_database.dart'; // Reutiliza la sesión y los permisos existentes.

class ReservasRepository {
  const ReservasRepository(); // Permite usar una fuente controlada en pruebas.
  Future<List<Map<String, dynamic>>> listar({required bool listas}) async {
    final datos = await SupabaseDatabase.client
        .from('reserva_producto')
        .select(
          'id, codigo_producto, estado, fecha_registro, rut_cliente, cliente(nombre, fono)',
        )
        .eq('estado', listas ? 'lista' : 'reservado')
        .order(
          'fecha_registro',
          ascending: false,
        ); // Consulta reservas persistentes según su estado.
    return List<Map<String, dynamic>>.from(datos); // Conserva los IDs reales.
  }

  Future<void> reservar(String codigo, {required String rutCliente}) async {
    final valor = codigo
        .trim()
        .toUpperCase(); // Normaliza códigos sin convertirlos a números.
    if (valor.isEmpty) {
      throw ArgumentError(
        'Ingresa el código del producto.',
      ); // Evita reservas vacías.
    }
    await SupabaseDatabase.client.from('reserva_producto').insert({
      'codigo_producto': valor,
      'estado': 'reservado',
      'rut_cliente': int.parse(
        rutCliente,
      ), // Vincula la solicitud al cliente que debe ser avisado.
    }); // Guarda la reserva sin modificar ventas ni stock.
  }

  Future<void> marcarLista(Object id) async {
    await SupabaseDatabase.client
        .from('reserva_producto')
        .update({'estado': 'lista'})
        .eq('id', id)
        .eq('estado', 'reservado')
        .select('id')
        .single(); // Cambia el estado sin eliminar la reserva y detecta cambios concurrentes.
  }

  Future<void> eliminar(Object id) async {
    await SupabaseDatabase.client
        .from('reserva_producto')
        .delete()
        .eq('id', id)
        .select('id')
        .single(); // Las reservas son solicitudes operativas y no afectan ventas cerradas.
  }
}
