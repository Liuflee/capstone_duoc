// Abre el registro independiente de productos.
import 'package:frenos_cerna/features/inventario/pagina_crear_producto.dart';
// Importa la barra superior común a las páginas.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
// Importa los campos de formulario reutilizables.

// Importa las cartas que conservan las acciones de la página.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
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
  final int? tipoId; // Conserva la categoría existente del esquema.

  Producto({
    required this.id,
    required this.nombre,
    required this.codigoBarra,
    required this.categoria,
    required this.precio,
    required this.cantidad,
    this.tipoId, // Permite editar la categoría sin añadir columnas.
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
      tipoId: (json['tipo'] as num?)?.toInt(), // Usa la clave de tipo_producto.
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

  bool _mostrarFaltantes =
      false; // Conserva la sección de inventario seleccionada.
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
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/products/new'),
        builder: (context) => const PaginaCrearProducto(),
      ),
    ); // Abre la página de registro del prototipo.
    if (actualizado == true && mounted) {
      await _cargarProductos(); // Conserva la actualización del inventario.
    }
  }

  // ============================================================
  // CONSTRUIR PÁGINA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;

    final esPantallaGrande =
        anchoPantalla >=
        700; // Comparte el punto de adaptación del menú principal.

    // Convierte los productos filtrados a registros que entiende TablaDatos.
    // El objeto original se conserva para usarlo al ver/editar el producto.
    final List<Map<String, dynamic>> filasProductos = _productosFiltrados
        .where((producto) => !_mostrarFaltantes || producto.cantidad == 0)
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
      appBar: PreferredSize(
        // Comparte el diez por ciento de altura con la página principal.
        preferredSize: Size.fromHeight(
          MediaQuery.sizeOf(context).height * 0.10,
        ),
        child: SizedBox(
          height:
              MediaQuery.sizeOf(context).height *
              0.10, // Mantiene la altura común de las barras.
          child: BarraSuperior(
            tituloPagina: 'Inventario',
          ), // Reutiliza el encabezado de Inicio.
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
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.12,
              child: MenuLateral(activo: 'Inventario'),
            ),

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

                    child: CartaNavegacion.accion(
                      // Conserva las medidas y la función de la acción original.
                      tipoBoton: 'elevated',

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
                  const SizedBox.shrink(),

                  // ==================================================
                  // SEPARACIÓN ENTRE BUSCADOR Y TABLA
                  // ==================================================
                  const SizedBox(height: 20),

                  // ==================================================
                  // BOTONES DE INVENTARIO
                  // ==================================================
                  Center(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10, // Conserva las medidas y pasa las acciones a otra fila en Android.
                      alignment: WrapAlignment.center,
                      children: [
                        CartaNavegacion.accion(
                          // Conserva las medidas y la función de la acción original.
                          tipoBoton: 'elevated',

                          onPressed: () =>
                              setState(() => _mostrarFaltantes = false),

                          icon: const Icon(
                            Icons.cases_outlined,
                            color: Colors.black,
                          ),

                          label: const Text(
                            'PRODUCTOS EN BODEGA',

                            style: TextStyle(color: Colors.black),
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mostrarFaltantes
                                ? const Color(0xFFB7B7B7)
                                : const Color(0xFFB74545),

                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        CartaNavegacion.accion(
                          // Conserva las medidas y la función de la acción original.
                          tipoBoton: 'elevated',

                          onPressed: () =>
                              setState(() => _mostrarFaltantes = true),

                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.black,
                          ),

                          label: const Text(
                            'PRODUCTOS SIN STOCK',

                            style: TextStyle(color: Colors.black),
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB7B7B7),

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

                            return CartaNavegacion.accion(
                              // Conserva las medidas y la función de la acción original.
                              tipoBoton: 'icon',

                              tooltip: 'Ver producto',
                              child: const Icon(Icons.search, size: 30),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaginaEdicionProducto(
                                      producto: producto,
                                    ),
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
