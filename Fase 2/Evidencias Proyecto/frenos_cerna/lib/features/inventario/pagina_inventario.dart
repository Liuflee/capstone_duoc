import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/inventario/pagina_edicion_producto.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

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

// ============================================================
// PÁGINA INVENTARIO
// ============================================================

class PaginaInventario extends StatefulWidget {
  const PaginaInventario({super.key});

  @override
  State<PaginaInventario> createState() => _PaginaInventarioState();
}

class _PaginaInventarioState extends State<PaginaInventario> {
  // ==========================================================
  // VARIABLES
  // ==========================================================

  List<Producto> productos = [];

  bool _cargando = true;
  String? _error;

  final TextEditingController _busquedaController = TextEditingController();

  // Colores de cabecera que se alternan entre las columnas.
  static const Color _rojoClaro = Color.fromARGB(255, 253, 116, 116);
  static const Color _rojoOscuro = Color.fromARGB(255, 207, 81, 81);

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

  List<Producto> get _productosFiltrados {
    final texto = _normalizarTexto(_busquedaController.text.trim());

    if (texto.isEmpty) return productos;

    return productos.where((producto) {
      final nombre = _normalizarTexto(producto.nombre);
      final codigoBarra = _normalizarTexto(producto.codigoBarra);
      final id = _normalizarTexto(producto.id);
      final categoria = _normalizarTexto(producto.categoria);
      final precio = producto.precio.toStringAsFixed(0);

      return nombre.contains(texto) ||
          codigoBarra.contains(texto) ||
          id.contains(texto) ||
          categoria.contains(texto) ||
          precio.contains(texto);
    }).toList();
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
            (item) => Producto.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      setState(() {
        productos = listaProductos;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  // ============================================================
  // AGREGAR PRODUCTO
  // ============================================================

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

  // ============================================================
  // CONSTRUIR PÁGINA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;

    final esPantallaGrande = anchoPantalla > 800;

    // Convierte los productos filtrados a registros que entiende TablaDatos.
    // El objeto original se conserva para usarlo al ver/editar el producto.
    final List<Map<String, dynamic>> filasProductos = _productosFiltrados
        .map(
          (producto) => <String, dynamic>{
            'nombre': producto.nombre,
            'categoria': producto.categoria,
            'precio': '\$${producto.precio.toStringAsFixed(0)}',
            'cantidad': producto.cantidad.toString(),
            'producto': producto,
          },
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================
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

      // ========================================================
      // MENÚ LATERAL MÓVIL
      // ========================================================
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Inventario')),

      // ========================================================
      // CONTENIDO PRINCIPAL
      // ========================================================
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ======================================================
          // MENÚ LATERAL ESCRITORIO
          // ======================================================

          if (esPantallaGrande)
            const ContenedorMenuLateral(activo: 'Inventario'),

          // ======================================================
          // CONTENIDO INVENTARIO
          // ======================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // BOTÓN AÑADIR PRODUCTO
                  // ==================================================

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

                  // ==================================================
                  // BUSCADOR
                  // ==================================================
                  Container(
                    color: Colors.grey[200],

                    padding: const EdgeInsets.only(left: 10),

                    child: Row(
                      children: [
                        // ==========================================
                        // CAMPO DE BÚSQUEDA
                        // ==========================================

                        Expanded(
                          child: TextField(
                            controller: _busquedaController,

                            decoration: const InputDecoration(
                              hintText: 'BUSCAR PRODUCTO EN INVENTARIO',

                              border: InputBorder.none,
                            ),

                            // ========================================
                            // BÚSQUEDA AUTOMÁTICA
                            // ========================================
                            onChanged: (_) => setState(() {}),
                          ),
                        ),

                        // ==========================================
                        // LUPA DECORATIVA
                        // ==========================================
                        IconButton(
                          onPressed: null,

                          icon: const Icon(Icons.search, color: Colors.black),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // SEPARACIÓN ENTRE BUSCADOR Y TABLA
                  // ==================================================
                  const SizedBox(height: 20),

                  // ==================================================
                  // BOTONES DE INVENTARIO
                  // ==================================================
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,

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
                            backgroundColor: Colors.red[700],

                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

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
                            backgroundColor: Colors.grey[400],

                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // MENSAJE DE ERROR
                  // ==================================================
                  if (_error != null)
                    Text('Error al cargar inventario: $_error'),

                  // ==================================================
                  // CARGANDO / TABLA
                  // ==================================================
                  if (_cargando)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Expanded(
                      child: TablaDatos(
                        // Encabezados visibles de la tabla.
                        nombresColumnas: const [
                          'PRODUCTO',
                          'CATEGORÍA',
                          'PRECIO',
                          'CANTIDAD',
                          'VER',
                        ],

                        // Campos de cada columna (vacío si la celda es personalizada).
                        camposColumnas: const [
                          'nombre',
                          'categoria',
                          'precio',
                          'cantidad',
                          '',
                        ],

                        // Ancho proporcional de cada columna.
                        anchosColumnas: const [450, 180, 130, 130, 100],

                        // Colores de cabecera alternando entre los dos rojos.
                        coloresEncabezados: const [
                          _rojoClaro,
                          _rojoOscuro,
                          _rojoClaro,
                          _rojoOscuro,
                          _rojoClaro,
                        ],

                        filas: filasProductos,

                        celdasPersonalizadas: {
                          // Columna 0: nombre del producto en negrita.
                          0: (context, fila) {
                            final producto = fila['producto'] as Producto;

                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                producto.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },

                          // Columna 4: botón para ver/editar el producto.
                          4: (context, fila) {
                            final producto = fila['producto'] as Producto;

                            return IconButton(
                              tooltip: 'Ver producto',
                              icon: const Icon(Icons.search, size: 30),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaginaEdicionProducto(producto: producto),
                                  ),
                                );

                                // Recarga los productos después de editar.
                                if (!mounted) return;
                                await _cargarProductos();
                              },
                            );
                          },
                        },
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