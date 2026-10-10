import 'package:flutter/material.dart';
import 'package:ferros_cerna/core/data/supabase_database.dart';
import 'package:ferros_cerna/shared/widgets/menu_lateral.dart';

// ============================================================================
// MODELOS DE DATOS (Preparados para Supabase)
// ============================================================================

class ProductoVenta {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;

  ProductoVenta({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
  });

  factory ProductoVenta.fromJson(Map<String, dynamic> json) {
    final codigo = json['codigo_producto']?.toString() ?? 'sin-codigo';
    final codigoBarra = json['cod_barra']?.toString() ?? '';
    final tipo = json['tipo_producto'];

    return ProductoVenta(
      id: codigo,
      nombre: codigoBarra.isEmpty ? 'Producto $codigo' : codigoBarra,
      categoria: tipo is Map
          ? (tipo['nombre_tipo'] ?? 'Sin categoría').toString()
          : (json['tipo']?.toString() ?? 'Sin categoría'),
      precio: double.tryParse(json['precio']?.toString() ?? '') ?? 0,
      stock: int.tryParse(json['stock']?.toString() ?? '') ?? 0,
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
  final _rutClienteCtrl = TextEditingController();
  final _patenteVehiculoCtrl = TextEditingController();

  // Controlador para la búsqueda de productos
  final _busquedaProductoCtrl = TextEditingController();

  final List<ProductoVenta> _inventario = [];

  bool _cargandoInventario = true;
  bool _guardando = false;
  String? _errorInventario;

  // Estado del carrito de compras actual
  final List<ProductoVenta> _carrito = [];

  // ==========================================================================
  // FILTRO DE INVENTARIO
  // ==========================================================================

  List<ProductoVenta> get _inventarioFiltrado {
    final texto = _normalizarTexto(_busquedaProductoCtrl.text.trim());

    // Si no hay texto de búsqueda, mostrar todo el inventario
    if (texto.isEmpty) {
      return _inventario;
    }

    // Buscar por nombre O categoría
    return _inventario.where((producto) {
      final nombre = _normalizarTexto(producto.nombre);
      final categoria = _normalizarTexto(producto.categoria);

      return nombre.contains(texto) || categoria.contains(texto);
    }).toList();
  }

  // ==========================================================================
  // NORMALIZAR TEXTO
  // ==========================================================================

  String _normalizarTexto(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  @override
  void initState() {
    super.initState();
    _cargarInventario();
  }

  Future<void> _cargarInventario() async {
    try {
      final data = await SupabaseDatabase.client
          .from(SupabaseTables.productos)
          .select(
            'codigo_producto, cod_barra, stock, tipo, precio, tipo_producto(nombre_tipo)',
          )
          .gt('stock', 0)
          .order('codigo_producto');

      if (!mounted) return;

      setState(() {
        _inventario
          ..clear()
          ..addAll(
            (data as List<dynamic>).map(
              (item) => ProductoVenta.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );

        _cargandoInventario = false;
        _errorInventario = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cargandoInventario = false;
        _errorInventario = error.toString();
      });
    }
  }

  // Getter para calcular el precio total dinámicamente
  double get _precioTotal =>
      _carrito.fold(0, (suma, item) => suma + item.precio);

  // ==========================================================================
  // FUNCIONES DE ESTADO
  // ==========================================================================

  void _agregarAlCarrito(ProductoVenta producto) {
    final cantidadEnCarrito = _carrito
        .where((item) => item.id == producto.id)
        .length;

    if (cantidadEnCarrito >= producto.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay más unidades disponibles.')),
      );
      return;
    }

    setState(() {
      _carrito.add(producto);
    });
  }

  Future<void> _registrarVenta() async {
    final rut = int.tryParse(_rutClienteCtrl.text.trim());

    if (rut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el RUT numérico del cliente.')),
      );
      return;
    }

    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto.')),
      );
      return;
    }

    final cantidades = <String, int>{};

    for (final producto in _carrito) {
      cantidades.update(
        producto.id,
        (cantidad) => cantidad + 1,
        ifAbsent: () => 1,
      );
    }

    setState(() => _guardando = true);

    try {
      await SupabaseDatabase.client.rpc(
        'registrar_venta',
        params: {
          'p_rut_cliente': rut,
          'p_patente_vehiculo': _patenteVehiculoCtrl.text.trim(),
          'p_iva': 19,
          'p_detalles': cantidades.entries
              .map(
                (entry) => {
                  'codigo_producto': int.parse(entry.key),
                  'cantidad': entry.value,
                },
              )
              .toList(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente.')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar la venta: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _removerDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
  }

  @override
  void dispose() {
    _rutClienteCtrl.dispose();
    _patenteVehiculoCtrl.dispose();
    _busquedaProductoCtrl.dispose();
    super.dispose();
  }

  // ==========================================================================
  // BUILD PRINCIPAL
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,

      // ======================================================================
      // APP BAR
      // ======================================================================
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
              'Registro de venta nueva',
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

      // ======================================================================
      // MENÚ LATERAL EN PANTALLAS PEQUEÑAS
      // ======================================================================
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Ventas')),

      // ======================================================================
      // CUERPO
      // ======================================================================
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================================
          // MENÚ LATERAL
          // ====================================================================

          if (esPantallaGrande)
            const SizedBox(width: 150, child: MenuLateral(activo: 'Ventas')),

          // ====================================================================
          // CONTENIDO PRINCIPAL
          // ====================================================================
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(30.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ======================================================
                      // SECCIÓN SUPERIOR: FORMULARIO Y CARRITO
                      // ======================================================

                      esPantallaGrande
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _construirFormularioCliente(context),
                                ),
                                const SizedBox(width: 40),
                                Expanded(
                                  flex: 1,
                                  child: _construirCarritoYTotal(),
                                ),
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

                      // ======================================================
                      // SECCIÓN INFERIOR: SELECCIÓN DE PRODUCTOS
                      // ======================================================
                      const Text(
                        'SELECCIÓN DE PRODUCTOS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ======================================================
                      // BARRA DE BÚSQUEDA
                      // ======================================================
                      Container(
                        width: double.infinity,
                        color: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _busquedaProductoCtrl,

                          // Filtrado automático al escribir
                          onChanged: (_) {
                            setState(() {});
                          },

                          decoration: InputDecoration(
                            hintText: 'BUSCAR PRODUCTO POR NOMBRE O CATEGORÍA',
                            border: InputBorder.none,
                            suffixIcon: Icon(
                              Icons.search,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ======================================================
                      // ESTADO DE CARGA / ERROR
                      // ======================================================
                      if (_errorInventario != null)
                        Text('Error al cargar inventario: $_errorInventario'),

                      if (_cargandoInventario)
                        const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ]),
                  ),
                ),

                // =================================================================
                // ENCABEZADO FIJO DE LA TABLA
                // =================================================================
                if (!_cargandoInventario && _errorInventario == null)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _EncabezadoTablaDelegate(),
                  ),

                // =================================================================
                // FILAS DE LA TABLA
                // =================================================================
                if (!_cargandoInventario && _errorInventario == null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final productosFiltrados = _inventarioFiltrado;
                          final producto = productosFiltrados[index];

                          return Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 80),
                            decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? Colors.grey[200]
                                  : Colors.grey[300],
                              border: const Border(
                                left: BorderSide(color: Colors.black, width: 2),
                                right: BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                ),
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  // =================================================
                                  // PRODUCTO
                                  // =================================================

                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          producto.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // =================================================
                                  // CATEGORÍA
                                  // =================================================
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          producto.categoria,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // =================================================
                                  // PRECIO
                                  // =================================================
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '\$${producto.precio.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // =================================================
                                  // AÑADIR
                                  // =================================================
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 35,
                                            color: Colors.black,
                                          ),
                                          onPressed: () =>
                                              _agregarAlCarrito(producto),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },

                        // =======================================================
                        // CANTIDAD DE RESULTADOS FILTRADOS
                        // =======================================================
                        childCount: _inventarioFiltrado.length,
                      ),
                    ),
                  ),

                // ===============================================================
                // ESPACIO INFERIOR
                // ===============================================================
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // WIDGET: FORMULARIO CLIENTE
  // ==========================================================================

  Widget _construirFormularioCliente(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_return, color: Colors.black),
          label: const Text(
            'VOLVER A VENTAS',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[200],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),

        const SizedBox(height: 50),

        const Text(
          'RUT DEL CLIENTE REGISTRADO:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        _ConstruirCampoEditable(
          hint: 'RUT numérico',
          controlador: _rutClienteCtrl,
        ),

        const SizedBox(height: 30),

        const Text(
          'PATENTE DEL VEHÍCULO (OPCIONAL):',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        _ConstruirCampoEditable(
          hint: 'Patente ya registrada',
          controlador: _patenteVehiculoCtrl,
        ),
      ],
    );
  }

  // ==========================================================================
  // WIDGET: CARRITO Y TOTAL
  // ==========================================================================

  Widget _construirCarritoYTotal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ======================================================================
        // CONTENEDOR DEL CARRITO
        // ======================================================================

        Container(
          height: 350,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            children: [
              // ==================================================================
              // CABECERA DEL CARRITO
              // ==================================================================

              Container(
                color: Colors.red[400],
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PRODUCTOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'REMOVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
              ),

              // ==================================================================
              // LISTA DE ITEMS EN EL CARRITO
              // ==================================================================
              Expanded(
                child: Container(
                  color: Colors.grey[300],
                  child: ListView.builder(
                    itemCount: _carrito.length,
                    itemBuilder: (context, index) {
                      final item = _carrito[index];

                      return Container(
                        color: index % 2 == 0
                            ? Colors.grey[200]
                            : Colors.grey[300],
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    item.nombre,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '\$${item.precio.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              width: 2,
                              height: 40,
                              color: Colors.black,
                            ),

                            const SizedBox(width: 15),

                            IconButton(
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                                size: 30,
                              ),
                              onPressed: () => _removerDelCarrito(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ==================================================================
              // TOTAL
              // ==================================================================
              Container(
                color: Colors.red[400],
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PRECIO TOTAL:\$${_precioTotal.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ======================================================================
        // BOTÓN REGISTRAR VENTA
        // ======================================================================
        ElevatedButton.icon(
          onPressed: _guardando ? null : _registrarVenta,
          icon: const Icon(Icons.download, color: Colors.black),
          label: const Text(
            'REGISTRAR VENTA',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// HEADER FIJO DE LA TABLA
// ============================================================================

class _EncabezadoTablaDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        color: Colors.red[400],
        child: Row(
          children: [
            // ================================================================
            // PRODUCTO
            // ================================================================

            const Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PRODUCTO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // ================================================================
            // CATEGORÍA
            // ================================================================
            Expanded(
              flex: 3,
              child: Container(
                height: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'CATEGORÍA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ================================================================
            // PRECIO
            // ================================================================
            Expanded(
              flex: 2,
              child: Container(
                height: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'PRECIO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ================================================================
            // AÑADIR
            // ================================================================
            Expanded(
              flex: 2,
              child: Container(
                height: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'AÑADIR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _EncabezadoTablaDelegate oldDelegate) {
    return false;
  }
}

// ============================================================================
// CAMPO EDITABLE
// ============================================================================

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
          ),
        ],
      ),
    );
  }
}
