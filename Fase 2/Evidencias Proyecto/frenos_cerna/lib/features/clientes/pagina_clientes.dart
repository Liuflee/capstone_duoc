import 'package:frenos_cerna/features/clientes/pagina_ver_cliente.dart'; // Abre el perfil sin edición.
// Importa los campos de formulario reutilizables.

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
          .select(
            'rut, nombre, fono, vehiculo_cliente(patente, modelo_vehiculo(modelo, marca_vehiculo(marca)))',
          )
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

  // Permite consultar y editar clientes sin eliminar registros.

  @override
  Widget build(BuildContext context) {
    // Obtiene el texto ingresado en el buscador sin distinguir mayúsculas.
    final textoBusqueda = _busquedaController.text.trim().toLowerCase();

    // Aplica la búsqueda al campo elegido; Todos conserva la búsqueda original.
    final clientesFiltrados = textoBusqueda.isEmpty
        ? clientes // Sin texto se muestran todos los clientes recuperados.
        : clientes.where((cliente) {
            // Evalúa cada cliente con la selección actual.
            // Selecciona los valores asociados al identificador del filtro.
            final campos = switch (_filtroSeleccionado) {
              'nombre' => [cliente.nombre], // Busca únicamente en el nombre.
              'numero' => [cliente.numero], // Busca únicamente en el teléfono.
              'rut' => [cliente.id], // Busca únicamente en el RUT.
              'vehiculos' => cliente.vehiculos,
              _ => [
                cliente.nombre,
                cliente.numero,
                cliente.id,
                ...cliente.vehiculos,
              ], // Busca en todos los campos.
            }; // Finaliza la selección de campos.
            // Comprueba las coincidencias sin distinguir mayúsculas.
            return campos.any(
              (campo) => campo.toLowerCase().contains(textoBusqueda),
            );
          }).toList(); // Entrega solo los clientes que cumplen la búsqueda.

    // Convierte los clientes filtrados a registros que entiende TablaDatos.
    // El objeto original se conserva para utilizarlo al editar.
    final List<Map<String, dynamic>> filasClientes = clientesFiltrados
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

                            // Obtiene el ancho del mismo contenedor que ocupa TablaDatos.
                            LayoutBuilder(
                              builder: (context, restricciones) {
                                // Distribuye los controles fuera del espacio de la tabla.
                                return Padding(
                                  padding: const EdgeInsets.only(right: 14), // Descuenta el espacio reservado por TablaDatos para el desplazamiento.
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween, // Ubica los controles en extremos opuestos.
                                    children: [
                                      // Mantiene ambos controles en una misma fila.
                                      FiltrosTabla(
                                        anchoTabla:
                                            (restricciones.maxWidth - 14)
                                                .clamp(0.0, double.infinity)
                                                .toDouble(), // Calcula el 33 % del ancho visible de la tabla.
                                        filtroSeleccionado: _filtroSeleccionado, // Refleja una única selección.
                                        filtros: const [
                                          // Define manualmente las opciones de Clientes.
                                          OpcionFiltroTabla(
                                            id: 'todos',
                                            texto: 'Todos los campos',
                                          ), // Conserva la búsqueda general.
                                          OpcionFiltroTabla(
                                            id: 'nombre',
                                            texto: 'Nombre',
                                          ), // Limita la búsqueda al nombre.
                                          OpcionFiltroTabla(
                                            id: 'numero',
                                            texto: 'Número',
                                          ), // Limita la búsqueda al teléfono.
                                          OpcionFiltroTabla(
                                            id: 'rut',
                                            texto: 'RUT',
                                          ), // Limita la búsqueda al RUT.
                                          OpcionFiltroTabla(
                                            id: 'vehiculos',
                                            texto: 'Vehículos',
                                          ),
                                        ], // Finaliza las opciones disponibles.
                                        alSeleccionar: (id) {
                                          // Recibe el identificador del filtro elegido.
                                          setState(
                                            () => _filtroSeleccionado = id,
                                          ); // Actualiza las filas con el nuevo criterio.
                                        }, // Finaliza la selección del filtro.
                                      ), // Finaliza el selector situado a la izquierda.
                                      BuscadorTabla(
                                        anchoTabla:
                                            (restricciones.maxWidth - 14)
                                                .clamp(0.0, double.infinity)
                                                .toDouble(), // Usa el mismo ancho visible de la tabla que el selector.
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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else
                              Expanded(
                                // Widget reutilizable de tabla, alimentado por los clientes filtrados.
                                child: TablaDatos(
                                  mostrarControles: false, // La página ya posiciona sus controles externos encima de la tabla.
                                  // Encabezados visibles de la tabla.
                                  nombresColumnas: const [
                                    'NOMBRE',
                                    'NÚMERO',
                                    'RUT',
                                    'VEHÍCULOS',
                                    'CAMBIAR',
                                    'VER',
                                  ],

                                  // Campos asociados a los valores de cada registro.
                                  // Las columnas de acciones no necesitan campo.
                                  camposColumnas: const [
                                    'nombre',
                                    'numero',
                                    'rut',
                                    'vehiculos',
                                    '',
                                    '',
                                  ],

                                  // Ancho proporcional de cada columna.
                                  // El widget los ajusta para ocupar el espacio total.
                                  anchosColumnas: const [
                                    330,
                                    150,
                                    150,
                                    260,
                                    120,
                                    120,
                                  ],

                                  // Color de cada cabecera (null usa colorEncabezado).
                                  coloresEncabezados: const [
                                    Color.fromARGB(255, 253, 116, 116),
                                    Color.fromARGB(255, 207, 81, 81),
                                    Color.fromARGB(255, 253, 116, 116),
                                    Color.fromARGB(255, 253, 116, 116),
                                    Color.fromARGB(255, 253, 116, 116),
                                    Color.fromARGB(255, 207, 81, 81),
                                  ],

                                  // Color del texto de cada cabecera (null usa blanco).
                                  coloresTextoEncabezados: const [
                                    null,
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
