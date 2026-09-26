import 'package:flutter/material.dart';
import 'menu_lateral.dart'; // Importa tu menú lateral compartido

// ============================================================================
// MODELOS DE DATOS (Preparados para Supabase)
// ============================================================================

class ProductoVenta {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;

  ProductoVenta({required this.id, required this.nombre, required this.categoria, required this.precio});

  factory ProductoVenta.fromJson(Map<String, dynamic> json) {
    return ProductoVenta(
      id: json['id'].toString(),
      nombre: json['nombre'],
      categoria: json['categoria'],
      precio: double.parse(json['precio'].toString()),
    );
  }
}

// ============================================================================
// INTERFAZ DE LA PÁGINA
// ============================================================================
class PaginaCrearVenta extends StatefulWidget {
  const PaginaCrearVenta({super.key});

  @override
  State<PaginaCrearVenta> createState() => _PaginaCrearVentaState();
}

class _PaginaCrearVentaState extends State<PaginaCrearVenta> {
  // Controladores de texto para el formulario del cliente
  final _nombreClienteCtrl = TextEditingController();
  final _numeroClienteCtrl = TextEditingController();
  final _vehiculoCtrl = TextEditingController();

  // Lista simulando los productos disponibles en la base de datos (Inventario)
  final List<ProductoVenta> _inventario = [
    ProductoVenta(id: '1', nombre: 'RUEDA GORDA', categoria: 'PIEZA', precio: 200000),
    ProductoVenta(id: '2', nombre: 'VENTANA CHICA', categoria: 'VIDRIO', precio: 200000),
    ProductoVenta(id: '3', nombre: 'ÁRBOLSITO DE\nAROMA', categoria: 'MISCELANEO', precio: 200000),
    ProductoVenta(id: '4', nombre: 'ACTUALIZADOR\nEVAPORADOR', categoria: 'PIEZA', precio: 10000),
    ProductoVenta(id: '5', nombre: 'VENTANA CUADRADA\nACHICADA DOTADA', categoria: 'VIDRIO', precio: 100000),
  ];

  // Estado del carrito de compras actual
  final List<ProductoVenta> _carrito = [];

  // Getter para calcular el precio total dinámicamente
  double get _precioTotal => _carrito.fold(0, (suma, item) => suma + item.precio);

  // Funciones de estado
  void _agregarAlCarrito(ProductoVenta producto) {
    setState(() {
      _carrito.add(producto);
    });
  }

  void _removerDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
  }

  @override
  void dispose() {
    _nombreClienteCtrl.dispose();
    _numeroClienteCtrl.dispose();
    _vehiculoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 900;

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
            const Text('Registro de venta nueva', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  // SECCIÓN SUPERIOR: Formulario y Carrito
                  esPantallaGrande 
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: _construirFormularioCliente(context)),
                          const SizedBox(width: 40),
                          Expanded(flex: 1, child: _construirCarritoYTotal()),
                        ],
                      )
                    : Column(
                        children: [
                          _construirFormularioCliente(context),
                          const SizedBox(height: 40),
                          _construirCarritoYTotal(),
                        ],
                      ),
                  
                  const SizedBox(height: 50),
                  
                  // SECCIÓN INFERIOR: Selección de productos
                  const Text('SELECCIÓN DE PRODUCTOS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  Container(
                    width: double.infinity,
                    color: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'BUSCAR PRODUCTO EN INVENTARIO',
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.search, color: Colors.black, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // TABLA DE INVENTARIO
                  SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.red[400]),
                      border: TableBorder.all(color: Colors.black, width: 2),
                      dataRowMaxHeight: 80,
                      columns: const [
                        DataColumn(label: Text('PRODUCTO', style: TextStyle(color: Colors.white, fontSize: 18))),
                        DataColumn(label: Text('CATEGORÍA', style: TextStyle(color: Colors.white, fontSize: 18))),
                        DataColumn(label: Text('PRECIO', style: TextStyle(color: Colors.white, fontSize: 18))),
                        DataColumn(label: Text('AÑADIR', style: TextStyle(color: Colors.white, fontSize: 18))),
                      ],
                      rows: _inventario.asMap().entries.map((entrada) {
                        int indice = entrada.key;
                        ProductoVenta producto = entrada.value;
                        return DataRow(
                          color: MaterialStateProperty.all(indice % 2 == 0 ? Colors.grey[200] : Colors.grey[300]),
                          cells: [
                            DataCell(Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            DataCell(Text(producto.categoria, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            DataCell(Text('\$${producto.precio.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 35, color: Colors.black),
                                onPressed: () => _agregarAlCarrito(producto),
                              )
                            ),
                          ],
                        );
                      }).toList(),
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

  // ============================================================================
  // WIDGETS INTERNOS
  // ============================================================================

  Widget _construirFormularioCliente(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_return, color: Colors.black),
          label: const Text('VOLVER A VENTAS', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[200],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
        const SizedBox(height: 50),
        
        const Text('NOMBRE DEL CLIENTE NUEVO:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _ConstruirCampoEditable(hint: 'Editar Nombre', controlador: _nombreClienteCtrl),
        const SizedBox(height: 30),
        
        const Text('NÚMERO DEL CLIENTE NUEVO:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _ConstruirCampoEditable(hint: 'Editar Número', controlador: _numeroClienteCtrl),
        const SizedBox(height: 30),
        
        const Text('NOMBRE DEL VEHÍCULO:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _ConstruirCampoEditable(hint: 'Editar Vehículo', controlador: _vehiculoCtrl),
      ],
    );
  }

  Widget _construirCarritoYTotal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // CONTENEDOR DEL CARRITO
        Container(
          height: 350,
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
          child: Column(
            children: [
              // Cabecera del carrito
              Container(
                color: Colors.red[400],
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: const Row(
                  children: [
                    Expanded(child: Text('PRODUCTOS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                    Text('REMOVER', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                  ],
                ),
              ),
              // Lista de items en el carrito
              Expanded(
                child: Container(
                  color: Colors.grey[300],
                  child: ListView.builder(
                    itemCount: _carrito.length,
                    itemBuilder: (context, index) {
                      final item = _carrito[index];
                      return Container(
                        color: index % 2 == 0 ? Colors.grey[200] : Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(item.nombre, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    '\$${item.precio.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}', 
                                    style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold, fontSize: 14)
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 2, height: 40, color: Colors.black), // Divisor vertical
                            const SizedBox(width: 15),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 30),
                              onPressed: () => _removerDelCarrito(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Total
              Container(
                color: Colors.red[400],
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PRECIO TOTAL:\$${_precioTotal.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}', 
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // BOTÓN REGISTRAR VENTA
        ElevatedButton.icon(
          onPressed: () {
            // Lógica para enviar a Supabase:
            // 1. Crear Venta
            // 2. Iterar _carrito y guardar en detalle_venta
          },
          icon: const Icon(Icons.download, color: Colors.black),
          label: const Text('REGISTRAR VENTA', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          ),
        ),
      ],
    );
  }
}

class _ConstruirCampoEditable extends StatelessWidget {
  final TextEditingController? controlador;
  final String? hint;

  const _ConstruirCampoEditable({this.controlador, this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey[300],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controlador,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            color: Colors.grey[400],
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.edit_square, size: 30),
          )
        ],
      ),
    );
  }
}