import 'package:flutter/material.dart';

import 'pagina_clientes.dart';
import 'menu_lateral.dart';

class PaginaCrearCliente extends StatelessWidget {
  const PaginaCrearCliente({super.key});

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: construirAppBar(context, 'Creación de cliente', esPantallaGrande),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'AÑADIR IMAGEN',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(
                      Icons.note_add_outlined,
                      size: 50,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'NOMBRE DEL CLIENTE NUEVO:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const CampoEditable(hint: 'Editar Nombre'),
                  const SizedBox(height: 20),
                  const Text(
                    'NÚMERO DEL CLIENTE NUEVO:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const CampoEditable(hint: 'Editar Número'),
                  const SizedBox(height: 20),
                  const Text(
                    'VEHÍCULO DEL CLIENTE NUEVO:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const CampoEditable(hint: 'Editar Vehículo'),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, color: Colors.black),
                      label: const Text(
                        'REGISTRAR',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
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
