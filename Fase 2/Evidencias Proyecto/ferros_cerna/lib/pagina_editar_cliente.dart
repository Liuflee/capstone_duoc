import 'package:flutter/material.dart';

import 'pagina_clientes.dart';
import 'menu_lateral.dart';

class PaginaEditarCliente extends StatelessWidget {
  final Cliente cliente;

  const PaginaEditarCliente({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    final nombreCtrl = TextEditingController(text: cliente.nombre);
    final numeroCtrl = TextEditingController(text: cliente.numero);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: construirAppBar(
        context,
        'Cliente “${cliente.nombre}”',
        esPantallaGrande,
      ),
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Clientes')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande) const ContenedorMenuLateral(activo: 'Clientes'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VEHÍCULO DEL CLIENTE:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                color: Colors.grey[300],
                                child: Text(
                                  cliente.vehiculo,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                color: Colors.grey[400],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'REVISAR',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(Icons.search),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          CampoEditable(controlador: nombreCtrl),
                          const SizedBox(height: 20),
                          CampoEditable(controlador: numeroCtrl),
                        ],
                      ),
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.red[300],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cliente.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            cliente.numero,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.person_remove,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Borrar Cliente',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'HISTORIAL DE VENTAS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.red[400]),
                    border: TableBorder.all(color: Colors.black, width: 2),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'NOMBRE PRODUCTO',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'FECHA',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'EXPANDIR',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    rows: [
                      DataRow(
                        color: MaterialStateProperty.all(Colors.grey[200]),
                        cells: [
                          const DataCell(
                            Text(
                              'MOTOR INALAMBRICO 4K 120 GIGAS,\nRUEDA REDONDA GIGANTE,\nREPUESTO #3212...',
                            ),
                          ),
                          const DataCell(Text('02/02/2002')),
                          const DataCell(Icon(Icons.arrow_drop_down, size: 40)),
                        ],
                      ),
                    ],
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
