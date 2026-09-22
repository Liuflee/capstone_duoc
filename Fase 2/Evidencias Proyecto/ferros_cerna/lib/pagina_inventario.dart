import 'package:ferros_cerna/pagina_edicion_producto.dart';
import 'package:flutter/material.dart';

import 'menu_lateral.dart';

// 1. MODELO DE DATOS (Preparado para Supabase)
class Producto {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;
  final int cantidad;

  Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.cantidad,
  });

  // Este método te servirá luego para convertir la respuesta de Supabase a objetos de Flutter
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'].toString(),
      nombre: json['nombre'],
      categoria: json['categoria'],
      precio: double.parse(json['precio'].toString()),
      cantidad: json['cantidad'],
    );
  }
}

// 2. INTERFAZ DE LA PÁGINA
class PaginaInventario extends StatefulWidget {
  const PaginaInventario({super.key});

  @override
  State<PaginaInventario> createState() => _PaginaInventarioState();
}

class _PaginaInventarioState extends State<PaginaInventario> {
  // Lista de prueba (Dummy Data). Luego esto se llenará con: supabase.from('productos').select();
  List<Producto> productos = [
    Producto(
      id: '1',
      nombre: 'Acelerador vintage',
      categoria: 'Pieza',
      precio: 30000,
      cantidad: 1,
    ),
    Producto(
      id: '2',
      nombre: 'Alerón Azul',
      categoria: 'Pieza',
      precio: 70000,
      cantidad: 3,
    ),
    Producto(
      id: '3',
      nombre: 'Rueda Cuadrada',
      categoria: 'Pieza',
      precio: 100000,
      cantidad: 2,
    ),
    Producto(
      id: '4',
      nombre: 'Ventana #6402',
      categoria: 'Vidrio',
      precio: 700000,
      cantidad: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPantallaGrande = anchoPantalla > 800;

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
              'Inventario',
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
          : const Drawer(child: MenuLateral(activo: 'Inventario')),
      body: Row(
        children: [
          if (esPantallaGrande)
            const ContenedorMenuLateral(activo: 'Inventario'),

          // CONTENIDO PRINCIPAL DEL INVENTARIO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón Añadir Producto
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Aquí irá la lógica para abrir un modal o página para crear producto
                      },
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text(
                        'AÑADIR PRODUCTO',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buscador
                  Container(
                    color: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'BUSCAR PRODUCTO EN INVENTARIO',
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.search, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Filtros
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.cases_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'PRODUCTOS EN BODEGA',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700], // Botón activo
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'PRODUCTOS FALTANTES',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400], // Botón inactivo
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // TABLA DE DATOS
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.red[400],
                          ),
                          border: TableBorder.all(
                            color: Colors.black,
                            width: 2,
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'PRODUCTO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'CATEGORÍA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'PRECIO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'CANTIDAD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'VER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          // Mapeamos la lista de objetos Producto a filas de la tabla
                          rows: productos.asMap().entries.map((entrada) {
                            int indice = entrada.key;
                            Producto producto = entrada.value;
                            // Alternar colores de las filas para imitar el diseño
                            Color? colorFila = indice % 2 == 0
                                ? Colors.grey[200]
                                : Colors.grey[300];

                            return DataRow(
                              color: MaterialStateProperty.all(colorFila),
                              cells: [
                                DataCell(
                                  Text(
                                    producto.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(Text(producto.categoria)),
                                DataCell(
                                  Text(
                                    '\$${producto.precio.toStringAsFixed(0)}',
                                  ),
                                ), // Formato de moneda
                                DataCell(Text(producto.cantidad.toString())),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.search, size: 30),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          // Aquí pasamos el objeto Producto a la nueva página
                                          builder: (context) =>
                                              PaginaEdicionProducto(
                                                producto: producto,
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
