import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:frenos_cerna/features/clientes/pagina_ver_cliente.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart';
import 'package:frenos_cerna/features/ventas/presentation/formato_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/panel_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/tema_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/detalle_venta_vista.dart';
import 'package:material_ui/material_ui.dart';

class PaginaDetalleVentaPendiente extends StatefulWidget {
  final VentaPendiente venta;
  final VentasPendientesRepository? repositorio;

  const PaginaDetalleVentaPendiente({
    super.key,
    required this.venta,
    this.repositorio,
  });

  @override
  State<PaginaDetalleVentaPendiente> createState() =>
      _PaginaDetalleVentaPendienteState();
}

enum _EstadoPendiente { disponible, revision, ausente, sinVerificar }

class _PaginaDetalleVentaPendienteState
    extends State<PaginaDetalleVentaPendiente> {
  late VentaPendiente _venta = widget.venta;
  _EstadoPendiente _estado = _EstadoPendiente.sinVerificar;
  bool _ocupado = true;
  String? _error;

  VentasPendientesRepository get _repositorio =>
      widget.repositorio ?? VentasPendientesRepository.instancia;

  @override
  void initState() {
    super.initState();
    _actualizar();
  }

  Future<void> _actualizar({String? errorPago}) async {
    try {
      final id = _venta.id;
      final ventas = await _repositorio.obtenerTodas();
      final actual = ventas.where((venta) => venta.id == id).firstOrNull;
      final revision =
          actual != null && await _repositorio.requiereRevision(id);
      final motivo = revision ? await _repositorio.errorConfirmacion(id) : null;
      if (!mounted) return;
      setState(() {
        if (actual != null) _venta = actual;
        _estado = actual == null
            ? _EstadoPendiente.ausente
            : revision
            ? _EstadoPendiente.revision
            : _EstadoPendiente.disponible;
        _error = motivo ?? errorPago;
        _ocupado = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _estado = _EstadoPendiente.sinVerificar;
        _error = 'No se pudo comprobar el estado de la venta. $error';
        _ocupado = false;
      });
    }
  }

  Future<void> _recuperar() async {
    if (_ocupado || _estado != _EstadoPendiente.revision) return;
    setState(() => _ocupado = true);
    final confirmado = await mostrarDialogoVenta<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('Revisar venta'),
        content: const Text(
          'Comprueba en el historial y en Supabase si la venta ya se registró. '
          'Recuperarla solo es seguro si comprobaste que el intento anterior '
          'falló. Una confirmación duplicada puede descontar el stock dos veces.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Verifiqué que no se registró'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmado != true) {
      setState(() => _ocupado = false);
      return;
    }
    try {
      await _repositorio.recuperarTrasRevision(_venta.id);
      if (mounted) await _actualizar();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo recuperar la venta. $error';
        _ocupado = false;
      });
    }
  }

  Future<void> _editar() async {
    if (_ocupado || _estado != _EstadoPendiente.disponible) return;
    setState(() => _ocupado = true);
    final modificada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/sales/pending/edit'),
        builder: (_) => PaginaCrearVenta(
          pendiente: _venta,
          repositorioPendientes: _repositorio,
        ),
      ),
    );
    if (!mounted) return;
    if (modificada == true) {
      await _actualizar();
    } else {
      setState(() => _ocupado = false);
    }
  }

  Future<void> _verCliente() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/clients/view'),
        builder: (_) => PaginaVerCliente(
          cliente: Cliente(
            id: _venta.rutCliente,
            nombre: _venta.nombreCliente,
            numero: _venta.fonoCliente,
            ultimaVenta: '',
            vehiculo: _venta.patente,
          ),
        ),
      ),
    );
    if (mounted) setState(() => _ocupado = false);
  }

  Future<void> _confirmarPago() async {
    if (_ocupado || _estado != _EstadoPendiente.disponible) return;
    setState(() => _ocupado = true);
    final confirmado = await mostrarDialogoVenta<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('Confirmar pago'),
        content: Text(
          'Total del borrador ${precioVenta(_venta.total)}\n\n'
          'Confirma solo después de recibir el pago. El servidor verificará '
          'los precios y la disponibilidad antes de registrar la venta y descontar el stock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: estiloAccionPrincipalVenta(dialogo),
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Confirmar pago'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmado != true) {
      setState(() => _ocupado = false);
      return;
    }
    setState(() => _error = null);
    try {
      final id = await _repositorio.confirmarPago(_venta.id);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/sales/closed'),
          builder: (_) => PaginaDetalleVenta(
            idVenta: id,
            rutCliente: _venta.rutCliente,
            clienteNombre: _venta.nombreCliente,
            vehiculoNombre: _venta.patente.isEmpty
                ? 'Sin vehículo'
                : _venta.patente,
            total: _venta.total,
            desdeHistorial: false,
          ),
        ),
        result: true,
      );
    } catch (error) {
      if (!mounted) return;
      final detalle = error.toString();
      final contadorVentas =
          detalle.contains('23505') &&
          (detalle.contains('venta_pkey') ||
              detalle.contains('detalle_venta_producto_pkey') ||
              detalle.contains('detalle_venta_servicio_pkey'));
      await _actualizar(
        errorPago: contadorVentas
            ? 'La secuencia de IDs de ventas o sus detalles está desactualizada. '
                  'La transacción fue rechazada y la venta sigue pendiente. Ejecuta '
                  'supabase/reparar_secuencias_ventas.sql en Supabase antes de reintentar.'
            : detalle,
      );
    }
  }

  @override
  Widget build(BuildContext context) => PaginaTematica(
    builder: (context) => PopScope(
      canPop: !_ocupado,
      child: DetalleVentaVista(
        titulo: 'Venta pendiente',
        estado: switch (_estado) {
          _EstadoPendiente.disponible => 'Pendiente de pago',
          _EstadoPendiente.revision => 'Requiere revisión',
          _EstadoPendiente.ausente => 'Fuera de pendientes',
          _EstadoPendiente.sinVerificar => 'Estado sin verificar',
        },
        total: _venta.total,
        cliente: _venta.nombreCliente,
        rut: _venta.rutCliente,
        vehiculo: _venta.patente.isEmpty
            ? 'Sin vehículo asociado'
            : 'Patente ${_venta.patente}',
        lineas: [
          for (final articulo in _venta.articulos)
            LineaDetalleVenta(
              nombre: articulo.nombre,
              codigo: articulo.codigo,
              categoria: articulo.categoria,
              unidades:
                  '${articulo.cantidad} × ${precioVenta(articulo.precio)}',
              subtotal: articulo.cantidad * articulo.precio,
            ),
        ],
        verCliente: _ocupado ? null : _verCliente,
        aviso: _estado != _EstadoPendiente.disponible || _error != null
            ? Builder(builder: _avisoEstado)
            : null,
        acciones: _acciones(context),
        mostrarProgreso: _ocupado,
      ),
    ),
  );

  Widget _avisoEstado(BuildContext context) {
    final mensaje = switch (_estado) {
      _EstadoPendiente.revision =>
        'Revisa el historial antes de volver a confirmar el pago.',
      _EstadoPendiente.ausente => 'Esta venta ya salió de pendientes. Puedes consultar el historial desde Ventas.',
      _EstadoPendiente.sinVerificar when _ocupado =>
        'Comprobando el estado de la venta…',
      _EstadoPendiente.sinVerificar => 'Estado de la venta sin verificar.',
      _EstadoPendiente.disponible => 'El pago sigue pendiente.',
    };
    return PanelVenta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mensaje, style: Theme.of(context).textTheme.titleSmall),
          if (_error case final error?)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text(error)),
        ],
      ),
    );
  }

  List<Widget> _acciones(BuildContext context) => [
    if (_estado == _EstadoPendiente.disponible) ...[
      OutlinedButton.icon(
        onPressed: _ocupado ? null : _editar,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Editar venta'),
      ),
      FilledButton.icon(
        style: estiloAccionPrincipalVenta(context),
        onPressed: _ocupado ? null : _confirmarPago,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Confirmar pago'),
      ),
    ] else if (_estado == _EstadoPendiente.revision)
      FilledButton.icon(
        style: estiloAccionPrincipalVenta(context),
        onPressed: _ocupado ? null : _recuperar,
        icon: const Icon(Icons.fact_check_outlined),
        label: const Text('Revisar venta'),
      )
    else if (_estado == _EstadoPendiente.sinVerificar && !_ocupado)
      OutlinedButton.icon(
        onPressed: () {
          setState(() => _ocupado = true);
          _actualizar();
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
      ),
  ];
}
