// Abre el registro conservando el listado debajo de la nueva ruta.
import 'package:frenos_cerna/features/vehiculos/pagina_crear_vehiculo.dart';
// Importa la barra superior común a las páginas.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
// Importa los campos de formulario reutilizables.

// Importa las cartas que conservan las acciones de la página.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_detalle_vehiculo.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
// Importa el panel reutilizable que combina buscador y categorías.
import 'package:frenos_cerna/shared/widgets/panel_filtros.dart';

class HistorialVehiculo {
  final String id;
  final String clienteNombre;
  final String vehiculoNombre;
  final String marca; // Permite filtrar por la marca del vehículo.
  final double total;
  final String fecha;

  HistorialVehiculo({
    required this.id,
    required this.clienteNombre,
    required this.vehiculoNombre,
    this.marca = '', // Los registros antiguos no obligan a informar la marca.
    required this.total,
    required this.fecha,
  });

  factory HistorialVehiculo.fromJson(Map<String, dynamic> json) {
    final clienteMap = json['cliente'];
    final modeloMap = json['modelo_vehiculo'];
    final marcaMap = modeloMap is Map ? modeloMap['marca_vehiculo'] : null;

    final nombreCliente = clienteMap is Map
        ? (clienteMap['nombre'] ?? 'Sin cliente')
        : (json['rut_cliente'] ?? 'Sin cliente');

    final partesVehiculo = [
      if (marcaMap is Map) marcaMap['marca'],
      if (modeloMap is Map) modeloMap['modelo'],
    ].where((parte) => parte != null && parte.toString().isNotEmpty);

    final patente = json['patente']?.toString() ?? 'Sin patente';

    return HistorialVehiculo(
      id: patente,
      clienteNombre: nombreCliente.toString(),
      vehiculoNombre: partesVehiculo.isEmpty
          ? patente
          : '${partesVehiculo.join(' ')} ($patente)',
      marca:
          marcaMap is Map
              ? (marcaMap['marca']?.toString() ?? '')
              : '', // Usa la marca desnormalizada del esquema.
      total: double.tryParse(json['kilometraje']?.toString() ?? '0') ?? 0,
      fecha: patente,
    );
  }
}

Future<List<HistorialVehiculo>> cargarVehiculosDeCliente(String rut) async {
  final respuesta = await SupabaseDatabase.client
      .from(SupabaseTables.vehiculos)
      .select(
        'patente, kilometraje, rut_cliente, cliente(nombre), '
        'modelo_vehiculo(modelo, marca_vehiculo(marca))',
      )
      .eq('rut_cliente', int.parse(rut))
      .order('patente');
  return respuesta
      .map(
        (fila) => HistorialVehiculo.fromJson(Map<String, dynamic>.from(fila)),
      )
      .toList();
}

class PaginaVehiculos extends StatefulWidget {
  const PaginaVehiculos({super.key});

  @override
  State<PaginaVehiculos> createState() => _PaginaVehiculosState();
}

class _PaginaVehiculosState extends State<PaginaVehiculos> {
  List<HistorialVehiculo> historial = [];
  bool _cargando = true;
  String? _error;

  // Colores de cabecera que se alternan entre las columnas.
  static const Color _rojoClaro = Color.fromARGB(255, 253, 116, 116);
  static const Color _rojoOscuro = Color.fromARGB(255, 207, 81, 81);

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  Future<void> _cargarVehiculos() async {
    try {
      final response = await SupabaseDatabase.client
          .from(SupabaseTables.vehiculos)
          .select(
            'patente, kilometraje, rut_cliente, cliente(nombre), '
            'modelo_vehiculo(modelo, marca_vehiculo(marca))',
          )
          .order('patente');

      final data = response as List<dynamic>;

      if (!mounted) return;

      setState(() {
        historial = data
            .map(
              (item) => HistorialVehiculo.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();

        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande =
        MediaQuery.of(context).size.width >=
        700; // Comparte el punto de adaptación del menú principal.

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        // Comparte el diez por ciento de altura con la página principal.
        preferredSize: Size.fromHeight(
          MediaQuery.sizeOf(context).height * 0.10,
        ),
        child: SizedBox(
          height:
              MediaQuery.sizeOf(context).height *
              0.10, // Mantiene la altura común de las barras.
          child: BarraSuperior(
            tituloPagina: 'Vehículos',
          ), // Reutiliza el encabezado de Inicio.
        ),
      ),
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Vehiculos')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande)
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.12,
              child: const MenuLateral(activo: 'Vehiculos'),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: CartaNavegacion.accion(
                      onPressed: () async {
                        final creado = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            settings: const RouteSettings(
                              name: '/vehicles/new',
                            ),
                            builder: (context) => const PaginaCrearVehiculo(),
                          ),
                        );
                        if (creado == true && mounted) await _cargarVehiculos();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('REGISTRAR VEHÍCULO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB7B7B7),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ), // Abre la nueva vista y actualiza el listado al volver.
                  const SizedBox(height: 20), // Separa la acción de los filtros.

                  if (_error != null)
                    Text('Error al cargar vehículos: $_error'),
                  if (_cargando)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Expanded(
                      child: PanelFiltros<HistorialVehiculo>(
                        datos: historial, // Filtra todos los vehículos registrados.
                        textoAyuda:
                            'BUSCAR CLIENTE, VEHÍCULO O PATENTE', // Describe la búsqueda disponible.
                        camposBusqueda: [
                          (registro) =>
                              registro.clienteNombre, // Busca en el cliente.
                          (registro) =>
                              registro.vehiculoNombre, // Busca en marca, modelo o patente.
                          (registro) =>
                              registro.total
                                  .toStringAsFixed(0), // Permite buscar por kilometraje.
                          (registro) => registro.fecha, // Busca en la patente.
                        ],
                        categorias: [
                          // Muestra las marcas reales del parque automotriz sin configurarlas a mano.
                          CategoriaFiltro<HistorialVehiculo>(
                            id: 'marca',
                            etiqueta: 'MARCA',
                            valor: (registro) => registro.marca.isEmpty
                                ? 'SIN MARCA'
                                : registro.marca,
                          ),
                        ],
                        child: (filtrados) {
                          // Convierte los vehículos filtrados a registros de TablaDatos.
                          // El objeto original se conserva para usarlo al revisar el detalle.
                          final filasVehiculos = filtrados
                              .map(
                                (registro) => <String, dynamic>{
                                  'cliente': registro.clienteNombre,
                                  'vehiculo': registro.vehiculoNombre,
                                  'kilometraje': registro.total.toStringAsFixed(0),
                                  'patente': registro.fecha,
                                  'registro': registro,
                                },
                              )
                              .toList();
                          return TablaDatos(
                            mostrarControles:
                                false, // El panel ya muestra el buscador y las categorías.
                            // Encabezados visibles de la tabla.
                        nombresColumnas: const [
                          'CLIENTE',
                          'VEHÍCULO',
                          'KILOMETRAJE',
                          'PATENTE',
                          'REVISAR',
                        ],

                        // Campos de cada columna (vacío si la celda es personalizada).
                        camposColumnas: const [
                          'cliente',
                          'vehiculo',
                          'kilometraje',
                          'patente',
                          '',
                        ],

                        // Ancho proporcional de cada columna.
                        anchosColumnas: const [300, 230, 150, 150, 120],

                        // Colores de cabecera alternando entre los dos rojos.
                        coloresEncabezados: const [
                          _rojoClaro,
                          _rojoOscuro,
                          _rojoClaro,
                          _rojoOscuro,
                          _rojoClaro,
                        ],

                        filas: filasVehiculos,

                        celdasPersonalizadas: {
                          // Columna 0: cliente con avatar.
                          0: (context, fila) {
                            final registro =
                                fila['registro'] as HistorialVehiculo;

                            return Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.red[300],
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    registro.clienteNombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },

                          // Columna 4: botón para revisar el detalle del vehículo.
                          4: (context, fila) {
                            final registro =
                                fila['registro'] as HistorialVehiculo;

                            return CartaNavegacion.accion(
                              // Conserva las medidas y la función de la acción original.
                              tipoBoton: 'icon',

                              tooltip: 'Revisar vehículo',
                              child: const Icon(
                                Icons.search,
                                size: 35,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaginaDetalleVehiculo(
                                      vehiculo: registro,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        },
                          ); // Finaliza la tabla construida con los vehículos filtrados.
                        }, // Finaliza la construcción del contenido.
                      ), // Finaliza el panel de filtros reutilizable.
                    ), // Finaliza el espacio restante de la página.
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
