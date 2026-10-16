import 'package:frenos_cerna/features/clientes/pagina_clientes.dart'; // Representa al cliente vinculado.
import 'package:frenos_cerna/features/clientes/pagina_ver_cliente.dart'; // Consulta el perfil sin permitir edición.
import 'package:frenos_cerna/core/data/supabase_database.dart'; // Recupera el cliente por su clave.
// Importa la tabla compartida para los registros de detalle.
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
// Importa la barra superior común a las páginas.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
// Importa las cartas que conservan las acciones de la página.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
import 'package:flutter/material.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';

// ============================================================================
// MODELO DE DATOS (Preparado para la tabla detalle_venta en Supabase)
// ============================================================================
class ItemVenta {
  final String idProducto;
  final String nombre;
  final double total;

  ItemVenta({
    required this.idProducto,
    required this.nombre,
    required this.total,
  });

  factory ItemVenta.fromJson(Map<String, dynamic> json) {
    return ItemVenta(
      idProducto: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Artículo',
      total: double.tryParse(json['total']?.toString() ?? '') ?? 0,
    );
  }
}

// ============================================================================
// INTERFAZ DE LA PÁGINA
// ============================================================================
class PaginaDetalleVenta extends StatefulWidget {
  final String idVenta;
  final String clienteNombre;
  final String vehiculoNombre;
  final double total;
  final String? fecha; // Será nulo si la venta está en proceso
  final bool desdeHistorial; // Para cambiar el texto del botón de retroceso

  final VentaRegistro?
  ventaInicial; // Permite mostrar el mismo detalle con datos locales.
  final bool
  esPendiente; // Distingue el historial pendiente del historial cerrado.
  final Widget?
  acciones; // Añade edición y pago únicamente a la vista pendiente.
  final String?
  rutCliente; // Identifica al cliente incluso si el detalle aún está cargando.
  final Cliente?
  clienteInicial; // Permite consultar una venta pendiente sin conexión.
  final Future<Cliente?> Function(String)?
  cargarCliente; // Permite comprobar la vinculación por RUT.
  final Future<List<VentaRegistro>> Function(String)?
  cargarHistorialCliente; // Permite verificar el perfil sin conexión real.
  const PaginaDetalleVenta({
    super.key,
    this.rutCliente,
    this.clienteInicial,
    this.cargarCliente,
    this.cargarHistorialCliente,
    this.ventaInicial, // Evita consultar una venta que aún no existe en Supabase.
    this.esPendiente = false, // Las ventas de la base ya están cerradas.
    this.acciones, // Conserva el historial cerrado sin acciones de edición.
    required this.idVenta,
    required this.clienteNombre,
    required this.vehiculoNombre,
    required this.total,
    this.fecha,
    required this.desdeHistorial,
  });

  @override
  State<PaginaDetalleVenta> createState() => _PaginaDetalleVentaState();
}

class _PaginaDetalleVentaState extends State<PaginaDetalleVenta> {
  // Datos de prueba simulando la consulta a la tabla detalle_venta
  List<ItemVenta> _items = [];
  bool _cargando = true;
  String? _error;
  VentaRegistro?
  _ventaCargada; // Conserva la relación de la venta con su cliente.
  bool _abriendoCliente = false; // Evita aperturas duplicadas del perfil.
  double? _totalCargado; // Presenta el total real confirmado por el servidor.

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    try {
      final venta =
          widget.ventaInicial ??
          await VentaRegistro.obtenerPorId(
            widget.idVenta,
          ); // Usa datos locales solo para pendientes.
      if (!mounted) return;
      setState(() {
        _ventaCargada =
            venta; // Conserva el RUT recuperado junto con el detalle.
        _items = venta.items.map(ItemVenta.fromJson).toList();
        _totalCargado =
            venta.total; // Refleja los precios registrados al cerrar.
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
    // Abre el perfil exacto del cliente de la venta.
    if (_abriendoCliente) return; // Evita abrir dos perfiles simultáneamente.
    setState(
      () => _abriendoCliente = true,
    ); // Bloquea el botón durante la consulta.
    try {
      // Conserva el detalle si no se puede recuperar el cliente.
      final rut =
          widget.rutCliente ??
          _ventaCargada?.rutCliente ??
          ''; // Usa la relación real; no busca por nombres repetidos.
      Cliente? cliente = widget.clienteInicial; // Permite consultar una pendiente local sin conexión.
      if (cliente == null && rut.isNotEmpty) {
        // Recupera los datos actuales del cliente registrado.
        if (widget.cargarCliente != null) {
          cliente = await widget.cargarCliente!(rut);
        } else {
          // Permite verificar la navegación con una fuente controlada.
          final datos = await SupabaseDatabase.client
              .from(SupabaseTables.clientes)
              .select('rut, nombre, fono, vehiculo_cliente(patente)')
              .eq('rut', int.parse(rut))
              .maybeSingle(); // Consulta la clave del cliente asociado.
          if (datos != null) {
            cliente = Cliente.fromJson(
              datos,
            ); // Conserva los vehículos registrados del perfil.
          }
        } // Finaliza la recuperación del cliente.
      } // Finaliza la resolución por RUT.
      if (!mounted) return; // Evita navegar desde una página cerrada.
      if (cliente == null) {
        throw StateError(
          'No se pudo identificar al cliente de esta venta.',
        ); // Informa relaciones ausentes sin abrir otro perfil.
      }
      final seleccionado =
          cliente; // Conserva el perfil consultado para la ruta.
      await Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/clients/view'),
          builder: (context) => PaginaVerCliente(
            cliente: seleccionado,
            cargarHistorial: widget.cargarHistorialCliente,
          ),
        ),
      ); // Abre una vista de consulta sin edición.
    } catch (error) {
      // Conserva el historial de venta ante fallos.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el cliente: $error')),
        ); // Muestra un error recuperable.
      }
    } finally {
      // Restablece el acceso al regresar del perfil.
      if (mounted) {
        setState(
          () => _abriendoCliente = false,
        ); // Habilita nuevamente la consulta.
      }
    } // Finaliza el acceso al cliente.
  } // Finaliza la navegación al perfil.

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande =
        MediaQuery.of(context).size.width >=
        700; // Comparte el punto de adaptación del menú principal.

    // Título dinámico
    final tituloPagina = widget.esPendiente
        ? 'Historial de venta pendiente'
        : 'Historial de venta'; // Distingue claramente el estado sin inventar fechas.

    final textoBotonVolver = widget.desdeHistorial
        ? 'VOLVER A HISTORIAL\nDE VENTAS'
        : 'VOLVER A VENTAS';

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
            tituloPagina: tituloPagina,
          ), // Reutiliza el encabezado de Inicio.
        ),
      ),
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Ventas')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande)
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.12,
              child: const MenuLateral(activo: 'Ventas'),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: esPantallaGrande
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _construirColumnaIzquierda(
                            context,
                            textoBotonVolver,
                          ),
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
                        _construirColumnaIzquierda(context, textoBotonVolver),
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
  // COLUMNA IZQUIERDA (Botón, Total y Tabla de Productos)
  // ============================================================================
  Widget _construirColumnaIzquierda(BuildContext context, String textoBoton) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BOTÓN VOLVER
        CartaNavegacion.accion(
          // Conserva las medidas y la función de la acción original.
          tipoBoton: 'elevated',

          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_return, color: Colors.black),
          label: Text(
            textoBoton,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB7B7B7),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
        const SizedBox(height: 40),

        // CAJA DE PRECIO TOTAL
        Container(
          color: Colors.red[400],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text(
            'PRECIO TOTAL:\$${(_totalCargado ?? widget.total).toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // TABLA DE PRODUCTOS
        if (_error != null)
          Text('Error al cargar el detalle: $_error')
        else if (_cargando)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            width: double.infinity,
            child: TablaDatos.desdeCeldas(
              headingRowColor: WidgetStateProperty.all(Colors.red[400]),
              border: TableBorder.all(color: Colors.black, width: 2),
              dataRowMaxHeight: 80,
              columns: const [
                DataColumn(
                  label: Text(
                    'PRODUCTO / SERVICIO',
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
              ],
              rows: _items.asMap().entries.map((entrada) {
                final indice = entrada.key;
                final item = entrada.value;
                return DataRow(
                  color: WidgetStateProperty.all(
                    indice % 2 == 0 ? Colors.grey[200] : Colors.grey[300],
                  ),
                  cells: [
                    DataCell(Text(item.nombre)),
                    DataCell(
                      Text(
                        '\$${item.total.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        if (widget.acciones != null) widget.acciones!, // Añade editar y confirmar exclusivamente al historial pendiente.
      ],
    );
  }

  // ============================================================================
  // COLUMNA DERECHA (Perfil del cliente y vehículo)
  // ============================================================================
  Widget _construirColumnaDerecha(BuildContext context) {
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

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
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
                      widget.clienteNombre,
                      style: const TextStyle(fontSize: 22, color: Colors.black),
                    ),
                  ],
                ),
              ),
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
                      widget.vehiculoNombre.replaceAll('\n', ' '),
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

          onPressed: _abriendoCliente ? null : _verCliente,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}
