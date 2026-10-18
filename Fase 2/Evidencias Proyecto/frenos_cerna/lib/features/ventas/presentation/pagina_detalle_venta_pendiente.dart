import 'package:frenos_cerna/features/clientes/pagina_clientes.dart'; // Muestra el cliente local asociado a la pendiente.
import 'package:flutter/material.dart'; // Presenta las acciones de la venta pendiente.
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart'; // Recupera y confirma los borradores locales.
import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart'; // Reutiliza el formulario para editar la venta.
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart'; // Conserva el mismo diseño del historial.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart'; // Conserva los botones del proyecto.

class PaginaDetalleVentaPendiente extends StatefulWidget {
  // Muestra el historial de una venta sin pago confirmado.
  final VentaPendiente venta; // Recibe la venta seleccionada mediante la lupa.
  final VentasPendientesRepository?
  repositorio; // Permite verificar el flujo con almacenamiento controlado.
  const PaginaDetalleVentaPendiente({
    super.key,
    required this.venta,
    this.repositorio,
  }); // Conserva el origen de la venta.
  @override // Crea el estado de edición y confirmación.
  State<PaginaDetalleVentaPendiente> createState() =>
      _PaginaDetalleVentaPendienteState(); // Administra los cambios sin reconstruir el historial remoto.
} // Finaliza la página pública.

class _PaginaDetalleVentaPendienteState
    extends State<PaginaDetalleVentaPendiente> {
  // Conserva el detalle local actualizado.
  late VentaPendiente _venta; // Mantiene la última versión guardada.
  bool _ocupado = true; // Bloquea acciones hasta comprobar el estado local.
  bool _requiereRevision =
      false; // Impide repetir una confirmación de resultado desconocido.
  String? _error; // Conserva los errores visibles de carga o pago.
  VentasPendientesRepository get _repositorio =>
      widget.repositorio ??
      VentasPendientesRepository
          .instancia; // Utiliza el almacenamiento del usuario.
  @override // Recupera el estado persistido al abrir la lupa.
  void initState() {
    // Conserva una vista disponible mientras carga.
    super.initState(); // Inicializa el ciclo de vida.
    _venta = widget.venta; // Muestra los datos recibidos.
    _actualizar(); // Comprueba que la venta siga pendiente.
  } // Finaliza la inicialización.

  Future<void> _actualizar() async {
    // Refresca el historial después de editar o fallar un pago.
    try {
      // Conserva la última vista ante errores locales.
      final ventas = await _repositorio
          .obtenerTodas(); // Consulta únicamente este dispositivo.
      final revision = await _repositorio.requiereRevision(
        _venta.id,
      ); // Detecta confirmaciones interrumpidas.
      final errorConfirmacion = await _repositorio.errorConfirmacion(
        _venta.id,
      ); // Recupera el detalle del último intento.
      if (!mounted) return; // Evita actualizar una página cerrada.
      final encontrada = ventas.where(
        (venta) => venta.id == _venta.id,
      ); // Localiza la versión actual.
      setState(() {
        // Actualiza el detalle y sus acciones.
        if (encontrada.isNotEmpty) {
          _venta = encontrada.first; // Conserva las modificaciones guardadas.
        }
        _requiereRevision = revision || encontrada.isEmpty; // Deshabilita acciones si el resultado es incierto o la venta ya no está pendiente.
        if (encontrada.isEmpty) _error = 'La venta ya no está pendiente. Vuelve a Ventas para consultar su historial.'; // Evita editar una copia local desactualizada.
        if (revision && errorConfirmacion != null) {
          _error =
              'Confirmación pendiente de revisión. Detalle del intento: $errorConfirmacion'; // Muestra el motivo real sin desbloquear una venta incierta.
        }
        _ocupado = false; // Permite continuar después de la lectura.
      }); // Finaliza la actualización.
    } catch (error) {
      // Conserva la venta si el almacenamiento falla.
      if (mounted) {
        setState(() {
          _error = error.toString();
          _ocupado = false;
          _requiereRevision = true;
        }); // Informa el fallo e impide confirmar datos no verificados.
      }
    } // Finaliza la recuperación local.
  } // Finaliza la actualización.

  Future<void> _recuperar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text(
          'REVISAR VENTA',
        ), // Exige verificar el resultado antes de reintentar.
        content: const Text(
          'Antes de continuar, comprueba en el historial completo y en Supabase que esta venta no fue guardada. Si ya existe, no la recuperes: podrías duplicar la venta y descontar el stock otra vez. ¿Confirmas que no fue registrada y que ya corregiste el problema?',
        ),
        actions: [
          CartaNavegacion.accion(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('CANCELAR'),
          ), // Mantiene el bloqueo.
          CartaNavegacion.accion(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('NO FUE REGISTRADA'),
          ), // Confirma la revisión manual.
        ],
      ),
    );
    if (confirmado != true || !mounted) {
      return; // Conserva el estado si se cancela.
    }
    setState(
      () => _ocupado = true,
    ); // Bloquea acciones durante la recuperación local.
    try {
      await _repositorio.recuperarTrasRevision(
        _venta.id,
      ); // Recupera sin enviar el pago.
      if (!mounted) return;
      setState(() => _error = null); // Limpia el mensaje revisado.
      await _actualizar(); // Recarga los datos y habilita el intento posterior.
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _ocupado = false;
        }); // Conserva el bloqueo si no pudo recuperar.
      }
    }
  }

  Future<void> _editar() async {
    // Abre la edición conservando este detalle debajo.
    final modificada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/sales/pending/edit'),
        builder: (context) => PaginaCrearVenta(
          pendiente: _venta,
          repositorioPendientes: _repositorio,
        ),
      ),
    ); // Devuelve la venta al mismo registro local.
    if (modificada == true && mounted) {
      setState(() => _ocupado = true);
      await _actualizar();
    } // Refresca artículos, cliente y total.
  } // Finaliza la edición.

  Future<void> _confirmarPago() async {
    // Envía la venta únicamente tras confirmar su pago.
    if (_ocupado || _requiereRevision) {
      return; // Impide confirmaciones repetidas o inseguras.
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('CONFIRMAR PAGO'),
        content: const Text(
          '¿Confirmas que se recibió el pago? La venta se guardará en el historial y se descontará el stock. El servidor comprobará precios y disponibilidad actuales.',
        ),
        actions: [
          CartaNavegacion.accion(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('CANCELAR'),
          ),
          CartaNavegacion.accion(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('CONFIRMAR PAGO'),
          ),
        ],
      ),
    ); // Explica la transición definitiva al historial.
    if (confirmar != true || !mounted) {
      return; // Cancela sin escrituras remotas.
    }
    setState(() {
      _ocupado = true;
      _error = null;
    }); // Bloquea la edición durante el cierre.
    try {
      // Conserva la venta pendiente si el servidor rechaza el registro.
      final id = await _repositorio.confirmarPago(
        _venta.id,
      ); // Usa la transacción existente de stock y detalles.
      if (!mounted) return; // Evita navegar si se cerró la vista.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/sales/closed'),
          builder: (context) => PaginaDetalleVenta(
            idVenta: id,
            rutCliente: _venta
                .rutCliente, // Transfiere la relación al historial cerrado.
            clienteNombre: _venta.nombreCliente,
            vehiculoNombre: _venta.patente.isEmpty
                ? 'Sin vehículo'
                : _venta.patente,
            total: _venta.total,
            desdeHistorial: false,
          ),
        ),
        result: true,
      ); // Abre el historial cerrado y permite refrescar la lista de Ventas.
    } catch (error) {
      // Mantiene los datos locales para corregir errores o revisar el resultado.
      if (!mounted) return; // Evita cambiar una página cerrada.
      final detalle = error
          .toString(); // Conserva el diagnóstico para otros errores.
      final contadorVentas =
          detalle.contains('23505') &&
          (detalle.contains('venta_pkey') ||
              detalle.contains('detalle_venta_producto_pkey') ||
              detalle.contains(
                'detalle_venta_servicio_pkey',
              )); // Reconoce una colisión del ID automático.
      setState(
        () => _error = contadorVentas
            ? 'El contador de IDs de ventas o sus detalles está desactualizado. La transacción fue rechazada y el borrador sigue local. Ejecuta supabase/reparar_secuencias_ventas.sql en Supabase y vuelve a confirmar el pago.'
            : detalle,
      ); // Explica la reparación sin afirmar que la venta ya existe.
      await _actualizar(); // Comprueba si se puede reintentar o debe revisarse el historial.
    } // Finaliza la confirmación.
  } // Finaliza el cierre de la venta.

  @override // Conserva el mismo contenido y las mismas proporciones del historial.
  Widget build(BuildContext context) => PopScope(
    canPop: !_ocupado,
    child: PaginaDetalleVenta(
      key: ValueKey(_venta.revision),
      idVenta: _venta.id,
      clienteNombre: _venta.nombreCliente,
      vehiculoNombre: _venta.patente.isEmpty ? 'Sin vehículo' : _venta.patente,
      total: _venta.total,
      desdeHistorial: false,
      rutCliente: _venta.rutCliente, // Conserva la relación del cliente local.
      clienteInicial: Cliente(
        id: _venta.rutCliente,
        nombre: _venta.nombreCliente,
        numero: _venta.fonoCliente,
        ultimaVenta: '',
        vehiculo: _venta.patente,
      ), // Permite ver el perfil del borrador incluso sin conexión.
      ventaInicial: _venta.registro,
      esPendiente: true,
      acciones: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Añade únicamente las acciones propias de una pendiente.
          if (_error != null)
            Text(
              _error!,
            ), // Mantiene visible el error de almacenamiento o pago.
          if (_requiereRevision)
            const Text(
              'Confirmación pendiente de revisión. Comprueba el historial antes de volver a registrar esta venta.',
            ), // Impide duplicados ante resultados inciertos.
          const SizedBox(height: 20), // Separa el detalle de las acciones.
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              if (_requiereRevision)
                CartaNavegacion.accion(
                  onPressed: _ocupado ? null : _recuperar,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('REVISAR VENTA'),
                ), // Recupera solo después de confirmar que no se guardó.
              // Conserva los botones en escritorio y móvil.
              CartaNavegacion.accion(
                onPressed: _ocupado || _requiereRevision ? null : _editar,
                icon: const Icon(Icons.edit),
                label: const Text('EDITAR VENTA'),
              ), // Permite modificar únicamente ventas abiertas.
              CartaNavegacion.accion(
                onPressed: _ocupado || _requiereRevision
                    ? null
                    : _confirmarPago,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_ocupado ? 'ESPERA...' : 'CONFIRMAR PAGO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD96363),
                  foregroundColor: Colors.black,
                ), // Distingue la confirmación con el rojo existente.
              ), // Cierra la venta después de recibir el pago.
            ],
          ), // Finaliza las acciones específicas.
        ],
      ),
    ),
  ); // Finaliza la vista del historial pendiente.
} // Finaliza el estado de la página.
