import 'package:flutter/material.dart';
import 'package:ferros_cerna/features/ventas/data/ventas_repository.dart';
import 'package:ferros_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:ferros_cerna/features/vehiculos/pagina_vehiculos.dart';
import 'package:ferros_cerna/shared/widgets/menu_lateral.dart';

// ============================================================================
// INTERFAZ DE LA PÁGINA
// ============================================================================
class PaginaDetalleVehiculo extends StatefulWidget {
  final HistorialVehiculo vehiculo;

  const PaginaDetalleVehiculo({super.key, required this.vehiculo});

  @override
  State<PaginaDetalleVehiculo> createState() => _PaginaDetalleVehiculoState();
}

class _PaginaDetalleVehiculoState extends State<PaginaDetalleVehiculo> {
  List<VentaRegistro> _ventas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    try {
      final ventas = await VentaRegistro.obtenerPorPatente(widget.vehiculo.id);
      if (!mounted) return;
      setState(() {
        _ventas = ventas;
        _cargando = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    // Limpiamos los saltos de línea del nombre del vehículo para el título
    final nombreVehiculoLimpio = widget.vehiculo.vehiculoNombre.replaceAll(
      '\n',
      ' ',
    );

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
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            // Título dinámico basado en la imagen
            Expanded(
              child: Text(
                '“$nombreVehiculoLimpio” de “${widget.vehiculo.clienteNombre}”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis,
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
          : const Drawer(child: MenuLateral(activo: 'Vehiculos')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande)
            const SizedBox(width: 150, child: MenuLateral(activo: 'Vehiculos')),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              // Usamos Flex (Row o Column) dependiendo del tamaño de la pantalla
              child: esPantallaGrande
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _construirColumnaIzquierda(context),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 2,
                          child: _construirColumnaDerecha(context),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _construirColumnaIzquierda(context),
                        const SizedBox(height: 40),
                        _construirColumnaDerecha(context),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // COLUMNA IZQUIERDA (Botón, Detalles de servicio, Tabla de compras)
  // ============================================================================
  Widget _construirColumnaIzquierda(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_return, color: Colors.black),
          label: const Text(
            'VOLVER A HISTORIAL',
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
        const SizedBox(height: 30),

        // El esquema solo conserva el kilometraje actual del vehículo.
        Container(
          width: double.infinity,
          color: Colors.grey[300],
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KILOMETRAJE: ${widget.vehiculo.total.toStringAsFixed(0)} km',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        const Text(
          'VENTAS DEL VEHÍCULO',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        if (_error != null)
          Text('Error al cargar ventas: $_error')
        else if (_cargando)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.red[400]),
              border: TableBorder.all(color: Colors.black, width: 2),
              dataRowMaxHeight: 60,
              columns: const [
                DataColumn(
                  label: Text(
                    'VENTA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'VER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              rows: _ventas.asMap().entries.map((entrada) {
                final indice = entrada.key;
                final venta = entrada.value;
                return DataRow(
                  color: WidgetStateProperty.all(
                    indice % 2 == 0 ? Colors.grey[200] : Colors.grey[300],
                  ),
                  cells: [
                    DataCell(
                      Text(
                        '#${venta.id}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    DataCell(
                      Text(
                        '\$${venta.total.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          size: 30,
                          color: Colors.black,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaginaDetalleVenta(
                              idVenta: venta.id,
                              clienteNombre: venta.clienteNombre,
                              vehiculoNombre: venta.vehiculoNombre,
                              total: venta.total,
                              fecha: venta.fecha,
                              desdeHistorial: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ============================================================================
  // COLUMNA DERECHA (Perfil del cliente y vehículo)
  // ============================================================================
  Widget _construirColumnaDerecha(BuildContext context) {
    final nombreVehiculoLimpio = widget.vehiculo.vehiculoNombre.replaceAll(
      '\n',
      ' ',
    );

    return Column(
      children: [
        CircleAvatar(
          radius: 70,
          backgroundColor: Colors.red[400],
          child: const Icon(
            Icons.person_outline,
            size: 80,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),

        // Tarjeta de información del cliente y vehículo
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              // Sección superior (Roja)
              Container(
                width: double.infinity,
                color: Colors.red[400],
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NOMBRE DE CLIENTE:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.vehiculo.clienteNombre,
                      style: const TextStyle(fontSize: 22, color: Colors.black),
                    ),
                  ],
                ),
              ),
              // Sección inferior (Gris)
              Container(
                width: double.infinity,
                color: Colors.grey[400],
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TIPO DE AUTO:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nombreVehiculoLimpio,
                      style: const TextStyle(fontSize: 22, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        ElevatedButton.icon(
          onPressed: () {
            // Lógica para redirigir a la página de edición del cliente
          },
          icon: const Icon(Icons.search, color: Colors.black, size: 30),
          label: const Text(
            'VER CLIENTE',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ],
    );
  }
}
