import 'package:frenos_cerna/core/data/supabase_database.dart'; // Consulta el vínculo real entre vehículo y cliente.
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart'; // Construye el cliente recuperado.
import 'package:frenos_cerna/features/clientes/pagina_ver_cliente.dart'; // Abre la consulta del cliente vinculado.
// Importa la tabla compartida para los registros de detalle.
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
// Importa la barra superior común a las páginas.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
// Importa las cartas que conservan las acciones de la página.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
import 'package:flutter/material.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';

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

  Future<void> _verCliente() async {
    // Recupera el cliente por la relación del vehículo seleccionado.
    try {
      // Conserva la vista si el vehículo no tiene un cliente válido.
      final vehiculo = await SupabaseDatabase.client
          .from(SupabaseTables.vehiculos)
          .select('rut_cliente')
          .eq('patente', widget.vehiculo.id)
          .single(); // Consulta la patente exacta sin buscar por nombres repetidos.
      final datos = await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .select('rut, nombre, fono, vehiculo_cliente(patente)')
          .eq('rut', vehiculo['rut_cliente'])
          .single(); // Recupera la información del cliente vinculado.
      if (!mounted) return; // Evita navegar desde una página cerrada.
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/clients/view'),
          builder: (context) =>
              PaginaVerCliente(cliente: Cliente.fromJson(datos)),
        ),
      ); // Abre la página de consulta sin habilitar edición.
    } catch (error) {
      // Informa fallos reales sin abrir otro cliente.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo abrir el cliente del vehículo: $error',
            ),
          ),
        ); // Permite volver a intentarlo.
      }
    } // Finaliza la recuperación del perfil.
  } // Finaliza la ruta de Ver cliente.

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande =
        MediaQuery.of(context).size.width >=
        700; // Comparte el punto de adaptación del menú principal.

    // Limpiamos los saltos de línea del nombre del vehículo para el título
    final nombreVehiculoLimpio = widget.vehiculo.vehiculoNombre.replaceAll(
      '\n',
      ' ',
    );

    return Scaffold(
      backgroundColor: Colors.white,
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
            tituloPagina: nombreVehiculoLimpio,
          ), // Reutiliza el encabezado de Inicio.
        ),
      ),
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Vehiculos')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande)
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.12,
              child: const MenuLateral(activo: 'Vehiculos'),
            ),

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
        CartaNavegacion.accion(
          // Conserva las medidas y la función de la acción original.
          tipoBoton: 'elevated',

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
            backgroundColor: const Color(0xFFF2A0A0),
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
          'COMPRAS PARA VEHÍCULO',
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
            child: TablaDatos.desdeCeldas(
              headingRowColor: WidgetStateProperty.all(Colors.red[400]),
              border: TableBorder.all(color: Colors.black, width: 2),
              dataRowMaxHeight: 60,
              columns: const [
                DataColumn(
                  label: Text(
                    'PRODUCTOS / SERVICIOS',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'VER',
                    style: TextStyle(
                      color: Colors.black,
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
                        venta.productosResumen,
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
                      CartaNavegacion.accion(
                        // Conserva las medidas y la función de la acción original.
                        tipoBoton: 'icon',

                        child: const Icon(
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
          backgroundColor: const Color(0xFFD96363),
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

        CartaNavegacion.accion(
          // Conserva las medidas y la función de la acción original.
          tipoBoton: 'elevated',

          onPressed: _verCliente, // Abre el cliente real del vehículo.
          icon: const Icon(Icons.search, color: Colors.black, size: 30),
          label: const Text(
            'VER CLIENTE',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB7B7B7),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ],
    );
  }
}
