import 'package:ferros_cerna/data/supabase_database.dart';
import 'package:ferros_cerna/pagina_edicion_producto.dart';
import 'package:flutter/material.dart';

import 'menu_lateral.dart';

// ============================================================
// MODELO PRODUCTO
// ============================================================

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

    final codigo =
        json['codigo_producto']?.toString() ?? 'sin-codigo';

    final codigoBarra =
        json['cod_barra']?.toString() ?? '';

    return Producto(
      id: codigo,

      nombre: codigoBarra.isEmpty
          ? 'Producto $codigo'
          : codigoBarra,

      codigoBarra: codigoBarra,

      categoria: tipo is Map
          ? (tipo['nombre_tipo'] ?? 'Sin categoría').toString()
          : (json['tipo']?.toString() ?? 'Sin categoría'),

      precio:
          double.tryParse(
                json['precio']?.toString() ?? '0',
              ) ??
              0,

      cantidad:
          int.tryParse(
                json['stock']?.toString() ?? '0',
              ) ??
              0,
    );
  }
}

// ============================================================
// PÁGINA INVENTARIO
// ============================================================

class PaginaInventario extends StatefulWidget {
  const PaginaInventario({super.key});

  @override
  State<PaginaInventario> createState() =>
      _PaginaInventarioState();
}

class _PaginaInventarioState
    extends State<PaginaInventario> {
  // ==========================================================
  // VARIABLES
  // ==========================================================

  List<Producto> productos = [];
  List<Producto> productosFiltrados = [];

  bool _cargando = true;
  String? _error;

  final TextEditingController _busquedaController =
      TextEditingController();

  // ==========================================================
  // INICIALIZACIÓN
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  // ==========================================================
  // LIBERAR CONTROLADORES
  // ==========================================================

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  // ==========================================================
  // NORMALIZAR TEXTO PARA BÚSQUEDA
  // ==========================================================

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

  // ==========================================================
  // CARGAR PRODUCTOS
  // ==========================================================

  Future<void> _cargarProductos() async {
    try {
      final response = await SupabaseDatabase.client
          .from(SupabaseTables.productos)
          .select(
            'codigo_producto, cod_barra, stock, tipo, precio, tipo_producto(nombre_tipo)',
          )
          .order('codigo_producto');

      final data = response as List<dynamic>;

      if (!mounted) return;

      final listaProductos = data
          .map(
            (item) => Producto.fromJson(
              Map<String, dynamic>.from(
                item as Map,
              ),
            ),
          )
          .toList();

      setState(() {
        productos = listaProductos;
        _cargando = false;
        _error = null;
      });

      // ========================================================
      // MANTENER EL FILTRO ACTUAL
      // ========================================================

      _buscarProductos();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  // ==========================================================
  // BUSCAR PRODUCTOS
  // ==========================================================

  void _buscarProductos() {
    final texto =
        _normalizarTexto(
          _busquedaController.text.trim(),
        );

    if (!mounted) return;

    setState(() {
      if (texto.isEmpty) {
        productosFiltrados =
            List.from(productos);
      } else {
        productosFiltrados =
            productos.where((producto) {
          // ==================================================
          // PRODUCTO
          // ==================================================

          final nombre =
              _normalizarTexto(
            producto.nombre,
          );

          final codigoBarra =
              _normalizarTexto(
            producto.codigoBarra,
          );

          final id =
              _normalizarTexto(
            producto.id,
          );

          // ==================================================
          // CATEGORÍA
          // ==================================================

          final categoria =
              _normalizarTexto(
            producto.categoria,
          );

          // ==================================================
          // PRECIO
          // ==================================================

          final precio =
              producto.precio
                  .toStringAsFixed(0);

          return nombre.contains(texto) ||
              codigoBarra.contains(texto) ||
              id.contains(texto) ||
              categoria.contains(texto) ||
              precio.contains(texto);
        }).toList();
      }
    });
  }

  // ============================================================
  // AGREGAR PRODUCTO
  // ============================================================

  Future<void> _agregarProducto() async {
    final codigoCtrl =
        TextEditingController();

    final barraCtrl =
        TextEditingController();

    final stockCtrl =
        TextEditingController(
      text: '0',
    );

    final precioCtrl =
        TextEditingController();

    final valores =
        await showDialog<Map<String, Object?>>(
      context: context,

      builder: (context) => AlertDialog(
        title:
            const Text('Añadir producto'),

        content:
            SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              TextField(
                controller:
                    codigoCtrl,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Código producto',
                ),
              ),

              TextField(
                controller:
                    barraCtrl,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Código de barra',
                ),
              ),

              TextField(
                controller:
                    stockCtrl,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Stock inicial',
                ),
              ),

              TextField(
                controller:
                    precioCtrl,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Precio entero',
                ),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),

            child:
                const Text('Cancelar'),
          ),

          TextButton(
            onPressed: () {
              final codigo =
                  int.tryParse(
                codigoCtrl.text.trim(),
              );

              final stock =
                  int.tryParse(
                stockCtrl.text.trim(),
              );

              final precio =
                  int.tryParse(
                precioCtrl.text.trim(),
              );

              if (codigo == null ||
                  stock == null ||
                  precio == null ||
                  stock < 0 ||
                  precio < 0) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Revisa los códigos, stock y precio.',
                    ),
                  ),
                );

                return;
              }

              Navigator.pop(
                context,
                {
                  'codigo_producto':
                      codigo,

                  'cod_barra':
                      barraCtrl.text
                              .trim()
                              .isEmpty
                          ? null
                          : barraCtrl.text
                              .trim(),

                  'stock': stock,

                  'precio': precio,
                },
              );
            },

            child:
                const Text('Registrar'),
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
          .from(
            SupabaseTables.productos,
          )
          .insert(valores);

      await _cargarProductos();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo añadir el producto: $error',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CONSTRUIR PÁGINA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final anchoPantalla =
        MediaQuery.of(context).size.width;

    final esPantallaGrande =
        anchoPantalla > 800;

    return Scaffold(
      backgroundColor:
          Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            Colors.grey[300],

        elevation: 0,

        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [
            if (esPantallaGrande)
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[500],

                    child: const Icon(
                      Icons
                          .settings_input_component,
                      color:
                          Colors.white,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  const Text(
                    'Frenos\nCerna',

                    style: TextStyle(
                      color:
                          Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

            const Text(
              'Inventario',

              style: TextStyle(
                color:
                    Colors.black,
                fontWeight:
                    FontWeight.bold,
                fontSize: 22,
              ),
            ),

            Row(
              children: [
                if (esPantallaGrande)
                  const Text(
                    'Leonardo',

                    style:
                        TextStyle(
                      color:
                          Colors.black,
                      fontSize: 16,
                    ),
                  ),

                const SizedBox(
                  width: 10,
                ),

                CircleAvatar(
                  backgroundColor:
                      Colors.red[800],

                  child: const Icon(
                    Icons.build,
                    color:
                        Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // ========================================================
      // MENÚ LATERAL MÓVIL
      // ========================================================

      drawer: esPantallaGrande
          ? null
          : const Drawer(
              child: MenuLateral(
                activo:
                    'Inventario',
              ),
            ),

      // ========================================================
      // CONTENIDO PRINCIPAL
      // ========================================================

      body: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ======================================================
          // MENÚ LATERAL ESCRITORIO
          // ======================================================

          if (esPantallaGrande)
            const ContenedorMenuLateral(
              activo:
                  'Inventario',
            ),

          // ======================================================
          // CONTENIDO INVENTARIO
          // ======================================================

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                20.0,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // ==================================================
                  // BOTÓN AÑADIR PRODUCTO
                  // ==================================================

                  Align(
                    alignment:
                        Alignment.centerRight,

                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _agregarProducto,

                      icon: const Icon(
                        Icons.add,
                        color:
                            Colors.black,
                      ),

                      label: const Text(
                        'AÑADIR PRODUCTO',

                        style:
                            TextStyle(
                          color:
                              Colors.black,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            Colors.grey[300],

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // BUSCADOR
                  // ==================================================

                  Container(
                    color:
                        Colors.grey[200],

                    padding:
                        const EdgeInsets
                            .only(
                      left: 10,
                    ),

                    child: Row(
                      children: [

                        // ==========================================
                        // CAMPO DE BÚSQUEDA
                        // ==========================================

                        Expanded(
                          child:
                              TextField(
                            controller:
                                _busquedaController,

                            decoration:
                                const InputDecoration(
                              hintText:
                                  'BUSCAR PRODUCTO EN INVENTARIO',

                              border:
                                  InputBorder.none,
                            ),

                            // ========================================
                            // BÚSQUEDA AUTOMÁTICA
                            // ========================================

                            onChanged:
                                (_) {
                              _buscarProductos();
                            },
                          ),
                        ),

                        // ==========================================
                        // LUPA DECORATIVA
                        // ==========================================

                        IconButton(
                          onPressed:
                              null,

                          icon:
                              const Icon(
                            Icons.search,
                            color:
                                Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // SEPARACIÓN ENTRE BUSCADOR Y TABLA
                  // ==================================================

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // BOTONES DE INVENTARIO
                  // ==================================================

                  Center(
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [

                        ElevatedButton
                            .icon(
                          onPressed:
                              () {},

                          icon:
                              const Icon(
                            Icons
                                .cases_outlined,
                            color:
                                Colors.white,
                          ),

                          label:
                              const Text(
                            'PRODUCTOS EN BODEGA',

                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                            ),
                          ),

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                Colors.red[700],

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  20,
                              vertical:
                                  15,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        ElevatedButton
                            .icon(
                          onPressed:
                              () {},

                          icon:
                              const Icon(
                            Icons
                                .warning_amber_rounded,
                            color:
                                Colors.black,
                          ),

                          label:
                              const Text(
                            'PRODUCTOS FALTANTES',

                            style:
                                TextStyle(
                              color:
                                  Colors.black,
                            ),
                          ),

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                Colors.grey[400],

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  20,
                              vertical:
                                  15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // MENSAJE DE ERROR
                  // ==================================================

                  if (_error != null)
                    Text(
                      'Error al cargar inventario: $_error',
                    ),

                  // ==================================================
                  // CARGANDO / TABLA
                  // ==================================================

                  if (_cargando)
                    const Expanded(
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    )
                  else
                    Expanded(
                      child:
                          _ConstruirTablaProductos(
                        productos:
                            productosFiltrados,

                        // ==================================================
                        // RECARGAR DESDE EL STATE PADRE
                        // ==================================================

                        onRecargar:
                            _cargarProductos,
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

// ============================================================
// TABLA DE PRODUCTOS
// ============================================================

class _ConstruirTablaProductos
    extends StatelessWidget {
  final List<Producto> productos;

  // ============================================================
  // FUNCIÓN DE RECARGA
  // ============================================================

  final Future<void> Function()
      onRecargar;

  const _ConstruirTablaProductos({
    required this.productos,
    required this.onRecargar,
  });

  // ============================================================
  // CONSTRUIR TABLA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        const double anchoMinimoTabla =
            850;

        final double anchoTabla =
            constraints.maxWidth >
                    anchoMinimoTabla
                ? constraints.maxWidth
                : anchoMinimoTabla;

        const double anchoCategoria =
            180;

        const double anchoPrecio =
            130;

        const double anchoCantidad =
            130;

        const double anchoVer =
            100;

        final double anchoProducto =
            anchoTabla -
                anchoCategoria -
                anchoPrecio -
                anchoCantidad -
                anchoVer;

        return SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,

          child: SizedBox(
            width: anchoTabla,

            child: CustomScrollView(
              slivers: [

                // ==================================================
                // ENCABEZADO FIJO
                // ==================================================

                SliverPersistentHeader(
                  pinned: true,

                  delegate:
                      _EncabezadoTablaDelegate(
                    child:
                        _crearEncabezado(
                      anchoProducto,
                      anchoCategoria,
                      anchoPrecio,
                      anchoCantidad,
                      anchoVer,
                    ),
                  ),
                ),

                // ==================================================
                // FILAS
                // ==================================================

                SliverList(
                  delegate:
                      SliverChildBuilderDelegate(
                    (
                      context,
                      index,
                    ) {
                      final producto =
                          productos[index];

                      return _crearFila(
                        context,
                        producto,
                        index,
                        anchoProducto,
                        anchoCategoria,
                        anchoPrecio,
                        anchoCantidad,
                        anchoVer,
                      );
                    },

                    childCount:
                        productos.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ENCABEZADO
  // ============================================================

  Widget _crearEncabezado(
    double anchoProducto,
    double anchoCategoria,
    double anchoPrecio,
    double anchoCantidad,
    double anchoVer,
  ) {
    return Container(
      color: Colors.red[400],

      child: Row(
        children: [

          SizedBox(
            width:
                anchoProducto,

            child: Container(
              height: 56,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  top: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  bottom:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.centerLeft,

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 12,
              ),

              child: const Text(
                'PRODUCTO',

                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),
            ),
          ),

          SizedBox(
            width:
                anchoCategoria,

            child: Container(
              height: 56,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  top: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  bottom:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: const Text(
                'CATEGORÍA',

                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),
            ),
          ),

          SizedBox(
            width:
                anchoPrecio,

            child: Container(
              height: 56,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  top: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  bottom:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: const Text(
                'PRECIO',

                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),
            ),
          ),

          SizedBox(
            width:
                anchoCantidad,

            child: Container(
              height: 56,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  top: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  bottom:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: const Text(
                'CANTIDAD',

                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),
            ),
          ),

          SizedBox(
            width:
                anchoVer,

            child: Container(
              height: 56,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  right:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  top: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  bottom:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: const Text(
                'VER',

                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILA DE PRODUCTO
  // ============================================================

  Widget _crearFila(
    BuildContext context,
    Producto producto,
    int index,
    double anchoProducto,
    double anchoCategoria,
    double anchoPrecio,
    double anchoCantidad,
    double anchoVer,
  ) {
    final Color? colorFila =
        index % 2 == 0
            ? Colors.grey[200]
            : Colors.grey[300];

    return Container(
      height: 70,
      color: colorFila,

      child: Row(
        children: [

          SizedBox(
            width:
                anchoProducto,

            child: Container(
              height: 70,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  bottom:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.centerLeft,

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 10,
              ),

              child: Text(
                producto.nombre,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),
            ),
          ),

          SizedBox(
            width:
                anchoCategoria,

            child: Container(
              height: 70,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  bottom:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 8,
              ),

              child: Text(
                producto.categoria,

                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          ),

          SizedBox(
            width:
                anchoPrecio,

            child: Container(
              height: 70,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  bottom:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: Text(
                '\$${producto.precio.toStringAsFixed(0)}',
              ),
            ),
          ),

          SizedBox(
            width:
                anchoCantidad,

            child: Container(
              height: 70,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  bottom:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: Text(
                producto.cantidad
                    .toString(),
              ),
            ),
          ),

          SizedBox(
            width:
                anchoVer,

            child: Container(
              height: 70,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  right: BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),

                  bottom:
                      BorderSide(
                    color:
                        Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: IconButton(
                icon: const Icon(
                  Icons.search,
                  size: 30,
                ),

                onPressed: () async {
                  await Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder:
                          (context) =>
                              PaginaEdicionProducto(
                        producto:
                            producto,
                      ),
                    ),
                  );

                  // ==================================================
                  // RECARGAR PRODUCTOS DESPUÉS DE EDITAR
                  // ==================================================

                  await onRecargar();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ENCABEZADO FIJO DE LA TABLA
// ============================================================

class _EncabezadoTablaDelegate
    extends SliverPersistentHeaderDelegate {
  final Widget child;

  _EncabezadoTablaDelegate({
    required this.child,
  });

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
    return child;
  }

  @override
  bool shouldRebuild(
    covariant _EncabezadoTablaDelegate
        oldDelegate,
  ) {
    return oldDelegate.child != child;
  }
}