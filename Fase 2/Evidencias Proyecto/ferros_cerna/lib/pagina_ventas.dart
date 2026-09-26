import 'package:ferros_cerna/data/ventas_repository.dart';
import 'package:flutter/material.dart';

import 'menu_lateral.dart';
import 'pagina_crear_ventas.dart';
import 'pagina_detalle_venta.dart';
import 'pagina_historial_ventas.dart';

typedef VentaEnProceso = VentaRegistro;

class PaginaVentas extends StatefulWidget {
  const PaginaVentas({super.key});

  @override
  State<PaginaVentas> createState() => _PaginaVentasState();
}

class _PaginaVentasState extends State<PaginaVentas> {
  List<VentaEnProceso> ventasActivas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    try {
      final data = await VentaRegistro.obtenerTodas();
      setState(() {
        ventasActivas = data;
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
              'Ventas',
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
          : const Drawer(child: MenuLateral(activo: 'Ventas')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande)
            const SizedBox(width: 150, child: MenuLateral(activo: 'Ventas')),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 40,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      InkWell(
                        onTap: () async {
                          final registrada = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PaginaCrearVenta(),
                            ),
                          );
                          if (registrada == true) _cargarVentas();
                        },
                        child: Container(
                          width: 350,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 70,
                                color: Colors.black87,
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  'REGISTRAR\nVENTA NUEVA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PaginaHistorialVentas(),
                            ),
                          );
                        },
                        child: Container(
                          width: 350,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 70,
                                color: Colors.black87,
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  'HISTORIAL\nDE VENTAS',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  const Text(
                    'VENTAS REGISTRADAS',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) Text('Error al cargar ventas: $_error'),
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
                            dataRowMaxHeight: 120,
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
                                  'PRODUCTOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'VER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                            rows: ventasActivas.asMap().entries.map((entrada) {
                              int indice = entrada.key;
                              VentaEnProceso venta = entrada.value;

                              return DataRow(
                                color: WidgetStateProperty.all(
                                  indice % 2 == 0
                                      ? Colors.grey[200]
                                      : Colors.grey[300],
                                ),
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.red[300],
                                          child: const Icon(
                                            Icons.person_outline,
                                            color: Colors.black,
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          venta.clienteNombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      venta.vehiculoNombre,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  DataCell(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10.0,
                                      ),
                                      child: Text(
                                        venta.productosResumen,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.search,
                                        size: 40,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PaginaDetalleVenta(
                                                  idVenta: venta.id,
                                                  clienteNombre: venta
                                                      .clienteNombre
                                                      .replaceAll('\n', ' '),
                                                  vehiculoNombre:
                                                      venta.vehiculoNombre,
                                                  total: venta.total,
                                                  desdeHistorial: false,
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
