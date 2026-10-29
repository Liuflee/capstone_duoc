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
// Importa el panel reutilizable que combina buscador y categorías.
import 'package:frenos_cerna/shared/widgets/panel_filtros.dart';

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
  final int?
  calidadId; // Conserva la calidad para precargar el formulario de edición.
  final int? tipoId; // Conserva la categoría existente del esquema.

  Producto({
    required this.id,
    required this.nombre,
    required this.codigoBarra,
    required this.categoria,
    required this.precio,
    required this.cantidad,
    this.calidadId, // Mantiene la calidad existente al editar.
    this.tipoId, // Permite editar la categoría sin añadir columnas.
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo_producto'];

    final codigo = json['codigo_producto']?.toString() ?? 'sin-codigo';

    final codigoBarra = json['cod_barra']?.toString() ?? '';

    return Producto(
      id: codigo,

      nombre: codigoBarra.isEmpty ? codigo : codigoBarra,

      codigoBarra: codigoBarra,

      categoria: tipo is Map
          ? (tipo['nombre_tipo'] ?? 'Sin categoría').toString()
          : (json['tipo']?.toString() ?? 'Sin categoría'),

      precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,

      cantidad: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      calidadId: (json['calidad'] as num?)
          ?.toInt(), // Recupera el identificador real de calidad.
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

  bool _cargando = true;
  String? _error;

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
  // CARGAR PRODUCTOS
  // ==========================================================

  Future<void> _cargarProductos() async {
    try {
      final response = await SupabaseDatabase.client
          .from(SupabaseTables.productos)
          .select(
            'codigo_producto, cod_barra, stock, tipo, calidad, precio, tipo_producto(nombre_tipo)',
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

                  Padding(
                    padding: const EdgeInsets.only(
                      right: margenDesplazamientoTabla,
                    ), // Alinea la acción con el borde visible de la tabla.
                    child: Align(
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
                  ), // Conserva el tamaño y la función del botón.
                  const SizedBox(
                    height: 20,
                  ), // Separa la acción de los filtros.
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
                      child: PanelFiltros<Producto>(
                        datos: productos, // Filtra el inventario completo.
                        textoAyuda: 'BUSCAR PRODUCTO, CÓDIGO O CATEGORÍA', // Describe la búsqueda disponible.
                        camposBusqueda: [
                          (producto) => producto.nombre, // Busca en el nombre.
                          (producto) => producto
                              .codigoBarra, // Busca en el código de barras.
                          (producto) =>
                              producto.id, // Busca en el código interno.
                          (producto) =>
                              producto.categoria, // Busca en la categoría.
                          (producto) => producto.precio.toStringAsFixed(
                            0,
                          ), // Permite buscar por precio.
                        ],
                        categorias: [
                          // Permite separar productos sin stock de los que están en bodega.
                          CategoriaFiltro<Producto>(
                            id: 'stock',
                            etiqueta: 'STOCK',
                            valor: (producto) => producto.cantidad == 0
                                ? 'SIN STOCK'
                                : 'EN BODEGA',
                          ),
                          // Muestra las categorías reales del inventario sin configurarlas a mano.
                          CategoriaFiltro<Producto>(
                            id: 'categoria',
                            etiqueta: 'CATEGORÍA',
                            valor: (producto) => producto.categoria,
                          ),
                        ],
                        child: (filtrados) {
                          // Convierte los productos filtrados a registros de TablaDatos.
                          // El objeto original se conserva para usarlo al ver/editar el producto.
                          final filasProductos = filtrados
                              .map(
                                (producto) => <String, dynamic>{
                                  'nombre': producto.nombre,
                                  'categoria': producto.categoria,
                                  'precio':
                                      '\$${producto.precio.toStringAsFixed(0)}',
                                  'cantidad': producto.cantidad.toString(),
                                  'producto': producto,
                                },
                              )
                              .toList();
                          return TablaDatos(
                            mostrarControles: false, // El panel ya muestra el buscador y las categorías.
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
                                        builder: (context) =>
                                            PaginaEdicionProducto(
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
                          ); // Finaliza la tabla construida con los productos filtrados.
                        }, // Finaliza la construcción del contenido.
                      ), // Finaliza el panel de filtros reutilizable.
                    ), // Finaliza el espacio restante de la página.
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
