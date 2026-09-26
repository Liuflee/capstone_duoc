import 'package:flutter/material.dart';
import 'package:ferros_cerna/data/supabase_database.dart';

// Asegúrate de importar el archivo donde definiste la clase Producto
import 'pagina_inventario.dart';
import 'menu_lateral.dart';

class PaginaEdicionProducto extends StatefulWidget {
  final Producto producto;

  const PaginaEdicionProducto({super.key, required this.producto});

  @override
  State<PaginaEdicionProducto> createState() => _PaginaEdicionProductoState();
}

class _PaginaEdicionProductoState extends State<PaginaEdicionProducto> {
  // Controladores para los campos de texto editables
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late String _categoriaSeleccionada;
  late int _cantidadActual;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Inicializamos los valores con los datos del producto recibido
    _nombreController = TextEditingController(
      text: widget.producto.codigoBarra,
    );
    _precioController = TextEditingController(
      text: widget.producto.precio.toStringAsFixed(0),
    );
    _categoriaSeleccionada = widget.producto.categoria;
    _cantidadActual = widget.producto.cantidad;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _guardarProducto() async {
    final precio = int.tryParse(_precioController.text.trim());
    if (precio == null || precio < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un precio entero válido.')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await SupabaseDatabase.client
          .from(SupabaseTables.productos)
          .update({
            'cod_barra': _nombreController.text.trim().isEmpty
                ? null
                : _nombreController.text.trim(),
            'precio': precio,
            'stock': _cantidadActual,
          })
          .eq('codigo_producto', int.parse(widget.producto.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Producto actualizado.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el producto: $error')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _borrarProducto() async {
    try {
      await SupabaseDatabase.client
          .from(SupabaseTables.productos)
          .delete()
          .eq('codigo_producto', int.parse(widget.producto.id));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar el producto: $error')),
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
            Text(
              '“${widget.producto.nombre}”',
              style: const TextStyle(
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
        crossAxisAlignment: CrossAxisAlignment.start, // Alinea el menú arriba
        children: [
          // MENÚ LATERAL (Fijo, no hace scroll)
          if (esPantallaGrande)
            const ContenedorMenuLateral(activo: 'Inventario'),

          // CONTENIDO PRINCIPAL (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              // Solo esta sección hace scroll
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Botón Volver
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      label: const Text(
                        'VOLVER A INVENTARIO',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botones Guardar y Borrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardarProducto,
                        icon: const Icon(Icons.download, color: Colors.black),
                        label: const Text(
                          'GUARDAR',
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
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _borrarProducto,
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'BORRAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    'DATOS EDITABLES DEL PRODUCTO',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Formulario de edición
                  _construirCampoEditable(
                    'CÓDIGO DE BARRA:',
                    _nombreController,
                    false,
                  ),
                  const SizedBox(height: 20),
                  _construirCampoEditable(
                    'PRECIO DE PRODUCTO:',
                    _precioController,
                    true,
                  ),
                  const SizedBox(height: 20),

                  // Categoría (Simulación de Dropdown)
                  const Text(
                    'CATEGORÍA DE PRODUCTO',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 400,
                    height: 50,
                    decoration: BoxDecoration(color: Colors.grey[300]),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              _categoriaSeleccionada,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        Container(
                          width: 50,
                          color: Colors.grey[400],
                          child: const Icon(Icons.arrow_drop_down, size: 40),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cantidad
                  const Text(
                    'CANTIDAD EN BODEGA ACTUAL:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 300,
                        height: 50,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: Text(
                          '$_cantidadActual',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _cantidadActual++; // Lógica temporal para aumentar
                          });
                        },
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text(
                          'REPONER\nCANTIDAD',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),

                  // Historial de ventas
                  const Text(
                    'HISTORIAL DE VENTAS DE PRODUCTO',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Tabla de historial (con scroll horizontal por si acaso)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.red[400]),
                      border: TableBorder.all(color: Colors.black, width: 2),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'CLIENTE',
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
                            'FECHA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'REVISAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      rows: [
                        DataRow(
                          color: WidgetStateProperty.all(Colors.grey[200]),
                          cells: [
                            const DataCell(
                              Text(
                                'BENJAMÍN\nPESCUEZO',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataCell(Text('\$20.000')),
                            const DataCell(Text('01/02/2002')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.search, size: 30),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                        DataRow(
                          color: WidgetStateProperty.all(Colors.grey[300]),
                          cells: [
                            const DataCell(
                              Text(
                                'LORENZO\nRAPANUI',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const DataCell(Text('\$22.000')),
                            const DataCell(Text('26/09/2001')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.search, size: 30),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // Widget para construir los campos de texto grises
  Widget _construirCampoEditable(
    String titulo,
    TextEditingController controlador,
    bool esPrecio,
  ) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          width: 400,
          color: Colors.grey[300],
          child: Row(
            children: [
              if (esPrecio)
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text('\$', style: TextStyle(fontSize: 18)),
                ),
              Expanded(
                child: TextField(
                  controller: controlador,
                  textAlign: esPrecio ? TextAlign.left : TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  style: const TextStyle(fontSize: 18),
                  keyboardType: esPrecio
                      ? TextInputType.number
                      : TextInputType.text,
                ),
              ),
              Container(
                color: Colors.grey[400],
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.edit_square, size: 30),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
