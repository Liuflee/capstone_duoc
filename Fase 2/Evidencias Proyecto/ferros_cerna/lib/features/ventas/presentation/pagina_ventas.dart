import 'package:flutter/material.dart';
import 'package:ferros_cerna/features/ventas/data/ventas_repository.dart';
import 'package:ferros_cerna/features/ventas/presentation/pagina_crear_ventas.dart';
import 'package:ferros_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:ferros_cerna/features/ventas/presentation/pagina_historial_ventas.dart';
import 'package:ferros_cerna/shared/widgets/menu_lateral.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    try {
      final data = await VentaRegistro.obtenerTodas();

      setState(() {
        ventasActivas = data;
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

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const double anchoTabla = 900;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,

                            child: SizedBox(
                              width: anchoTabla,

                              child: CustomScrollView(
                                slivers: [
                                  // ==================================
                                  // ENCABEZADO FIJO
                                  // ==================================

                                  SliverPersistentHeader(
                                    pinned: true,

                                    delegate: _EncabezadoVentasDelegate(
                                      child: _crearEncabezado(),
                                    ),
                                  ),

                                  // ==================================
                                  // FILAS
                                  // ==================================
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      indice,
                                    ) {
                                      final venta = ventasActivas[indice];

                                      return _crearFila(context, venta, indice);
                                    }, childCount: ventasActivas.length),
                                  ),
                                ],
                              ),
                            ),
                          );
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

  // ============================================================
  // ENCABEZADO DE LA TABLA
  // ============================================================

  Widget _crearEncabezado() {
    return Container(
      height: 56,
      color: Colors.red[400],

      child: Row(
        children: [
          // ========================================================
          // CLIENTE
          // ========================================================

          SizedBox(
            width: 200,
            height: 56,

            child: Container(
              alignment: Alignment.center,

              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black, width: 2),
                  top: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),

              child: const Text(
                'CLIENTE',

                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),

          // ========================================================
          // VEHÍCULO
          // ========================================================
          SizedBox(
            width: 200,
            height: 56,

            child: Container(
              alignment: Alignment.center,

              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black, width: 2),
                  top: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),

              child: const Text(
                'VEHÍCULO',

                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),

          // ========================================================
          // PRODUCTOS
          // ========================================================
          SizedBox(
            width: 400,
            height: 56,

            child: Container(
              alignment: Alignment.center,

              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black, width: 2),
                  top: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),

              child: const Text(
                'PRODUCTOS',

                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),

          // ========================================================
          // VER
          // ========================================================
          SizedBox(
            width: 100,
            height: 56,

            child: Container(
              alignment: Alignment.center,

              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black, width: 2),
                  right: BorderSide(color: Colors.black, width: 2),
                  top: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),

              child: const Text(
                'VER',

                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILA DE VENTA
  // ============================================================

  Widget _crearFila(BuildContext context, VentaEnProceso venta, int indice) {
    final color = indice % 2 == 0 ? Colors.grey[200] : Colors.grey[300];

    return Container(
      height: 120,
      color: color,

      child: Row(
        children: [
          // ========================================================
          // CLIENTE
          // ========================================================

          SizedBox(
            width: 200,
            height: 120,

            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),

              alignment: Alignment.centerLeft,

              padding: const EdgeInsets.symmetric(horizontal: 10),

              child: Row(
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

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========================================================
          // VEHÍCULO
          // ========================================================
          SizedBox(
            width: 200,
            height: 120,

            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),

              alignment: Alignment.center,

              child: Text(
                venta.vehiculoNombre,

                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),

          // ========================================================
          // PRODUCTOS
          // ========================================================
          SizedBox(
            width: 400,
            height: 120,

            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),

              alignment: Alignment.center,

              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),

              child: Text(
                venta.productosResumen,

                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          // ========================================================
          // VER
          // ========================================================
          SizedBox(
            width: 100,
            height: 120,

            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black, width: 2),
                  right: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),

              alignment: Alignment.center,

              child: IconButton(
                icon: const Icon(Icons.search, size: 40, color: Colors.black),

                onPressed: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) => PaginaDetalleVenta(
                        idVenta: venta.id,

                        clienteNombre: venta.clienteNombre.replaceAll(
                          '\n',
                          ' ',
                        ),

                        vehiculoNombre: venta.vehiculoNombre,

                        total: venta.total,

                        desdeHistorial: false,
                      ),
                    ),
                  );
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
// ENCABEZADO FIJO DE LA TABLA DE VENTAS
// ============================================================

class _EncabezadoVentasDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _EncabezadoVentasDelegate({required this.child});

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
  bool shouldRebuild(covariant _EncabezadoVentasDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
