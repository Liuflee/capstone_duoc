// Importaciones necesarias para construir la interfaz y consultar los clientes.
import 'package:flutter/material.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';

import 'package:frenos_cerna/features/clientes/pagina_crear_cliente.dart';

import 'package:frenos_cerna/features/clientes/pagina_editar_cliente.dart';

import 'package:frenos_cerna/shared/widgets/barra_superior.dart';

import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
// Importa el buscador reutilizable que se coloca encima de la tabla.
import 'package:frenos_cerna/shared/widgets/buscador_tabla.dart';
// Importa el selector y las opciones configurables de filtrado.
import 'package:frenos_cerna/shared/widgets/filtros_tabla.dart';

// Modelo que representa los datos de un cliente en la aplicación.
class Cliente {

  final String id;

  final String nombre;

  final String numero;

  final String ultimaVenta;

  final String vehiculo;

  Cliente({
    required this.id,
    required this.nombre,
    required this.numero,
    required this.ultimaVenta,
    required this.vehiculo,
  });

  // Convierte los campos de Supabase en un objeto Cliente.
  factory Cliente.fromJson(Map<String, dynamic> json) {

    return Cliente(
      id: json['rut']?.toString() ?? 'sin-rut',
      nombre: (json['nombre'] ?? 'Sin nombre').toString(),
      numero: (json['fono'] ?? 'Sin teléfono').toString(),
      ultimaVenta: 'No disponible',
      vehiculo: 'Sin registrar',
    );

  }
}

// Página de clientes: conserva su estado para mostrar datos y realizar búsquedas.
class PaginaClientes extends StatefulWidget {

  const PaginaClientes({super.key});

  @override
  State<PaginaClientes> createState() => _PaginaClientesState();
}

class _PaginaClientesState extends State<PaginaClientes> {

  // Lista de clientes recuperados desde Supabase.
  List<Cliente> clientes = [];

  // Variables para controlar la carga de datos y sus posibles errores.
  bool _cargando = true;

  String? _error;

  // Controlador del campo de búsqueda.
  final TextEditingController _busquedaController = TextEditingController();

  // Identifica los campos en los que se aplica el texto de búsqueda.
  String _filtroSeleccionado = 'todos';

  @override
  void initState() {

    super.initState();

    // Consulta los clientes cuando se abre la página.
    _cargarClientes();
  }

  @override
  void dispose() {

    // Libera los recursos del campo de búsqueda al cerrar la página.
    _busquedaController.dispose();

    super.dispose();
  }

  // Consulta los clientes en Supabase y los ordena alfabéticamente.
  Future<void> _cargarClientes() async {

    try {

      final response = await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .select('rut, nombre, fono')
          .order('nombre');

      final data = response as List<dynamic>;

      // Evita actualizar una pantalla que ya fue cerrada.
      if (!mounted) return;

      // Transforma cada registro recibido en un objeto Cliente.
      final listaClientes = data
          .map((item) => Cliente.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      setState(() {
        clientes = listaClientes;
        _cargando = false;
        _error = null;
      });

    } catch (error) {

      if (!mounted) return;

      // Informa a la interfaz que la consulta terminó con un error.
      setState(() {
        _error = error.toString();
        _cargando = false;
      });
    }
  }

  // Solicita confirmación antes de eliminar un cliente de Supabase.
  Future<void> _borrarCliente(Cliente cliente) async {

    final confirmar = await showDialog<bool>(
      context: context,

      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,

        // Título del cuadro de confirmación.
        title: const Text(
          'Borrar cliente',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        // Muestra el nombre del cliente que se pretende eliminar.
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white, fontSize: 16),
            children: [
              const TextSpan(text: '¿Borrar a '),

              TextSpan(
                text: cliente.nombre.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const TextSpan(text: '?'),
            ],
          ),
        ),

        // Botones para cancelar o confirmar la eliminación.
        actions: [

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Borrar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // No elimina nada si el usuario cancela o la página ya no existe.
    if (confirmar != true || !mounted) return;

    try {

      // Elimina el registro cuyo RUT corresponde al cliente seleccionado.
      await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .delete()
          .eq('rut', int.parse(cliente.id));

      // Actualiza la lista para quitar el cliente eliminado de la tabla.
      await _cargarClientes();

    } catch (error) {

      if (!mounted) return;

      // Muestra un mensaje si Supabase no pudo eliminar el registro.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar el cliente: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    // Obtiene el texto ingresado en el buscador sin distinguir mayúsculas.
    final textoBusqueda = _busquedaController.text.trim().toLowerCase();

    // Aplica la búsqueda al campo elegido; Todos conserva la búsqueda original.
    final clientesFiltrados = textoBusqueda.isEmpty
        ? clientes // Sin texto se muestran todos los clientes recuperados.
        : clientes.where((cliente) { // Evalúa cada cliente con la selección actual.
            // Selecciona los valores asociados al identificador del filtro.
            final campos = switch (_filtroSeleccionado) {
              'nombre' => [cliente.nombre], // Busca únicamente en el nombre.
              'numero' => [cliente.numero], // Busca únicamente en el teléfono.
              'rut' => [cliente.id], // Busca únicamente en el RUT.
              _ => [cliente.nombre, cliente.numero, cliente.id], // Busca en todos los campos.
            }; // Finaliza la selección de campos.
            // Comprueba las coincidencias sin distinguir mayúsculas.
            return campos.any((campo) => campo.toLowerCase().contains(textoBusqueda));
          }).toList(); // Entrega solo los clientes que cumplen la búsqueda.

    // Convierte los clientes filtrados a registros que entiende TablaDatos.
    // El objeto original se conserva para utilizarlo al editar o borrar.
    final List<Map<String, dynamic>> filasClientes = clientesFiltrados
        .map((cliente) => <String, dynamic>{
              'nombre': cliente.nombre,
              'numero': cliente.numero,
              'rut': cliente.id,
              'cliente': cliente,
            })
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[200],

      // Obtiene el ancho y alto disponibles para reproducir la estructura de Inicio.
      body: LayoutBuilder(
        builder: (context, constraints) {

          final double ancho = constraints.maxWidth;

          final double alto = constraints.maxHeight;

          return Column(
            children: [

              // Barra superior reutilizable, con el título de esta página.
              SizedBox(
                width: ancho,
                height: alto * 0.10,
                child: const BarraSuperior(tituloPagina: 'Clientes'),
              ),

              // Área situada debajo de la barra superior.
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Menú lateral reutilizable que marca Clientes como seleccionado.
                    SizedBox(
                      width: ancho * 0.12,
                      child: const MenuLateral(activo: 'Clientes'),
                    ),

                    // Contenido principal de la página Clientes.
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [

                            // Abre el formulario para registrar un nuevo cliente.
                            ElevatedButton.icon(
                              onPressed: () async {

                                final actualizado = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PaginaCrearCliente(),
                                  ),
                                );

                                // Recarga la tabla si se registró un cliente.
                                if (actualizado == true) {
                                  _cargarClientes();
                                }
                              },

                              icon: const Icon(
                                Icons.person_add_alt_1,
                                color: Colors.black,
                              ),

                              label: const Text(
                                '+ Añadir cliente',
                                style: TextStyle(color: Colors.black),
                              ),

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[400],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Obtiene el ancho del mismo contenedor que ocupa TablaDatos.
                            LayoutBuilder(
                              builder: (context, restricciones) {
                                // Distribuye los controles fuera del espacio de la tabla.
                                return Padding(
                                  padding: const EdgeInsets.only(right: 14), // Descuenta el espacio reservado por TablaDatos para el desplazamiento.
                                  child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ubica los controles en extremos opuestos.
                                  children: [ // Mantiene ambos controles en una misma fila.
                                    FiltrosTabla(
                                      anchoTabla: (restricciones.maxWidth - 14).clamp(0.0, double.infinity).toDouble(), // Calcula el 33 % del ancho visible de la tabla.
                                      filtroSeleccionado: _filtroSeleccionado, // Refleja una única selección.
                                      filtros: const [ // Define manualmente las opciones de Clientes.
                                        OpcionFiltroTabla(id: 'todos', texto: 'Todos los campos'), // Conserva la búsqueda general.
                                        OpcionFiltroTabla(id: 'nombre', texto: 'Nombre'), // Limita la búsqueda al nombre.
                                        OpcionFiltroTabla(id: 'numero', texto: 'Número'), // Limita la búsqueda al teléfono.
                                        OpcionFiltroTabla(id: 'rut', texto: 'RUT'), // Limita la búsqueda al RUT.
                                      ], // Finaliza las opciones disponibles.
                                      alSeleccionar: (id) { // Recibe el identificador del filtro elegido.
                                        setState(() => _filtroSeleccionado = id); // Actualiza las filas con el nuevo criterio.
                                      }, // Finaliza la selección del filtro.
                                    ), // Finaliza el selector situado a la izquierda.
                                    BuscadorTabla(
                                      anchoTabla: (restricciones.maxWidth - 14).clamp(0.0, double.infinity).toDouble(), // Usa el mismo ancho visible de la tabla que el selector.
                                      controlador: _busquedaController, // Conserva el texto al cambiar de filtro.
                                      textoAyuda: 'BUSCAR CLIENTE', // Conserva la indicación del buscador original.
                                      alCambiar: (_) => setState(() {}), // Actualiza la tabla mientras se escribe.
                                    ), // Finaliza el buscador situado a la derecha.
                                  ], // Finaliza los controles superiores de la tabla.
                                  ), // Finaliza la distribución horizontal.
                                ); // Finaliza la alineación con el borde visible de la tabla.
                              }, // Finaliza el cálculo del ancho disponible.
                            ), // Finaliza la fila independiente de búsqueda y filtros.

                            const SizedBox(height: 20),

                            // Muestra el error de carga, cuando exista.
                            if (_error != null)
                              Text('Error al cargar clientes: $_error'),

                            // Reserva el espacio restante para la tabla o el indicador de carga.
                            if (_cargando)
                              const Expanded(
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else
                              Expanded(
                                // Widget reutilizable de tabla, alimentado por los clientes filtrados.
                                child: TablaDatos(

                                  // Encabezados visibles de la tabla.
                                  nombresColumnas: const [
                                    'NOMBRE',
                                    'NÚMERO',
                                    'RUT',
                                    'CAMBIAR',
                                    'BORRAR',
                                  ],

                                  // Campos asociados a los valores de cada registro.
                                  // Las columnas de acciones no necesitan campo.
                                  camposColumnas: const [
                                    'nombre',
                                    'numero',
                                    'rut',
                                    '',
                                    '',
                                  ],

                                  // Ancho proporcional de cada columna.
                                  // El widget los ajusta para ocupar el espacio total.
                                  anchosColumnas: const [330, 150, 150, 120, 120],

                                  // Color de cada cabecera (null usa colorEncabezado).
                                  coloresEncabezados: const [
                                    Color.fromARGB(255, 253, 116, 116),
                                    Color.fromARGB(255, 207, 81, 81),
                                    Color.fromARGB(255, 253, 116, 116),
                                    Color.fromARGB(255, 207, 81, 81),
                                    Color.fromARGB(255, 253, 116, 116),
                                  ],

                                  // Color del texto de cada cabecera (null usa blanco).
                                  coloresTextoEncabezados: const [
                                    null,
                                    null,
                                    null,
                                    null,
                                    null,
                                  ],

                                  // Resultados de Supabase ya filtrados por el buscador.
                                  filas: filasClientes,

                                  // Personaliza las columnas que contienen widgets.
                                  celdasPersonalizadas: {

                                    // Columna 0: nombre con avatar del cliente.
                                    0: (context, fila) {
                                      final cliente = fila['cliente'] as Cliente;

                                      return Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.red[300],
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              cliente.nombre,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },

                                    // Columna 3: botón de edición del cliente.
                                    3: (context, fila) {
                                      final cliente = fila['cliente'] as Cliente;

                                      return IconButton(
                                        tooltip: 'Editar cliente',
                                        icon: const Icon(Icons.edit, size: 30),
                                        onPressed: () async {
                                          final actualizado = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PaginaEditarCliente(cliente: cliente),
                                            ),
                                          );

                                          // Actualiza la tabla si el cliente fue editado.
                                          if (!mounted) return;
                                          if (actualizado == true) {
                                            await _cargarClientes();
                                          }
                                        },
                                      );
                                    },

                                    // Columna 4: botón para borrar con confirmación.
                                    4: (context, fila) {
                                      final cliente = fila['cliente'] as Cliente;

                                      return IconButton(
                                        tooltip: 'Borrar cliente',
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.red,
                                          size: 30,
                                        ),
                                        onPressed: () {
                                          _borrarCliente(cliente);
                                        },
                                      );
                                    },
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Campo de texto reutilizable con un icono de edición decorativo.
// Se conserva porque es una clase pública del archivo original.
class CampoEditable extends StatelessWidget {

  final TextEditingController? controlador;

  final String? hint;

  const CampoEditable({super.key, this.controlador, this.hint});

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 400,
      color: Colors.grey[300],
      child: Row(
        children: [

          // Campo que utiliza el controlador y el texto de ayuda recibidos.
          Expanded(
            child: TextField(
              controller: controlador,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),

          // Icono que indica visualmente la edición.
          Container(
            color: Colors.grey[400],
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.edit_square, size: 30),
          ),
        ],
      ),
    );
  }
}
