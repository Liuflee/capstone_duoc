import 'package:ferros_cerna/data/supabase_database.dart';
import 'package:flutter/material.dart';

import 'menu_lateral.dart';
import 'pagina_detalle_vehiculo.dart';

class HistorialVehiculo {
  final String id;
  final String clienteNombre;
  final String vehiculoNombre;
  final double total;
  final String fecha;

  HistorialVehiculo({
    required this.id,
    required this.clienteNombre,
    required this.vehiculoNombre,
    required this.total,
    required this.fecha,
  });

  factory HistorialVehiculo.fromJson(Map<String, dynamic> json) {
    final clienteMap = json['cliente'];
    final modeloMap = json['modelo_vehiculo'];
    final marcaMap =
        modeloMap is Map ? modeloMap['marca_vehiculo'] : null;

    final nombreCliente = clienteMap is Map
        ? (clienteMap['nombre'] ?? 'Sin cliente')
        : (json['rut_cliente'] ?? 'Sin cliente');

    final partesVehiculo = [
      if (marcaMap is Map) marcaMap['marca'],
      if (modeloMap is Map) modeloMap['modelo'],
    ].where(
      (parte) => parte != null && parte.toString().isNotEmpty,
    );

    final patente = json['patente']?.toString() ?? 'Sin patente';

    return HistorialVehiculo(
      id: patente,
      clienteNombre: nombreCliente.toString(),
      vehiculoNombre: partesVehiculo.isEmpty
          ? patente
          : '${partesVehiculo.join(' ')} ($patente)',
      total: double.tryParse(
            json['kilometraje']?.toString() ?? '0',
          ) ??
          0,
      fecha: patente,
    );
  }
}

class PaginaVehiculos extends StatefulWidget {
  const PaginaVehiculos({super.key});

  @override
  State<PaginaVehiculos> createState() => _PaginaVehiculosState();
}

class _PaginaVehiculosState extends State<PaginaVehiculos> {
  List<HistorialVehiculo> historial = [];
  bool _cargando = true;
  String? _error;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  Future<void> _cargarVehiculos() async {
    try {
      final response = await SupabaseDatabase.client
          .from(SupabaseTables.vehiculos)
          .select(
            'patente, kilometraje, rut_cliente, cliente(nombre), '
            'modelo_vehiculo(modelo, marca_vehiculo(marca))',
          )
          .order('patente');

      final data = response as List<dynamic>;

      setState(() {
        historial = data
            .map(
              (item) => HistorialVehiculo.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();

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

  List<HistorialVehiculo> get _vehiculosFiltrados {
    if (_busqueda.trim().isEmpty) {
      return historial;
    }

    final busqueda = _busqueda.trim().toLowerCase();

    return historial.where((registro) {
      final cliente =
          registro.clienteNombre.toLowerCase();

      final vehiculo =
          registro.vehiculoNombre.toLowerCase();

      final patente =
          registro.fecha.toLowerCase();

      return cliente.contains(busqueda) ||
          vehiculo.contains(busqueda) ||
          patente.contains(busqueda);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande =
        MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
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
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            const Text(
              'Historial Vehículos',
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
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.red[800],
                  child: const Icon(
                    Icons.build,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: esPantallaGrande
          ? null
          : const Drawer(
              child: MenuLateral(activo: 'Vehiculos'),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande)
            const SizedBox(
              width: 150,
              child: MenuLateral(activo: 'Vehiculos'),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 350,
                    color: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    child: TextField(
                      onChanged: (valor) {
                        setState(() {
                          _busqueda = valor;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText:
                            'BUSCAR CLIENTE, VEHÍCULO O PATENTE',
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
                  if (_error != null)
                    Text(
                      'Error al cargar vehículos: $_error',
                    ),
                  if (_cargando)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Expanded(
                      child: _TablaVehiculos(
                        historial: _vehiculosFiltrados,
                        onRevisar: (registro) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PaginaDetalleVehiculo(
                                vehiculo: registro,
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
}

class _TablaVehiculos extends StatelessWidget {
  final List<HistorialVehiculo> historial;
  final void Function(HistorialVehiculo) onRevisar;

  const _TablaVehiculos({
    required this.historial,
    required this.onRevisar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double anchoMinimoTabla = 850;

        final double anchoTabla =
            constraints.maxWidth > anchoMinimoTabla
                ? constraints.maxWidth
                : anchoMinimoTabla;

        const double anchoVehiculo = 230;
        const double anchoKilometraje = 150;
        const double anchoPatente = 150;
        const double anchoRevisar = 120;

        final double anchoCliente = anchoTabla -
            anchoVehiculo -
            anchoKilometraje -
            anchoPatente -
            anchoRevisar -
            4;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: anchoTabla,
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate:
                      _EncabezadoTablaVehiculosDelegate(
                    child: _crearEncabezado(
                      anchoCliente,
                      anchoVehiculo,
                      anchoKilometraje,
                      anchoPatente,
                      anchoRevisar,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final registro = historial[index];

                      return _crearFila(
                        registro,
                        index,
                        anchoCliente,
                        anchoVehiculo,
                        anchoKilometraje,
                        anchoPatente,
                        anchoRevisar,
                      );
                    },
                    childCount: historial.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _crearEncabezado(
    double anchoCliente,
    double anchoVehiculo,
    double anchoKilometraje,
    double anchoPatente,
    double anchoRevisar,
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.red[400],
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          _celdaEncabezado(
            'CLIENTE',
            anchoCliente,
            tieneBordeDerecho: true,
          ),
          _celdaEncabezado(
            'VEHÍCULO',
            anchoVehiculo,
            tieneBordeDerecho: true,
          ),
          _celdaEncabezado(
            'KILOMETRAJE',
            anchoKilometraje,
            tieneBordeDerecho: true,
          ),
          _celdaEncabezado(
            'PATENTE',
            anchoPatente,
            tieneBordeDerecho: true,
          ),
          _celdaEncabezado(
            'REVISAR',
            anchoRevisar,
            tieneBordeDerecho: false,
          ),
        ],
      ),
    );
  }

  Widget _celdaEncabezado(
    String texto,
    double ancho, {
    required bool tieneBordeDerecho,
  }) {
    return Container(
      width: ancho,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: tieneBordeDerecho
            ? const Border(
                right: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
              )
            : null,
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _crearFila(
    HistorialVehiculo registro,
    int indice,
    double anchoCliente,
    double anchoVehiculo,
    double anchoKilometraje,
    double anchoPatente,
    double anchoRevisar,
  ) {
    final Color colorFila =
        indice % 2 == 0
            ? Colors.grey[200]!
            : Colors.grey[300]!;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: colorFila,
        border: const Border(
          left: BorderSide(
            color: Colors.black,
            width: 2,
          ),
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
      child: Row(
        children: [
          Container(
            width: anchoCliente,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red[300],
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    registro.clienteNombre,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: anchoVehiculo,
            height: double.infinity,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              registro.vehiculoNombre,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Container(
            width: anchoKilometraje,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              registro.total.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Container(
            width: anchoPatente,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              registro.fecha,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(
            width: anchoRevisar,
            height: double.infinity,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.search,
                  size: 35,
                  color: Colors.black,
                ),
                onPressed: () => onRevisar(registro),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoTablaVehiculosDelegate
    extends SliverPersistentHeaderDelegate {
  final Widget child;

  _EncabezadoTablaVehiculosDelegate({
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
    covariant _EncabezadoTablaVehiculosDelegate oldDelegate,
  ) {
    return false;
  }
}