import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:frenos_cerna/features/clientes/pagina_ver_cliente.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/detalle_venta_vista.dart';
import 'package:material_ui/material_ui.dart';

class PaginaDetalleVenta extends StatefulWidget {
  final String idVenta;
  final String clienteNombre;
  final String vehiculoNombre;
  final double total;
  final String? fecha;
  final bool desdeHistorial;
  final VentaRegistro? ventaInicial;
  final bool esPendiente;
  final Widget? acciones;
  final String? rutCliente;
  final Cliente? clienteInicial;
  final Future<Cliente?> Function(String)? cargarCliente;
  final Future<List<VentaRegistro>> Function(String)? cargarHistorialCliente;

  const PaginaDetalleVenta({
    super.key,
    this.rutCliente,
    this.clienteInicial,
    this.cargarCliente,
    this.cargarHistorialCliente,
    this.ventaInicial,
    this.esPendiente = false,
    this.acciones,
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
  VentaRegistro? _ventaCargada;
  bool _cargando = true;
  bool _abriendoCliente = false;
  String? _error;

  String get _rutCliente {
    final rut = widget.rutCliente ?? _ventaCargada?.rutCliente ?? '';
    return rut.isEmpty ? _ventaCargada?.rutCliente ?? '' : rut;
  }

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    try {
      final venta =
          widget.ventaInicial ??
          await VentaRegistro.obtenerPorId(widget.idVenta);
      if (!mounted) return;
      setState(() {
        _ventaCargada = venta;
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
    if (_abriendoCliente) return;
    setState(() => _abriendoCliente = true);
    try {
      final cliente = widget.clienteInicial ?? await _buscarCliente();
      if (!mounted) return;
      if (cliente == null) {
        throw StateError('No se pudo identificar al cliente de esta venta.');
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/clients/view'),
          builder: (_) => PaginaVerCliente(
            cliente: cliente,
            cargarHistorial: widget.cargarHistorialCliente,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el cliente: $error')),
      );
    } finally {
      if (mounted) setState(() => _abriendoCliente = false);
    }
  }

  Future<Cliente?> _buscarCliente() async {
    final rut = _rutCliente;
    if (rut.isEmpty) return null;
    if (widget.cargarCliente case final cargar?) return cargar(rut);
    final datos = await SupabaseDatabase.client
        .from(SupabaseTables.clientes)
        .select('rut, nombre, fono, vehiculo_cliente(patente)')
        .eq('rut', int.parse(rut))
        .maybeSingle();
    return datos == null ? null : Cliente.fromJson(datos);
  }

  Widget? _estadoDetalle() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error case final error?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Error al cargar el detalle: $error'),
          TextButton(
            onPressed: () {
              setState(() => _cargando = true);
              _cargarDetalles();
            },
            child: const Text('Reintentar'),
          ),
        ],
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final venta = _ventaCargada;
    final vehiculo = (venta?.vehiculoNombre ?? widget.vehiculoNombre)
        .replaceAll('\n', ' ')
        .trim();
    return PaginaTematica(
      builder: (_) => DetalleVentaVista(
        titulo: widget.esPendiente
            ? 'Venta pendiente'
            : widget.desdeHistorial
            ? 'Historial de venta'
            : 'Detalle de venta',
        estado: widget.esPendiente ? 'Pendiente de pago' : 'Venta cerrada',
        total: venta?.total ?? widget.total,
        cliente: (venta?.clienteNombre ?? widget.clienteNombre).replaceAll(
          '\n',
          ' ',
        ),
        rut: _rutCliente,
        vehiculo: vehiculo.isEmpty || vehiculo == 'Sin vehículo'
            ? 'Sin vehículo asociado'
            : vehiculo,
        tituloLista: 'Productos y servicios',
        lineas: [
          for (final item in venta?.items ?? const [])
            LineaDetalleVenta(
              nombre: item['nombre']?.toString() ?? 'Artículo',
              codigo: item['codigo']?.toString() ?? '',
              subtotal: double.tryParse(item['total']?.toString() ?? '') ?? 0,
            ),
        ],
        verCliente:
            _abriendoCliente ||
                (_cargando &&
                    _rutCliente.isEmpty &&
                    widget.clienteInicial == null)
            ? null
            : _verCliente,
        estadoLista: _estadoDetalle(),
        acciones: [if (widget.acciones case final acciones?) acciones],
        mostrarNavegacionMovil: !widget.esPendiente,
      ),
    );
  }
}
