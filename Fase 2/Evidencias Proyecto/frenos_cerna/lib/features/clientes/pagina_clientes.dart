import 'package:frenos_cerna/features/clientes/pagina_ver_cliente.dart'; // Abre el perfil sin edición.
// Importa los campos de formulario reutilizables.

// Importaciones necesarias para construir la interfaz y consultar los clientes.
import 'package:flutter/material.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/core/data/perfil_sesion.dart';

import 'package:frenos_cerna/features/clientes/pagina_crear_cliente.dart';

import 'package:frenos_cerna/features/clientes/pagina_editar_cliente.dart';

import 'package:frenos_cerna/shared/widgets/barra_superior.dart';

import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
// Importa el panel reutilizable que combina buscador y categorías.
import 'package:frenos_cerna/shared/widgets/panel_filtros.dart';
// Importa la tarjeta reutilizable para abrir el registro de clientes.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

// Modelo que representa los datos de un cliente en la aplicación.
class Cliente {
  final String id;

  final String nombre;

  final String numero;

  final String ultimaVenta;

  final String vehiculo;
  final List<String> vehiculos;
  final List<String> patentesVehiculos;

  Cliente({
    required this.id,
    required this.nombre,
    required this.numero,
    required this.ultimaVenta,
    required this.vehiculo,
    this.vehiculos = const [],
    this.patentesVehiculos = const [],
  });

  // Convierte los campos de Supabase en un objeto Cliente.
  factory Cliente.fromJson(Map<String, dynamic> json) {
    final vehiculos = (json['vehiculo_cliente'] as List? ?? [])
        .whereType<Map>()
        .map((fila) {
          final patente = fila['patente']?.toString() ?? 'Sin patente';
          final modelo = fila['modelo_vehiculo'];
          final marca = modelo is Map ? modelo['marca_vehiculo'] : null;
          final partes = [
            if (marca is Map) marca['marca'],
            if (modelo is Map) modelo['modelo'],
          ].where((parte) => parte != null && parte.toString().isNotEmpty);
          return partes.isEmpty
              ? patente
              : '${partes.join(' ')} ($patente)';
        })
        .toList();
    return Cliente(
      id: json['rut']?.toString() ?? 'sin-rut',
      nombre: (json['nombre'] ?? 'Sin nombre').toString(),
      numero: (json['fono'] ?? 'Sin teléfono').toString(),
      ultimaVenta: 'No disponible',
      vehiculo: (json['vehiculo_cliente'] as List? ?? []).isEmpty
          ? 'Sin registrar'
          : (json['vehiculo_cliente'] as List)
                .map((vehiculo) => vehiculo['patente'].toString())
                .join(', '), // Usa la relación existente de vehículos.
      vehiculos: vehiculos,
      patentesVehiculos: (json['vehiculo_cliente'] as List? ?? [])
          .whereType<Map>()
          .map((fila) => fila['patente']?.toString() ?? '')
          .where((patente) => patente.isNotEmpty)
          .toList(),
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

  @override
  void initState() {
    super.initState();

    // Consulta los clientes cuando se abre la página.
    _cargarClientes();
  }

  // Consulta los clientes en Supabase y los ordena alfabéticamente.
  Future<void> _cargarClientes() async {
    try {
      final response = await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .select(
            'rut, nombre, fono, activo, vehiculo_cliente(patente, modelo_vehiculo(modelo, marca_vehiculo(marca)))',
          )
          .eq('activo', true)
          .order('nombre');

      final data = response as List<dynamic>;

      // Evita actualizar una pantalla que ya fue cerrada.
      if (!mounted) return;

      // Transforma cada registro recibido en un objeto Cliente.
      final listaClientes = data
          .map(
            (item) => Cliente.fromJson(Map<String, dynamic>.from(item as Map)),
          )
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

  Future<void> _eliminarCliente(Cliente cliente) async {
    if (!PerfilSesion.esAdministrador) return;
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('ELIMINAR CLIENTE'),
        content: Text('¿Quitar a ${cliente.nombre} de los clientes activos? Sus ventas y vehículos históricos se conservarán.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('VOLVER')),
          TextButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('ELIMINAR')),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    try {
      await SupabaseDatabase.client.from(SupabaseTables.clientes)
          .update({'activo': false}).eq('rut', int.parse(cliente.id));
      await _cargarClientes();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar el cliente: $error')));
    }
  }

  // Permite consultar y editar clientes sin eliminar registros.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Conserva la navegación lateral en pantallas pequeñas.
      drawer: const Drawer(child: MenuLateral(activo: 'Clientes')),
      backgroundColor: Colors.white,

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
                    if (ancho >= 700) // Comparte el menú de escritorio y permite usar el desplegable en móvil.
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
                            // Alinea la tarjeta con el borde visible derecho de la tabla.
                            Padding(
                              padding: const EdgeInsets.only(right: 14), // Reserva el mismo espacio lateral que TablaDatos.
                              child: CartaNavegacion(
                                ancho: 240, // Define el ancho deseado sin superar el espacio disponible del contenedor.
                                alto: 70, // Da espacio al icono y al texto de la tarjeta.
                                texto: 'AÑADIR CLIENTE', // Describe la acción de navegación.
                                icono: Icons.person_add_alt_1, // Identifica visualmente el registro de clientes.
                                color: Colors.grey[400], // Conserva el color de la acción anterior.
                                alPresionar: () async {
                                  // Abre el formulario al pulsar la tarjeta.
                                  final actualizado =
                                      await Navigator.push<bool>(
                                        context, // Utiliza la navegación de la página actual.
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PaginaCrearCliente(), // Construye el formulario de registro.
                                        ), // Finaliza la ruta del formulario.
                                      ); // Espera el resultado del registro.
                                  if (!mounted) return; // Evita recargar una página que ya se cerró.
                                  if (actualizado == true) {
                                    // Comprueba si se registró un cliente.
                                    await _cargarClientes(); // Actualiza la tabla conservando la búsqueda y el filtro.
                                  } // Finaliza la actualización condicional.
                                }, // Finaliza la acción de la tarjeta.
                              ), // Finaliza la tarjeta reutilizable.
                            ), // Finaliza la alineación con la tabla.

                            const SizedBox(height: 20),

                            // Muestra el error de carga, cuando exista.
                            if (_error != null)
                              Text('Error al cargar clientes: $_error'),

                            // Reserva el espacio restante para la tabla o el indicador de carga.
                            if (_cargando)
                              const Expanded(
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else
                              Expanded(
                                // Panel reutilizable que combina buscador, categoría y tabla.
                                child: PanelFiltros<Cliente>(
                                  datos:
                                      clientes, // Filtra los clientes recuperados de Supabase.
                                  textoAyuda:
                                      'BUSCAR CLIENTE (NOMBRE, RUT, FONO O VEHÍCULO)', // Describe toda la búsqueda disponible.
                                  camposBusqueda: [
                                    (cliente) => cliente.nombre, // Busca en el nombre.
                                    (cliente) => cliente.id, // Busca en el RUT.
                                    (cliente) => cliente.numero, // Busca en el teléfono.
                                    (cliente) => cliente.vehiculo, // Busca por las patentes.
                                    (cliente) =>
                                        cliente.vehiculos.join(' '), // Busca por marca, modelo o patente.
                                  ],
                                  categorias: [
                                    // Permite separar clientes con y sin vehículos registrados.
                                    CategoriaFiltro<Cliente>(
                                      id: 'vehiculos',
                                      etiqueta: 'VEHÍCULOS',
                                      valor: (cliente) => cliente.vehiculos.isEmpty
                                          ? 'SIN REGISTRAR'
                                          : 'CON VEHÍCULOS',
                                    ),
                                  ],
                                  child: (filtrados) {
                                    // Convierte los clientes filtrados a registros de TablaDatos.
                                    // El objeto original se conserva para utilizarlo al editar.
                                    final filasClientes = filtrados
                                        .map(
                                          (cliente) => <String, dynamic>{
                                            'nombre': cliente.nombre,
                                            'numero': cliente.numero,
                                            'rut': cliente.id,
                                            'vehiculos': cliente.vehiculos.isEmpty
                                                ? 'Sin vehículos'
                                                : cliente.vehiculos.join('\n'),
                                            'cliente': cliente,
                                          },
                                        )
                                        .toList();
                                    return TablaDatos(
                                  mostrarControles: false, // El panel ya muestra el buscador y las categorías.
                                  // Encabezados visibles de la tabla.
                                  nombresColumnas: [
                                    'NOMBRE',
                                    'NÚMERO',
                                    'RUT',
                                    'VEHÍCULOS',
                                    'CAMBIAR',
                                    'VER',
                                    if (PerfilSesion.esAdministrador) 'ELIMINAR',
                                  ],

                                  // Campos asociados a los valores de cada registro.
                                  // Las columnas de acciones no necesitan campo.
                                  camposColumnas: [
                                    'nombre',
                                    'numero',
                                    'rut',
                                    'vehiculos',
                                    '',
                                    if (PerfilSesion.esAdministrador) '',
                                    '',
                                  ],

                                  // Ancho proporcional de cada columna.
                                  // El widget los ajusta para ocupar el espacio total.
                                  anchosColumnas: [
                                    330, 150, 150, 260, 120, 120,
                                    if (PerfilSesion.esAdministrador) 120,
                                  ],

                                  // Color de cada cabecera (null usa colorEncabezado).
                                  coloresEncabezados: [
                                    Color.fromARGB(255, 253, 116, 116),
                                    Color.fromARGB(255, 207, 81, 81),
                                    Color.fromARGB(255, 253, 116, 116),
                                    Color.fromARGB(255, 253, 116, 116),
                                    Color.fromARGB(255, 253, 116, 116),
                                    Color.fromARGB(255, 207, 81, 81),
                                    if (PerfilSesion.esAdministrador)
                                      Color.fromARGB(255, 207, 81, 81),
                                  ],

                                  // Color del texto de cada cabecera (null usa blanco).
                                  coloresTextoEncabezados: [
                                    null,
                                    null,
                                    null,
                                    null,
                                    null,
                                    null,
                                    if (PerfilSesion.esAdministrador) null,
                                  ],

                                  // Resultados de Supabase ya filtrados por el buscador.
                                  filas: filasClientes,

                                  // Personaliza las columnas que contienen widgets.
                                  celdasPersonalizadas: {
                                    // Columna 0: nombre con avatar del cliente.
                                    0: (context, fila) {
                                      final cliente =
                                          fila['cliente'] as Cliente;

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

                                    3: (context, fila) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        fila['vehiculos'] as String,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Columna 4: botón de edición del cliente.
                                    4: (context, fila) {
                                      final cliente =
                                          fila['cliente'] as Cliente;

                                      return CartaNavegacion.accion(
                                        // Conserva las medidas y la función de la acción original.
                                        tipoBoton: 'icon',

                                        tooltip: 'Editar cliente',
                                        child: const Icon(Icons.edit, size: 30),
                                        onPressed: () async {
                                          final actualizado =
                                              await Navigator.push<bool>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PaginaEditarCliente(
                                                        cliente: cliente,
                                                      ),
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
                                    5: (context, fila) =>
                                        CartaNavegacion.accion(
                                          tipoBoton: 'icon',
                                          tooltip: 'Ver cliente',
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              settings: const RouteSettings(
                                                name: '/clients/view',
                                              ),
                                              builder: (context) =>
                                                  PaginaVerCliente(
                                                    cliente:
                                                        fila['cliente']
                                                            as Cliente,
                                                  ),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.search,
                                            size: 28,
                                          ),
                                        ), // Consulta el perfil sin habilitar edición.
                                    if (PerfilSesion.esAdministrador)
                                      6: (context, fila) => CartaNavegacion.accion(
                                        tipoBoton: 'icon',
                                        tooltip: 'Eliminar cliente',
                                        onPressed: () => _eliminarCliente(fila['cliente'] as Cliente),
                                        child: const Icon(Icons.delete_outline),
                                      ),
                                  },
                                    ); // Finaliza la tabla construida con los clientes filtrados.
                                  }, // Finaliza la construcción del contenido.
                                ), // Finaliza el panel de filtros reutilizable.
                              ), // Finaliza el espacio restante de la página.
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
