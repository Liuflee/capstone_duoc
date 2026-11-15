import 'package:frenos_cerna/core/tema/paleta_taller.dart';
// Importa Flutter, la conexión existente y la tabla compartida.
import 'package:material_ui/material_ui.dart';
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
  return mostrarDialogoConTema<Cliente>(
    context: context,
    builder: (dialogo) => Dialog(
      backgroundColor: PaletaTaller.de(dialogo)
          .fondo, // Comparte el fondo de las páginas de la aplicación.
      surfaceTintColor:
          Colors.transparent, // Evita el tinte rosado del tema Material.
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
                      nombresColumnas: const ['NOMBRE', 'RUT'],
                      camposColumnas: const ['nombre', 'rut'],
                      anchosColumnas: const [3, 2],
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
                        for (final campo in ['nombre', 'rut'])
                          (campo == 'nombre'
                              ? 0
                              : 1): (context, fila) => SizedBox.expand(
                            child: InkWell(
                              onTap: () async {
                                final cliente = fila['cliente'] as Cliente;
                                final aceptar = await mostrarDialogoConTema<bool>(
                                  context: dialogo,
                                  builder: (confirmacion) => AlertDialog(
                                    backgroundColor: PaletaTaller.de(
                                      confirmacion,
                                    ).fondo,
                                    surfaceTintColor: Colors.transparent,
                                    title: const Text(
                                      '¿Seleccionar este cliente?',
                                    ),
                                    content: Text(
                                      '${cliente.nombre}\nRUT: ${cliente.id}',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(confirmacion, false),
                                        child: const Text('CANCELAR'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(confirmacion, true),
                                        child: const Text('ACEPTAR'),
                                      ),
                                    ],
                                  ),
                                );
                                if (aceptar == true && dialogo.mounted) {
                                  Navigator.pop(dialogo, cliente);
                                }
                              },
                              child: Center(
                                child: Text(
                                  fila[campo].toString(),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                      },
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
