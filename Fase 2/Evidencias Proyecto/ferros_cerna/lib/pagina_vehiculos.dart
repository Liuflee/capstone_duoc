import 'package:flutter/material.dart';
import 'menu_lateral.dart';
import 'pagina_detalle_vehiculo.dart'; // Importamos el menú centralizado que creaste en el paso anterior

// ============================================================================
// MODELO DE DATOS (Preparado para Supabase)
// ============================================================================
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

  // Factory para mapear el JSON de Supabase a este objeto
  factory HistorialVehiculo.fromJson(Map<String, dynamic> json) {
    return HistorialVehiculo(
      id: json['id'].toString(),
      clienteNombre: json['cliente_nombre'],
      vehiculoNombre: json['vehiculo_nombre'],
      total: double.parse(json['total'].toString()),
      fecha: json['fecha'],
    );
  }
}

// ============================================================================
// INTERFAZ DE LA PÁGINA
// ============================================================================
class PaginaVehiculos extends StatefulWidget {
  const PaginaVehiculos({super.key});

  @override
  State<PaginaVehiculos> createState() => _PaginaVehiculosState();
}

class _PaginaVehiculosState extends State<PaginaVehiculos> {
  // Lista de prueba (Dummy Data) replicando la imagen
  List<HistorialVehiculo> historial = [
    HistorialVehiculo(id: '1', clienteNombre: 'BENJAMÍN', vehiculoNombre: 'Chevroleis\nevoleits', total: 100000, fecha: '02/02/2002'),
    HistorialVehiculo(id: '2', clienteNombre: 'ALONSO', vehiculoNombre: 'Toyoti 23', total: 300000, fecha: '02/01/2002'),
    HistorialVehiculo(id: '3', clienteNombre: 'PABLO', vehiculoNombre: 'Hundai', total: 600000, fecha: '06/07/2001'),
    HistorialVehiculo(id: '4', clienteNombre: 'AMELIA', vehiculoNombre: 'Miata', total: 90000, fecha: '15/05/2001'),
    HistorialVehiculo(id: '5', clienteNombre: 'AMY', vehiculoNombre: 'Payaso', total: 500000, fecha: '30/03/2001'),
    HistorialVehiculo(id: '6', clienteNombre: 'ALBERTO', vehiculoNombre: 'Golf', total: 60000, fecha: '12/12/2000'),
    HistorialVehiculo(id: '7', clienteNombre: 'SELENA', vehiculoNombre: 'Ferrari 4', total: 20000, fecha: '27/08/2000'),
  ];

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
                    child: const Icon(Icons.settings_input_component, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('Frenos\nCerna', style: TextStyle(color: Colors.black, fontSize: 16)),
                ],
              ),
            const Text('Historial Vehículos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
            Row(
              children: [
                if (esPantallaGrande)
                  const Text('Leonardo', style: TextStyle(color: Colors.black, fontSize: 16)),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.red[800],
                  child: const Icon(Icons.build, color: Colors.black),
                ),
              ],
            )
          ],
        ),
      ),
      drawer: esPantallaGrande ? null : const Drawer(child: MenuLateral(activo: 'Vehiculos')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MENÚ LATERAL
          if (esPantallaGrande)
            const SizedBox(
              width: 150,
              child: MenuLateral(activo: 'Vehiculos'), // Pasamos un activo que no resalte los 4 principales, tal como en la imagen
            ),
          
          // CONTENIDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Buscador alineado a la derecha
                  Container(
                    width: 350,
                    color: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'BUSCAR VEHÍCULO',
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.search, color: Colors.black, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TABLA DE HISTORIAL
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.red[400]),
                          border: TableBorder.all(color: Colors.black, width: 2),
                          dataRowMaxHeight: 70, // Aumentamos la altura para los textos largos
                          columns: const [
                            DataColumn(label: Text('CLIENTE', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('VEHÍCULO', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('TOTAL', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('FECHA', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('REVISAR', style: TextStyle(color: Colors.white, fontSize: 18))),
                          ],
                          rows: historial.asMap().entries.map((entrada) {
                            int indice = entrada.key;
                            HistorialVehiculo registro = entrada.value;
                            Color? colorFila = indice % 2 == 0 ? Colors.grey[200] : Colors.grey[300];

                            return DataRow(
                              color: MaterialStateProperty.all(colorFila),
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.red[300],
                                        child: const Icon(Icons.person_outline, color: Colors.black),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(registro.clienteNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  )
                                ),
                                DataCell(Text(registro.vehiculoNombre, style: const TextStyle(fontSize: 16))),
                                // Formato de precio añadiendo el punto de miles si es necesario
                                DataCell(Text('\$${registro.total.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}', style: const TextStyle(fontSize: 16))),
                                DataCell(Text(registro.fecha, style: const TextStyle(fontSize: 16))),
                                DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.search, size: 35, color: Colors.black),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            // Le pasamos la variable "registro" que contiene la fila actual
                                            builder: (context) => PaginaDetalleVehiculo(vehiculo: registro),
                                          ),
                                        );
                                      },
                                    )
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