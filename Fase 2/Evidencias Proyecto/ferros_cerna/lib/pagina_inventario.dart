import 'package:ferros_cerna/data/supabase_database.dart';
import 'package:ferros_cerna/pagina_edicion_producto.dart';
import 'package:flutter/material.dart';

import 'menu_lateral.dart';

class Producto {
  final String id;
  final String nombre;
  final String codigoBarra;
  final String categoria;
  final double precio;
  final int cantidad;

  Producto({
    required this.id,
    required this.nombre,
    required this.codigoBarra,
    required this.categoria,
    required this.precio,
    required this.cantidad,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo_producto'];
    final codigo = json['codigo_producto']?.toString() ?? 'sin-codigo';
    final codigoBarra = json['cod_barra']?.toString() ?? '';
    return Producto(
      id: codigo,
      nombre: codigoBarra.isEmpty ? 'Producto $codigo' : codigoBarra,
      codigoBarra: codigoBarra,
      categoria: tipo is Map
          ? (tipo['nombre_tipo'] ?? 'Sin categoría').toString()
          : (json['tipo']?.toString() ?? 'Sin categoría'),
      precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
      cantidad: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
    );
  }
}

class PaginaInventario extends StatefulWidget {
  const PaginaInventario({super.key});

  @override
  State<PaginaInventario> createState() => _PaginaInventarioState();
}

class _PaginaInventarioState extends State<PaginaInventario> {
  List<Producto> productos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final response = await SupabaseDatabase.client
          .from(SupabaseTables.productos)
          .select(
            'codigo_producto, cod_barra, stock, tipo, precio, tipo_producto(nombre_tipo)',
          )
          .order('codigo_producto');

      final data = response as List<dynamic>;
      setState(() {
        productos = data
            .map(
              (item) =>
                  Producto.fromJson(Map<String, dynamic>.from(item as Map)),
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

  Future<void> _agregarProducto() async {
    final codigoCtrl = TextEditingController();
    final barraCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final precioCtrl = TextEditingController();
    final valores = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Código producto'),
              ),
              TextField(
                controller: barraCtrl,
                decoration: const InputDecoration(labelText: 'Código de barra'),
              ),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock inicial'),
              ),
              TextField(
                controller: precioCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio entero'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final codigo = int.tryParse(codigoCtrl.text.trim());
              final stock = int.tryParse(stockCtrl.text.trim());
              final precio = int.tryParse(precioCtrl.text.trim());
              if (codigo == null ||
                  stock == null ||
                  precio == null ||
                  stock < 0 ||
                  precio < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Revisa los códigos, stock y precio.'),
                  ),
                );
                return;
              }
              Navigator.pop(context, {
                'codigo_producto': codigo,
                'cod_barra': barraCtrl.text.trim().isEmpty
                    ? null
                    : barraCtrl.text.trim(),
                'stock': stock,
                'precio': precio,
              });
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    codigoCtrl.dispose();
    barraCtrl.dispose();
    stockCtrl.dispose();
    precioCtrl.dispose();
    if (valores == null) return;

    try {
      await SupabaseDatabase.client
          .from(SupabaseTables.productos)
          .insert(valores);
      await _cargarProductos();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo añadir el producto: $error')),
      );
    }
  }

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
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _agregarProducto,
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

                  if (_error != null)
                    Text('Error al cargar inventario: $_error'),
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
                            rows: productos.asMap().entries.map((entrada) {
                              int indice = entrada.key;
                              Producto producto = entrada.value;
                              Color? colorFila = indice % 2 == 0
                                  ? Colors.grey[200]
                                  : Colors.grey[300];

                              return DataRow(
                                color: WidgetStateProperty.all(colorFila),
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
                                  ),
                                  DataCell(Text(producto.cantidad.toString())),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.search, size: 30),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PaginaEdicionProducto(
                                                  producto: producto,
                                                ),
                                          ),
                                        ).then((_) => _cargarProductos());
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
