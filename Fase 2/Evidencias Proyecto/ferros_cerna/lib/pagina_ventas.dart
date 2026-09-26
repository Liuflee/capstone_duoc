import 'package:flutter/material.dart';
import 'menu_lateral.dart';
import 'pagina_crear_ventas.dart';
import 'pagina_detalle_venta.dart';
import 'pagina_historial_ventas.dart'; // Asegúrate de tener este archivo del paso anterior

// ============================================================================
// MODELO DE DATOS (Preparado para Supabase)
// ============================================================================
class VentaEnProceso {
  final String id;
  final String clienteNombre;
  final String vehiculoNombre;
  final String productosResumen;

  VentaEnProceso({
    required this.id,
    required this.clienteNombre,
    required this.vehiculoNombre,
    required this.productosResumen,
  });

  // Factory para mapear el JSON de Supabase (ej. tabla 'ventas_en_proceso')
  factory VentaEnProceso.fromJson(Map<String, dynamic> json) {
    return VentaEnProceso(
      id: json['id'].toString(),
      clienteNombre: json['cliente_nombre'],
      vehiculoNombre: json['vehiculo_nombre'],
      productosResumen: json['productos_resumen'],
    );
  }
}

// ============================================================================
// INTERFAZ DE LA PÁGINA
// ============================================================================
class PaginaVentas extends StatefulWidget {
  const PaginaVentas({super.key});

  @override
  State<PaginaVentas> createState() => _PaginaVentasState();
}

class _PaginaVentasState extends State<PaginaVentas> {
  // Dummy data simulando los datos que vendrán de Supabase
  List<VentaEnProceso> ventasActivas = [
    VentaEnProceso(
      id: '1',
      clienteNombre: 'MATÍAS',
      vehiculoNombre: 'TOYOTIS 3',
      productosResumen: 'ACELERADOR,\nTRANSMISOR 23,\nCARBURADOR...',
    ),
    VentaEnProceso(
      id: '2',
      clienteNombre: 'JONATHAN\nBADMNINGTON',
      vehiculoNombre: 'HUNDIAI',
      productosResumen: 'RUEDA AZUL,\nMETAL\nEXHAUSTIVO...',
    ),
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
                  Container(width: 40, height: 40, color: Colors.grey[500], child: const Icon(Icons.settings_input_component, color: Colors.white)),
                  const SizedBox(width: 10),
                  const Text('Frenos\nCerna', style: TextStyle(color: Colors.black, fontSize: 16)),
                ],
              ),
            const Text('Ventas', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
            Row(
              children: [
                if (esPantallaGrande) const Text('Leonardo', style: TextStyle(color: Colors.black, fontSize: 16)),
                const SizedBox(width: 10),
                CircleAvatar(backgroundColor: Colors.red[800], child: const Icon(Icons.build, color: Colors.black)),
              ],
            )
          ],
        ),
      ),
      drawer: esPantallaGrande ? null : const Drawer(child: MenuLateral(activo: 'Ventas')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MENÚ LATERAL
          if (esPantallaGrande) const SizedBox(width: 150, child: MenuLateral(activo: 'Ventas')),
          
          // CONTENIDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // BOTONES SUPERIORES
                  Wrap(
                    spacing: 40,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      // Botón Registrar Venta Nueva
                      InkWell(
                        onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PaginaCrearVenta()),
                            );
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
                              Icon(Icons.attach_money, size: 70, color: Colors.black87),
                              SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  'REGISTRAR\nVENTA NUEVA',
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Botón Historial de Ventas
                      InkWell(
                        onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PaginaHistorialVentas()),
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
                              Icon(Icons.menu_book, size: 70, color: Colors.black87),
                              SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  'HISTORIAL\nDE VENTAS',
                                  style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),

                  // TÍTULO TABLA
                  const Text('VENTAS EN PROCESO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // TABLA DE VENTAS
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.red[400]),
                          border: TableBorder.all(color: Colors.black, width: 2),
                          dataRowMaxHeight: 120, // Altura expandida para textos con saltos de línea
                          columns: const [
                            DataColumn(label: Text('CLIENTE', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('VEHÍCULO', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('PRODUCTOS', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('VER', style: TextStyle(color: Colors.white, fontSize: 18))),
                          ],
                          rows: ventasActivas.asMap().entries.map((entrada) {
                            int indice = entrada.key;
                            VentaEnProceso venta = entrada.value;
                            
                            return DataRow(
                              color: MaterialStateProperty.all(indice % 2 == 0 ? Colors.grey[200] : Colors.grey[300]),
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.red[300],
                                        child: const Icon(Icons.person_outline, color: Colors.black, size: 30),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(venta.clienteNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  )
                                ),
                                DataCell(Text(venta.vehiculoNombre, style: const TextStyle(fontSize: 18))),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: Text(venta.productosResumen, style: const TextStyle(fontSize: 16)),
                                  )
                                ),
                                DataCell(
                                IconButton(
                                  icon: const Icon(Icons.search, size: 40, color: Colors.black),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PaginaDetalleVenta(
                                          idVenta: venta.id,
                                          clienteNombre: venta.clienteNombre.replaceAll('\n', ' '), // Limpiamos saltos de línea
                                          vehiculoNombre: venta.vehiculoNombre,
                                          total: 200000, // Total simulado para ventas en proceso
                                          desdeHistorial: false, // Define que venimos de Ventas
                                        ),
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