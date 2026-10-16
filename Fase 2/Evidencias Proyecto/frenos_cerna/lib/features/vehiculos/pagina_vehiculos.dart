import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_detalle_vehiculo.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

class HistorialVehiculo {
  final String id;
  final String clienteNombre;
  final String vehiculoNombre;
  final double total;
  final String fecha;

  HistorialVehiculo({
    required this.id,
    required this.clienteNombre,
    required this.vehiculoNombre,
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
      total: double.tryParse(json['kilometraje']?.toString() ?? '0') ?? 0,
      fecha: patente,
    );
  }
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
  String _busqueda = '';

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

  List<HistorialVehiculo> get _vehiculosFiltrados {
    if (_busqueda.trim().isEmpty) {
      return historial;
    }

    final busqueda = _busqueda.trim().toLowerCase();

    return historial.where((registro) {
      final cliente = registro.clienteNombre.toLowerCase();

      final vehiculo = registro.vehiculoNombre.toLowerCase();

      final patente = registro.fecha.toLowerCase();

      return cliente.contains(busqueda) ||
          vehiculo.contains(busqueda) ||
          patente.contains(busqueda);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    // Convierte los vehículos filtrados a registros que entiende TablaDatos.
    // El objeto original se conserva para usarlo al revisar el detalle.
    final List<Map<String, dynamic>> filasVehiculos = _vehiculosFiltrados
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (esPantallaGrande)
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[500],
                    child: const Icon(
                      Icons.settings_input_component,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Frenos\nCerna',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            const Text(
              'Historial Vehículos',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Row(
              children: [
                if (esPantallaGrande)
                  const Text(
                    'Leonardo',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.red[800],
                  child: const Icon(Icons.build, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Vehiculos')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande)
            const SizedBox(width: 150, child: MenuLateral(activo: 'Vehiculos')),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 350,
                    color: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      onChanged: (valor) {
                        setState(() {
                          _busqueda = valor;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'BUSCAR CLIENTE, VEHÍCULO O PATENTE',
                        border: InputBorder.none,
                        suffixIcon: Icon(
                          Icons.search,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Text('Error al cargar vehículos: $_error'),
                  if (_cargando)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Expanded(
                      child: TablaDatos(
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

                            return IconButton(
                              tooltip: 'Revisar vehículo',
                              icon: const Icon(
                                Icons.search,
                                size: 35,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaginaDetalleVehiculo(vehiculo: registro),
                                  ),
                                );
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
    );
  }
}