import 'package:ferros_cerna/data/supabase_database.dart';
import 'package:flutter/material.dart';

import 'menu_lateral.dart';
import 'pagina_detalle_vehiculo.dart';

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
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

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
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'BUSCAR VEHÍCULO',
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.red[400],
                            ),
                            border: TableBorder.all(
                              color: Colors.black,
                              width: 2,
                            ),
                            dataRowMaxHeight: 70,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'CLIENTE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'VEHÍCULO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'KILOMETRAJE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'PATENTE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'REVISAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                            rows: historial.asMap().entries.map((entrada) {
                              int indice = entrada.key;
                              HistorialVehiculo registro = entrada.value;
                              Color? colorFila = indice % 2 == 0
                                  ? Colors.grey[200]
                                  : Colors.grey[300];

                              return DataRow(
                                color: WidgetStateProperty.all(colorFila),
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.red[300],
                                          child: const Icon(
                                            Icons.person_outline,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          registro.clienteNombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      registro.vehiculoNombre,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      registro.total.toStringAsFixed(0),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      registro.fecha,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
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
                                                PaginaDetalleVehiculo(
                                                  vehiculo: registro,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
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
