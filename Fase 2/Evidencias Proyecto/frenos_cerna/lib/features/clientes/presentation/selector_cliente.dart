// Importa Flutter, la conexión existente y la tabla compartida.
import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

// Abre un buscador de clientes existentes y devuelve el cliente elegido.
Future<Cliente?> seleccionarClienteExistente(
  BuildContext context, {
  Future<List<Cliente>> Function()? cargarClientes,
}) {
  Future<List<Cliente>> consultar() async {
    final filas = await SupabaseDatabase.client
        .from(SupabaseTables.clientes)
        .select('rut, nombre, fono')
        .order('nombre'); // Usa solo las columnas de Cliente.
    return filas
        .map((fila) => Cliente.fromJson(Map<String, dynamic>.from(fila)))
        .toList(); // Conserva el RUT de cada cliente.
  } // Finaliza la consulta.

  final consulta =
      (cargarClientes ??
      consultar)(); // Consulta una sola vez mientras se escribe en el buscador.
  return showDialog<Cliente>(
    context: context,
    builder: (dialogo) => Dialog(
      insetPadding: const EdgeInsets.all(
        16,
      ), // Conserva un margen en pantallas pequeñas.
      child: SizedBox(
        width: MediaQuery.sizeOf(dialogo).width * 0.85,
        height: MediaQuery.sizeOf(dialogo).height * 0.75,
        child: Padding(
          padding: const EdgeInsets.all(16), // Separa los controles del borde.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SELECCIONAR CLIENTE',
                      style: TextStyle(fontSize: 20),
                    ),
                  ), // Identifica el buscador.
                  CartaNavegacion.accion(
                    tipoBoton: 'icon',
                    tooltip: 'Cerrar buscador de clientes',
                    child: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogo),
                  ), // Cancela sin cambiar la selección anterior.
                ],
              ), // Finaliza la cabecera.
              const SizedBox(height: 16), // Separa los controles de búsqueda.
              Expanded(
                child: FutureBuilder<List<Cliente>>(
                  future: consulta,
                  builder: (context, estado) {
                    if (estado.hasError) {
                      return Center(
                        child: Text(
                          'No se pudieron cargar los clientes: ${estado.error}',
                        ),
                      ); // Conserva el error de conexión.
                    }
                    if (!estado.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      ); // Conserva el estado de carga.
                    }
                    return TablaDatos(
                      nombresColumnas: const ['NOMBRE', 'RUT', 'SELECCIONAR'],
                      camposColumnas: const ['nombre', 'rut', ''],
                      anchosColumnas: const [
                        4,
                        2,
                        2,
                      ], // Permite buscar por nombre o RUT.
                      filas: estado.data!
                          .map(
                            (cliente) => <String, dynamic>{
                              'nombre': cliente.nombre,
                              'rut': cliente.id,
                              'cliente': cliente,
                            },
                          )
                          .toList(), // Conserva el cliente original al filtrar.
                      celdasPersonalizadas: {
                        2: (context, fila) => CartaNavegacion.accion(
                          tipoBoton: 'icon',
                          tooltip: 'Vincular este cliente',
                          child: const Icon(Icons.check_circle_outline),
                          onPressed: () => Navigator.pop(
                            dialogo,
                            fila['cliente'] as Cliente,
                          ),
                        ),
                      }, // Devuelve el cliente seleccionado sin crear duplicados.
                    ); // Finaliza la tabla del buscador.
                  },
                ),
              ), // Finaliza los resultados.
            ],
          ), // Finaliza el contenido del diálogo.
        ),
      ), // Finaliza el tamaño del buscador.
    ),
  ); // Devuelve el resultado a la página que lo abrió.
} // Finaliza el selector reutilizable.
