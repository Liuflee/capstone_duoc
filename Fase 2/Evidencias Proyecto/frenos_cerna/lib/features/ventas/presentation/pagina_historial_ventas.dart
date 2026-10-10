import 'package:flutter/material.dart';
import 'package:ferros_cerna/features/ventas/data/ventas_repository.dart';
import 'package:ferros_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:ferros_cerna/shared/widgets/menu_lateral.dart';

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

  // Controlador horizontal compartido
  final ScrollController _scrollHorizontal = ScrollController();

  // Controlador de búsqueda
  final TextEditingController _busquedaController = TextEditingController();

  // ============================================================
  // ANCHOS FIJOS DE LAS COLUMNAS
  // ============================================================

  // Se mantienen constantes para que la tabla NO cambie
  // de dimensiones al realizar una búsqueda.
  static const double _anchoCliente = 250;
  static const double _anchoProducto = 450;
  static const double _anchoTotal = 150;
  static const double _anchoFecha = 180;
  static const double _anchoVer = 100;

  // Espacio interno para separar el texto de las líneas
  // verticales de las columnas.
  static const double _paddingColumnas = 12;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();

    // Búsqueda automática mientras se escribe
    _busquedaController.addListener(_filtrarHistorial);
  }

  @override
  void dispose() {
    _scrollHorizontal.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    try {
      final data = await VentaRegistro.obtenerTodas();

      setState(() {
        _historial = data;
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

  // ============================================================
  // COLUMNAS DE LA TABLA
  // ============================================================

  List<DataColumn> _crearColumnas() {
    return const [
      DataColumn(
        label: SizedBox(
          width: _anchoCliente,
          child: Text(
            'CLIENTE',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: _anchoProducto,
          child: Padding(
            padding: EdgeInsets.only(left: _paddingColumnas),
            child: Text(
              'PRODUCTO',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: _anchoTotal,
          child: Padding(
            padding: EdgeInsets.only(left: _paddingColumnas),
            child: Text(
              'TOTAL',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: _anchoFecha,
          child: Padding(
            padding: EdgeInsets.only(left: _paddingColumnas),
            child: Text(
              'FECHA',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: _anchoVer,
          child: Text(
            'VER',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    ];
  }

  // ============================================================
  // FILAS DE LA TABLA
  // ============================================================

  List<DataRow> _crearFilas() {
    return _historialFiltrado.asMap().entries.map((entrada) {
      int indice = entrada.key;
      VentaHistorica venta = entrada.value;

      return DataRow(
        color: WidgetStateProperty.all(
          indice % 2 == 0 ? Colors.grey[200] : Colors.grey[300],
        ),
        cells: [
          DataCell(
            SizedBox(
              width: _anchoCliente,
              child: Text(
                venta.clienteNombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          DataCell(
            SizedBox(
              width: _anchoProducto,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: _paddingColumnas,
                  top: 10.0,
                  bottom: 10.0,
                ),
                child: Text(
                  venta.productosResumen,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),

          DataCell(
            SizedBox(
              width: _anchoTotal,
              child: Padding(
                padding: const EdgeInsets.only(left: _paddingColumnas),
                child: Text(
                  '\$${venta.total.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          DataCell(
            SizedBox(
              width: _anchoFecha,
              child: Padding(
                padding: const EdgeInsets.only(left: _paddingColumnas),
                child: Text(venta.fecha, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),

          DataCell(
            SizedBox(
              width: _anchoVer,
              child: IconButton(
                icon: const Icon(Icons.search, size: 40, color: Colors.black),
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
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  // ============================================================
  // TABLA
  // ============================================================

  Widget _crearTabla({bool ocultarEncabezado = false}) {
    return DataTable(
      headingRowColor: ocultarEncabezado
          ? WidgetStateProperty.all(Colors.transparent)
          : WidgetStateProperty.all(Colors.red[400]),
      headingRowHeight: ocultarEncabezado ? 0 : null,
      border: ocultarEncabezado
          ? const TableBorder(
              left: BorderSide(color: Colors.black, width: 2),
              right: BorderSide(color: Colors.black, width: 2),
              bottom: BorderSide(color: Colors.black, width: 2),
              horizontalInside: BorderSide(color: Colors.black, width: 2),
              verticalInside: BorderSide(color: Colors.black, width: 2),
            )
          : TableBorder.all(color: Colors.black, width: 2),
      dataRowMaxHeight: 100,

      // Mantiene las mismas dimensiones de columnas.
      columnSpacing: 0,

      columns: _crearColumnas(),
      rows: _crearFilas(),
    );
  }

  // ============================================================
  // ENCABEZADO FIJO
  // ============================================================

  Widget _crearEncabezadoFijo() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            controller: _scrollHorizontal,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: ClipRect(
              child: SizedBox(
                height: 56,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.red[400]),
                    headingRowHeight: 56,
                    border: const TableBorder(
                      top: BorderSide(color: Colors.black, width: 2),
                      left: BorderSide(color: Colors.black, width: 2),
                      right: BorderSide(color: Colors.black, width: 2),
                      verticalInside: BorderSide(color: Colors.black, width: 2),
                      horizontalInside: BorderSide(
                        color: Colors.transparent,
                        width: 0,
                      ),
                    ),
                    dataRowMaxHeight: 100,

                    // Mismo spacing que la tabla.
                    columnSpacing: 0,

                    // Mismas columnas y mismos anchos.
                    columns: _crearColumnas(),

                    // Se mantienen las filas para conservar
                    // exactamente las mismas dimensiones.
                    rows: _crearFilas(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
                      child: Stack(
                        children: [
                          // ============================================================
                          // CUERPO DE LA TABLA
                          // ============================================================

                          SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            padding: const EdgeInsets.only(top: 56),
                            child: SingleChildScrollView(
                              controller: _scrollHorizontal,
                              scrollDirection: Axis.horizontal,
                              child: _crearTabla(ocultarEncabezado: true),
                            ),
                          ),

                          // ============================================================
                          // ENCABEZADO FIJO
                          // ============================================================
                          _crearEncabezadoFijo(),
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
}
