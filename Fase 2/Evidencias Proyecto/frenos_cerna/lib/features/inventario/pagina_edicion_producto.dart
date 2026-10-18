// Consulta el historial real sin depender de fechas inexistentes.
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
// Importa la tabla compartida para los registros de detalle.
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
// Importa la barra superior común a las páginas.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
// Importa los campos de formulario reutilizables.
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';
// Importa las cartas que conservan las acciones de la página.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';

// Asegúrate de importar el archivo donde definiste la clase Producto
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';

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
  List<VentaRegistro> _ventasProducto =
      []; // Conserva las compras reales de este producto.
  String? _errorHistorial; // Informa los fallos del historial.
  int? _tipoSeleccionado; // Conserva la categoría real.
  List<Map<String, dynamic>> _categorias =
      []; // Conserva las categorías existentes.
  Future<void> _cargarComplementos() async {
    try {
      final ventas = await VentaRegistro.obtenerTodas();
      final categorias = await SupabaseDatabase.client
          .from(SupabaseTables.tiposProducto)
          .select('id, nombre_tipo');
      if (mounted) {
        setState(() {
          _ventasProducto = ventas
              .where(
                (venta) => venta.items.any(
                  (item) => item['codigo'] == widget.producto.id,
                ),
              )
              .toList();
          _categorias = List<Map<String, dynamic>>.from(categorias);
        });
      }
    } catch (error) {
      if (mounted) setState(() => _errorHistorial = error.toString());
    }
  } // Recupera únicamente datos del esquema autorizado.

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
    _tipoSeleccionado = widget.producto.tipoId;
    _cargarComplementos(); // Consulta categoría e historial.
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
      await SupabaseDatabase.client.from(SupabaseTables.productos).update({
        'cod_barra': _nombreController.text.trim().isEmpty
            ? null
            : _nombreController.text.trim(),
        'precio': precio,
        'stock': _cantidadActual,
        if (_tipoSeleccionado != null)
          'tipo': _tipoSeleccionado, // Guarda la categoría seleccionada.
      }).eq('codigo_producto', widget.producto.id);
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

  Future<void> _eliminarProducto() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('ELIMINAR PRODUCTO'),
        content: Text('¿Eliminar el producto ${widget.producto.id}?'),
        actions: [
          CartaNavegacion.accion(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('CANCELAR'),
          ),
          CartaNavegacion.accion(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _guardando = true);
    try {
      final detalles = await SupabaseDatabase.client
          .from(SupabaseTables.detallesVentaProducto)
          .select('id')
          .eq('codigo_producto', widget.producto.id)
          .limit(1);
      if (detalles.isNotEmpty) {
        throw StateError(
          'No se puede eliminar: el producto aparece en ventas registradas.',
        );
      }
      await SupabaseDatabase.client
          .from(SupabaseTables.productos)
          .delete()
          .eq('codigo_producto', widget.producto.id)
          .select('codigo_producto')
          .single();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el producto: $error')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPantallaGrande = anchoPantalla >=
        700; // Comparte el punto de adaptación del menú principal.

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        // Comparte el diez por ciento de altura con la página principal.
        preferredSize: Size.fromHeight(
          MediaQuery.sizeOf(context).height * 0.10,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height *
              0.10, // Mantiene la altura común de las barras.
          child: BarraSuperior(
            tituloPagina: 'Edición de producto',
          ), // Reutiliza el encabezado de Inicio.
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
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.12,
              child: MenuLateral(activo: 'Inventario'),
            ),

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
                    child: CartaNavegacion.accion(
                      // Conserva las medidas y la función de la acción original.
                      tipoBoton: 'elevated',

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

                  // Acción para guardar los cambios
                  Wrap(
                    spacing: 10,
                    runSpacing:
                        10, // Conserva las medidas y pasa las acciones a otra fila en Android.
                    alignment: WrapAlignment.center,
                    children: [
                      CartaNavegacion.accion(
                        // Conserva las medidas y la función de la acción original.
                        tipoBoton: 'elevated',

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
                          backgroundColor: const Color(0xFFB7B7B7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                      ),
                      CartaNavegacion.accion(
                        tipoBoton: 'elevated',
                        onPressed: _guardando ? null : _eliminarProducto,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'ELIMINAR',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD96363),
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
                  DropdownButtonFormField<int>(
                    initialValue: _tipoSeleccionado,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFD9D9D9),
                    ),
                    items: [
                      if (_tipoSeleccionado != null &&
                          !_categorias.any(
                            (fila) => fila['id'] == _tipoSeleccionado,
                          ))
                        DropdownMenuItem(
                          value: _tipoSeleccionado,
                          child: Text(_categoriaSeleccionada),
                        ),
                      for (final fila in _categorias)
                        DropdownMenuItem(
                          value: (fila['id'] as num).toInt(),
                          child: Text(fila['nombre_tipo'].toString()),
                        ),
                    ],
                    onChanged: _guardando
                        ? null
                        : (valor) => setState(() => _tipoSeleccionado = valor),
                  ),
                  const SizedBox(height: 20),

                  // Cantidad
                  const Text(
                    'CANTIDAD EN BODEGA ACTUAL:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing:
                        10, // Conserva las medidas y pasa las acciones a otra fila en Android.
                    alignment: WrapAlignment.center,
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
                      CartaNavegacion.accion(
                        // Conserva las medidas y la función de la acción original.
                        tipoBoton: 'elevated',

                        onPressed: () {
                          setState(() {
                            _cantidadActual++; // Aumenta el stock editable que se persiste al pulsar Guardar
                          });
                        },
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text(
                          'REPONER\nCANTIDAD',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB7B7B7),
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

                  if (_errorHistorial != null)
                    Text(
                      'No se pudo cargar el historial: $_errorHistorial',
                    ), // Conserva el error de consulta.
                  // Tabla de historial con las columnas disponibles.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: TablaDatos.desdeCeldas(
                      headingRowColor: WidgetStateProperty.all(Colors.red[400]),
                      border: TableBorder.all(color: Colors.black, width: 2),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'CLIENTE',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'PRECIO',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'REVISAR',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      rows: _ventasProducto
                          .map(
                            (venta) => DataRow(
                              cells: [
                                DataCell(Text(venta.clienteNombre)),
                                DataCell(
                                  Text(
                                    venta.items
                                        .where(
                                          (item) =>
                                              item['codigo'] ==
                                              widget.producto.id,
                                        )
                                        .fold<double>(
                                          0,
                                          (total, item) =>
                                              total +
                                              (item['total'] as num).toDouble(),
                                        )
                                        .toStringAsFixed(0),
                                  ),
                                ),
                                DataCell(
                                  CartaNavegacion.accion(
                                    tipoBoton: 'icon',
                                    child: const Icon(Icons.search, size: 30),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PaginaDetalleVenta(
                                          idVenta: venta.id,
                                          clienteNombre: venta.clienteNombre,
                                          vehiculoNombre: venta.vehiculoNombre,
                                          total: venta.total,
                                          desdeHistorial: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
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
    // Comparte el formulario manteniendo el ancho anterior del campo.
    return FormularioDatos(
      ancho: 400,
      campos: [
        CampoFormularioDatos(
          controlador: controlador,
          etiqueta: titulo,
          textoAyuda: esPrecio ? 'Precio' : 'Nombre',
          tipoTeclado: esPrecio ? TextInputType.number : TextInputType.text,
          habilitado: !_guardando,
        ),
      ],
    );
  }
}
