import 'package:flutter/material.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

typedef VentaHistorica = VentaRegistro;

class PaginaHistorialVentas extends StatefulWidget {
  const PaginaHistorialVentas({super.key});

  @override
  State<PaginaHistorialVentas> createState() => _PaginaHistorialVentasState();
}

class _PaginaHistorialVentasState extends State<PaginaHistorialVentas> {
  List<VentaHistorica> _historial = [];

  bool _cargando = true;
  String? _error;

  // Controlador de búsqueda
  final TextEditingController _busquedaController = TextEditingController();

  // Colores de cabecera que se alternan entre las columnas.
  static const Color _rojoClaro = Color.fromARGB(255, 253, 116, 116);
  static const Color _rojoOscuro = Color.fromARGB(255, 207, 81, 81);

  @override
  void initState() {
    super.initState();
    _cargarHistorial();

    // Búsqueda automática mientras se escribe
    _busquedaController.addListener(_filtrarHistorial);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    try {
      final data = await VentaRegistro.obtenerTodas();

      if (!mounted) return;

      setState(() {
        _historial = data;
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
  // FILTRO DE BÚSQUEDA
  // ============================================================

  List<VentaHistorica> get _historialFiltrado {
    final texto = _busquedaController.text.trim().toLowerCase();

    if (texto.isEmpty) return _historial;

    return _historial.where((venta) {
      final cliente = venta.clienteNombre.toLowerCase();
      final fecha = venta.fecha.toLowerCase();

      return cliente.contains(texto) || fecha.contains(texto);
    }).toList();
  }

  void _filtrarHistorial() => setState(() {});

  String _formatearTotal(double total) {
    return '\$${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    // Convierte las ventas filtradas a registros que entiende TablaDatos.
    // El objeto original se conserva para usarlo al ver el detalle.
    final List<Map<String, dynamic>> filasHistorial = _historialFiltrado
        .map(
          (venta) => <String, dynamic>{
            'cliente': venta.clienteNombre,
            'producto': venta.productosResumen,
            'total': _formatearTotal(venta.total),
            'fecha': venta.fecha,
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
              'Historial de ventas',
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
          : const Drawer(child: MenuLateral(activo: 'Ventas')),

      // ============================================================
      // CUERPO
      // ============================================================
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande)
            const SizedBox(width: 150, child: MenuLateral(activo: 'Ventas')),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================================
                  // BOTÓN VOLVER
                  // ============================================================

                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.keyboard_return,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'VOLVER A VENTAS',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[200],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============================================================
                  // BUSCADOR
                  // ============================================================
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 350,
                      color: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: _busquedaController,
                        decoration: const InputDecoration(
                          hintText: 'BUSCAR FECHA O CLIENTE',
                          border: InputBorder.none,
                          suffixIcon: Icon(
                            Icons.search,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============================================================
                  // ERROR
                  // ============================================================
                  if (_error != null)
                    Text('Error al cargar historial: $_error'),

                  // ============================================================
                  // TABLA
                  // ============================================================
                  if (_cargando)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
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
                            'PRODUCTO',
                            'TOTAL',
                            'FECHA',
                            'VER',
                          ],

                          // Campos de cada columna (vacío si la celda es personalizada).
                          camposColumnas: const [
                            'cliente',
                            'producto',
                            'total',
                            'fecha',
                            '',
                          ],

                          // Ancho proporcional de cada columna.
                          anchosColumnas: const [250, 450, 150, 180, 100],

                          // Colores de cabecera alternando entre los dos rojos.
                          coloresEncabezados: const [
                            _rojoClaro,
                            _rojoOscuro,
                            _rojoClaro,
                            _rojoOscuro,
                            _rojoClaro,
                          ],

                          // Altura de fila similar a la original.
                          altoFila: 100,

                          filas: filasHistorial,

                          celdasPersonalizadas: {
                            // Columna 0: cliente en negrita.
                            0: (context, fila) {
                              final venta = fila['venta'] as VentaHistorica;

                              return Text(
                                venta.clienteNombre,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              );
                            },

                            // Columna 1: resumen de productos.
                            1: (context, fila) {
                              final venta = fila['venta'] as VentaHistorica;

                              return Text(
                                venta.productosResumen,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              );
                            },

                            // Columna 2: total en negrita.
                            2: (context, fila) {
                              return Text(
                                fila['total'] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },

                            // Columna 3: fecha.
                            3: (context, fila) {
                              return Text(
                                fila['fecha'] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18),
                              );
                            },

                            // Columna 4: botón para ver el detalle de la venta.
                            4: (context, fila) {
                              final venta = fila['venta'] as VentaHistorica;

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
                                        clienteNombre: venta.clienteNombre,
                                        vehiculoNombre: 'Vehículo Registrado',
                                        total: venta.total,
                                        fecha: venta.fecha,
                                        desdeHistorial: true,
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