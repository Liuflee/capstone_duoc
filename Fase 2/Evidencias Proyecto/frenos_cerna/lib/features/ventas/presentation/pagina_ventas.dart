import 'package:flutter/material.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_historial_ventas.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

typedef VentaEnProceso = VentaRegistro;

class PaginaVentas extends StatefulWidget {
  const PaginaVentas({super.key});

  @override
  State<PaginaVentas> createState() => _PaginaVentasState();
}

class _PaginaVentasState extends State<PaginaVentas> {
  List<VentaEnProceso> ventasActivas = [];
  bool _cargando = true;
  String? _error;

  // Colores de cabecera que se alternan entre las columnas.
  static const Color _rojoClaro = Color.fromARGB(255, 253, 116, 116);
  static const Color _rojoOscuro = Color.fromARGB(255, 207, 81, 81);

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    try {
      final data = await VentaRegistro.obtenerTodas();

      if (!mounted) return;

      setState(() {
        ventasActivas = data;
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

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    // Convierte las ventas a registros que entiende TablaDatos.
    // El objeto original se conserva para usarlo al ver el detalle.
    final List<Map<String, dynamic>> filasVentas = ventasActivas
        .map(
          (venta) => <String, dynamic>{
            'cliente': venta.clienteNombre,
            'vehiculo': venta.vehiculoNombre,
            'productos': venta.productosResumen,
            'venta': venta,
          },
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,

        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            // ======================================================
            // LOGO Y NOMBRE
            // ======================================================

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

            // ======================================================
            // TÍTULO
            // ======================================================
            const Text(
              'Ventas',

              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),

            // ======================================================
            // USUARIO
            // ======================================================
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

      // ============================================================
      // MENÚ LATERAL MÓVIL
      // ============================================================
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Ventas')),

      // ============================================================
      // CUERPO
      // ============================================================
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ========================================================
          // MENÚ LATERAL ESCRITORIO
          // ========================================================

          if (esPantallaGrande)
            const SizedBox(width: 150, child: MenuLateral(activo: 'Ventas')),

          // ========================================================
          // CONTENIDO PRINCIPAL
          // ========================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  // ==================================================
                  // BOTONES SUPERIORES
                  // ==================================================

                  Wrap(
                    spacing: 40,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,

                    children: [
                      // ==============================================
                      // REGISTRAR VENTA
                      // ==============================================

                      InkWell(
                        onTap: () async {
                          final registrada = await Navigator.push<bool>(
                            context,

                            MaterialPageRoute(
                              builder: (context) => const PaginaCrearVenta(),
                            ),
                          );

                          if (registrada == true) {
                            _cargarVentas();
                          }
                        },

                        child: Container(
                          width: 350,
                          height: 120,

                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(15),
                          ),

                          padding: const EdgeInsets.all(20),

                          child: const Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 70,
                                color: Colors.black87,
                              ),

                              SizedBox(width: 15),

                              Expanded(
                                child: Text(
                                  'REGISTRAR\nVENTA NUEVA',

                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ==============================================
                      // HISTORIAL
                      // ==============================================
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (context) =>
                                  const PaginaHistorialVentas(),
                            ),
                          );
                        },

                        child: Container(
                          width: 350,
                          height: 120,

                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),

                          padding: const EdgeInsets.all(20),

                          child: const Row(
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 70,
                                color: Colors.black87,
                              ),

                              SizedBox(width: 15),

                              Expanded(
                                child: Text(
                                  'HISTORIAL\nDE VENTAS',

                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // ==================================================
                  // TÍTULO
                  // ==================================================
                  const Text(
                    'VENTAS EN PROCESO',

                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // ERROR
                  // ==================================================
                  if (_error != null) Text('Error al cargar ventas: $_error'),

                  // ==================================================
                  // CARGANDO
                  // ==================================================
                  if (_cargando)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  // ==================================================
                  // TABLA
                  // ==================================================
                  else
                    Expanded(
                      child: Padding(
                        // Compensa los 14 px que TablaDatos reserva a la
                        // derecha para el scrollbar, así queda centrada.
                        padding: const EdgeInsets.only(left: 14),
                        child: TablaDatos(
                          // Encabezados visibles de la tabla.
                          nombresColumnas: const [
                            'CLIENTE',
                            'VEHÍCULO',
                            'PRODUCTOS',
                            'VER',
                          ],

                          // Campos de cada columna (vacío si la celda es personalizada).
                          camposColumnas: const [
                            'cliente',
                            'vehiculo',
                            'productos',
                            '',
                          ],

                          // Ancho proporcional de cada columna.
                          anchosColumnas: const [200, 200, 400, 100],

                          // Colores de cabecera alternando entre los dos rojos.
                          coloresEncabezados: const [
                            _rojoClaro,
                            _rojoOscuro,
                            _rojoClaro,
                            _rojoOscuro,
                          ],

                          // Las filas de ventas son más altas que el valor por defecto.
                          altoFila: 120,

                          filas: filasVentas,

                          celdasPersonalizadas: {
                            // Columna 0: cliente con avatar.
                            0: (context, fila) {
                              final venta = fila['venta'] as VentaEnProceso;

                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.red[300],
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: Colors.black,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      venta.clienteNombre,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },

                            // Columna 1: vehículo.
                            1: (context, fila) {
                              final venta = fila['venta'] as VentaEnProceso;

                              return Text(
                                venta.vehiculoNombre,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 18),
                              );
                            },

                            // Columna 2: resumen de productos.
                            2: (context, fila) {
                              final venta = fila['venta'] as VentaEnProceso;

                              return Text(
                                venta.productosResumen,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              );
                            },

                            // Columna 3: botón para ver el detalle de la venta.
                            3: (context, fila) {
                              final venta = fila['venta'] as VentaEnProceso;

                              return IconButton(
                                tooltip: 'Ver venta',
                                icon: const Icon(
                                  Icons.search,
                                  size: 40,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaginaDetalleVenta(
                                        idVenta: venta.id,
                                        clienteNombre: venta.clienteNombre
                                            .replaceAll('\n', ' '),
                                        vehiculoNombre: venta.vehiculoNombre,
                                        total: venta.total,
                                        desdeHistorial: false,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          },
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