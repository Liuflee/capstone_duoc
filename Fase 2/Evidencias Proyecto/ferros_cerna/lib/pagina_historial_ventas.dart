import 'package:flutter/material.dart';
import 'menu_lateral.dart';
import 'pagina_detalle_venta.dart'; // Importa el menú compartido

// ============================================================================
// MODELO DE DATOS (Preparado para Supabase)
// ============================================================================
class VentaHistorica {
  final String id;
  final String cliente;
  final String productosResumen;
  final double total;
  final String fecha;

  VentaHistorica({
    required this.id,
    required this.cliente,
    required this.productosResumen,
    required this.total,
    required this.fecha,
  });

  // Factory para mapear el JSON de la tabla 'historial_ventas' de Supabase
  factory VentaHistorica.fromJson(Map<String, dynamic> json) {
    return VentaHistorica(
      id: json['id'].toString(),
      cliente: json['cliente'],
      productosResumen: json['productos_resumen'],
      total: double.parse(json['total'].toString()),
      fecha: json['fecha'],
    );
  }
}

// ============================================================================
// INTERFAZ DE LA PÁGINA
// ============================================================================
class PaginaHistorialVentas extends StatefulWidget {
  const PaginaHistorialVentas({super.key});

  @override
  State<PaginaHistorialVentas> createState() => _PaginaHistorialVentasState();
}

class _PaginaHistorialVentasState extends State<PaginaHistorialVentas> {
  // Datos de prueba simulando la respuesta de Supabase
  final List<VentaHistorica> _historial = [
    VentaHistorica(
      id: '1',
      cliente: 'BENJAMÍN',
      productosResumen: 'RUEDAS ROTORAS,\nVIDRIO PARA VER,\nCLORO LIMPIAAUTOS..',
      total: 200000,
      fecha: '31/09/2003',
    ),
    VentaHistorica(
      id: '2',
      cliente: 'MONAMÍ',
      productosResumen: 'AZUCARERO MÓVIL,\nTECHO INVISIBLE,\nCUBRE AUTOS...',
      total: 300000,
      fecha: '11/06/2003',
    ),
    VentaHistorica(
      id: '3',
      cliente: 'PEPELÍN',
      productosResumen: 'COLGANTE DE OSO',
      total: 50000,
      fecha: '22/02/2003',
    ),
    VentaHistorica(
      id: '4',
      cliente: 'AGUSTÍN',
      productosResumen: 'MANUBRIO SIMPLE,\nPUERTA PESADA,\nVIDRIO DE ORO...',
      total: 800000,
      fecha: '01/12/2002',
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
            const Text('Historial de ventas', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BOTÓN VOLVER
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_return, color: Colors.black),
                    label: const Text('VOLVER A VENTAS', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[200],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // BUSCADOR ALINEADO A LA DERECHA
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 350,
                      color: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'BUSCAR FECHA',
                          border: InputBorder.none,
                          suffixIcon: Icon(Icons.search, color: Colors.black, size: 30),
                        ),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          dataRowMaxHeight: 100, // Altura expandida para los textos multilínea
                          columns: const [
                            DataColumn(label: Text('CLIENTE', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('PRODUCTO', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('TOTAL', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('FECHA', style: TextStyle(color: Colors.white, fontSize: 18))),
                            DataColumn(label: Text('VER', style: TextStyle(color: Colors.white, fontSize: 18))),
                          ],
                          rows: _historial.asMap().entries.map((entrada) {
                            int indice = entrada.key;
                            VentaHistorica venta = entrada.value;
                            
                            return DataRow(
                              color: MaterialStateProperty.all(indice % 2 == 0 ? Colors.grey[200] : Colors.grey[300]),
                              cells: [
                                DataCell(Text(venta.cliente, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: Text(venta.productosResumen, style: const TextStyle(fontSize: 16)),
                                  )
                                ),
                                DataCell(Text('\$${venta.total.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                DataCell(Text(venta.fecha, style: const TextStyle(fontSize: 18))),
                                DataCell(
                                IconButton(
                                  icon: const Icon(Icons.search, size: 40, color: Colors.black),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PaginaDetalleVenta(
                                          idVenta: venta.id,
                                          clienteNombre: venta.cliente,
                                          vehiculoNombre: 'Vehículo Registrado', // Dato de ejemplo a extraer de tu DB
                                          total: venta.total,
                                          fecha: venta.fecha,
                                          desdeHistorial: true, // Define que venimos del Historial
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