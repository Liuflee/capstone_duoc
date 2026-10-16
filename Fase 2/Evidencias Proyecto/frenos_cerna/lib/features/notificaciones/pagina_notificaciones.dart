// Importa Flutter, la conexión y las páginas de reservas.
import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/notificaciones/pagina_reserva_producto.dart';
import 'package:frenos_cerna/features/notificaciones/pagina_productos_reservados.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

// Presenta los cambios de precio registrados en la base de datos.
class PaginaNotificaciones extends StatefulWidget {
  const PaginaNotificaciones({super.key}); // Crea la página.
  @override // Crea el estado de consulta.
  State<PaginaNotificaciones> createState() => _PaginaNotificacionesState();
} // Finaliza la página pública.

class _PaginaNotificacionesState extends State<PaginaNotificaciones> {
  late Future<List<Map<String, dynamic>>>
  _datos; // Conserva la consulta actual.
  @override // Recupera el historial al abrir la página.
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _datos = _consultar();
  } // Crea una nueva consulta.

  Future<List<Map<String, dynamic>>> _consultar() async {
    final datos = await SupabaseDatabase.client
        .from(SupabaseTables.productos)
        .select('codigo_producto, cod_barra, precio')
        .order(
          'codigo_producto',
        ); // Consulta solo campos del esquema autorizado.
    return datos
        .map(
          (fila) => <String, dynamic>{
            'producto': fila['cod_barra'] ?? fila['codigo_producto'].toString(),
            'precio': fila['precio'],
          },
        )
        .toList(); // Presenta los precios actuales sin inventar un historial.
  }

  // Finaliza la consulta.
  @override // Construye las acciones superiores y la tabla.
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Notificaciones',
    activo: 'Notificaciones',
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Alinea la tabla con las acciones.
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 16,
          children: [
            CartaNavegacion(
              ancho: 240,
              alto: 70,
              icono: Icons.archive_outlined,
              texto: 'RESERVAR PRODUCTO',
              color: const Color(0xFFB7B7B7),
              alPresionar: () => Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/notifications/reserve'),
                  builder: (context) => const PaginaReservaProducto(),
                ),
              ),
            ), // Abre el catálogo de reservas.
            CartaNavegacion(
              ancho: 240,
              alto: 70,
              icono: Icons.menu_book_outlined,
              texto: 'LISTA RESERVADOS',
              color: const Color(0xFFB7B7B7),
              alPresionar: () => Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(
                    name: '/notifications/reserved',
                  ),
                  builder: (context) => const PaginaProductosReservados(),
                ),
              ),
            ), // Abre las reservas guardadas.
          ],
        ), // Conserva las dos acciones superiores del diseño.
        const SizedBox(height: 24), // Separa las acciones de los filtros.
        const Text(
          'Precios actuales. La base no registra cambios históricos de precio.',
        ), // Evita presentar un historial que no existe.
        const SizedBox(height: 12), // Separa la aclaración de la tabla.
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _datos,
            builder: (context, estado) {
              if (estado.hasError) {
                return Column(
                  children: [
                    Text('No se pudo cargar el historial: ${estado.error}'),
                    CartaNavegacion.accion(
                      onPressed: () => setState(_recargar),
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                ); // Permite recuperar la consulta tras aplicar la migración.
              }
              if (!estado.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                ); // Conserva el estado de carga.
              }
              return TablaDatos(
                nombresColumnas: const ['PRODUCTO', 'PRECIO ACTUAL'],
                camposColumnas: const ['producto', 'precio'],
                anchosColumnas: const [500, 391],
                filas: estado.data!,
              ); // Reutiliza la tabla, el buscador y el filtro.
            },
          ),
        ), // Reserva el espacio para las notificaciones.
      ], // Finaliza los elementos de la página.
    ),
  ); // Finaliza la página.
} // Finaliza el estado.
