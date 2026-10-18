import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart'; // Integra las ventas todavía locales.
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta_pendiente.dart'; // Abre el historial de una venta sin pago.
import 'package:frenos_cerna/shared/widgets/panel_filtros.dart'; // Filtra las ventas por estado, periodo y búsqueda.
// Importa la barra superior común a las páginas.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
// Importa las cartas que conservan las acciones de la página.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
import 'package:flutter/material.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

typedef VentaEnProceso = VentaRegistro;

class PaginaVentas extends StatefulWidget {
  final VentasPendientesRepository?
  repositorioPendientes; // Permite verificar el almacenamiento local.
  final Future<List<VentaRegistro>> Function()?
  cargarVentas; // Permite comprobar el catálogo cerrado sin conexión real.
  final bool
  mostrarHistorial; // Separa el historial completo de las ventas diarias.
  final DateTime Function()?
  ahora; // Permite comprobar límites de día sin depender del reloj real.
  final String?
  clienteId; // Filtra todas las ventas por el RUT de un solo cliente.
  final String?
  clienteNombre; // Personaliza el título cuando se filtra por cliente.
  const PaginaVentas({
    super.key,
    this.mostrarHistorial =
        false, // La vista principal muestra únicamente el día actual.
    this.ahora, // Mantiene el reloj real por defecto.
    this.repositorioPendientes,
    this.cargarVentas,
    this.clienteId, // Sin cliente definido se muestra el historial completo.
    this.clienteNombre,
  });

  @override
  State<PaginaVentas> createState() => _PaginaVentasState();
}

class _PaginaVentasState extends State<PaginaVentas> {
  List<VentaEnProceso> ventasActivas = [];
  List<VentaPendiente> _pendientes =
      []; // Conserva las ventas guardadas localmente.
  VentasPendientesRepository get _repositorio =>
      widget.repositorioPendientes ??
      VentasPendientesRepository
          .instancia; // Usa el mismo catálogo al crear y editar.

  bool _cargando = true;
  String? _error;

  // Colores de cabecera que se alternan entre las columnas.
  static const Color _rojoClaro = Color.fromARGB(255, 253, 116, 116);
  static const Color _rojoOscuro = Color.fromARGB(255, 207, 81, 81);

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    // Combina las ventas locales con las ya pagadas.
    List<VentaPendiente> pendientes =
        _pendientes; // Conserva datos visibles ante un fallo de lectura.
    List<VentaRegistro> cerradas =
        ventasActivas; // Conserva el historial ya recuperado.
    final errores =
        <String>[]; // Informa por separado fallos locales y remotos.
    try {
      pendientes = await _repositorio.obtenerTodas();
    } catch (error) {
      errores.add('No se pudieron cargar las pendientes locales: $error');
    } // Las pendientes no requieren conexión.
    try {
      cerradas =
          await (widget.cargarVentas?.call() ?? VentaRegistro.obtenerTodas());
    } catch (error) {
      errores.add('No se pudo actualizar el historial de Supabase: $error');
    } // Consulta solamente ventas concretadas.
    if (!mounted) return; // Evita actualizar una página cerrada.
    setState(() {
      _pendientes = pendientes;
      ventasActivas = cerradas;
      _error = errores.isEmpty ? null : errores.join('\n');
      _cargando = false;
    }); // Conserva las pendientes aunque no haya conexión.
  } // Finaliza la carga combinada.

  // Construye la celda del cliente con su avatar.
  Widget _celdaCliente(BuildContext context, Map<String, dynamic> fila) {
    final venta = fila['venta'] as VentaEnProceso;

    return Row(
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ],
    );
  } // Finaliza la celda de identificación del cliente.

  // Construye la celda del vehículo asociado a la venta.
  Widget _celdaVehiculo(BuildContext context, Map<String, dynamic> fila) {
    final venta = fila['venta'] as VentaEnProceso;

    return Text(
      venta.vehiculoNombre,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18),
    );
  } // Finaliza la celda del vehículo.

  // Construye la celda con el resumen de productos de la venta.
  Widget _celdaProductos(BuildContext context, Map<String, dynamic> fila) {
    final venta = fila['venta'] as VentaEnProceso;

    return Text(
      venta.productosResumen,
      textAlign: TextAlign.center,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 16),
    );
  } // Finaliza la celda de productos.

  // Construye la celda con la acción para ver el detalle completo de la venta.
  Widget _celdaVer(BuildContext context, Map<String, dynamic> fila) {
    final venta = fila['venta'] as VentaEnProceso;

    return CartaNavegacion.accion(
      // Conserva las medidas y la función de la acción original.
      tipoBoton: 'icon',

      tooltip: 'Ver venta',
      child: const Icon(Icons.search, size: 40, color: Colors.black),

      onPressed: () async {
        // Abre el detalle según el estado real.
        final pendiente = fila['pendiente'] as VentaPendiente?; // Recupera el borrador local si corresponde.
        await Navigator.push(
          context,
          MaterialPageRoute(
            settings: RouteSettings(
              name: pendiente == null ? '/sales/closed' : '/sales/pending',
            ),
            builder: (context) => pendiente != null
                ? PaginaDetalleVentaPendiente(
                    venta: pendiente,
                    repositorio: _repositorio,
                  )
                : PaginaDetalleVenta(
                    idVenta: venta.id,
                    rutCliente: venta
                        .rutCliente, // Abre el perfil por su relación real.
                    clienteNombre: venta.clienteNombre.replaceAll('\n', ' '),
                    vehiculoNombre: venta.vehiculoNombre,
                    total: venta.total,
                    desdeHistorial: false,
                  ),
          ),
        ); // Conserva historial cerrado sin edición ni confirmación.
        if (mounted) await _cargarVentas(); // Refresca la lista después de editar o confirmar el pago.
      },
    );
  } // Finaliza la celda con la acción de detalle.

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande =
        MediaQuery.of(context).size.width >=
        700; // Comparte el punto de adaptación del menú principal.

    // Convierte las ventas a registros que entiende TablaDatos.
    // El objeto original se conserva para usarlo al ver el detalle.

    final hoy = (widget.ahora?.call() ?? DateTime.now())
        .toLocal(); // Compara los días en la misma zona horaria.
    // Comprueba si dos fechas pertenecen al mismo día.
    bool mismoDia(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    bool esDeHoy(DateTime? fecha) =>
        fecha != null &&
        mismoDia(
          fecha.toLocal(),
          hoy,
        ); // Excluye ventas sin fecha conocida de la vista diaria.
    // Clasifica cada venta en un periodo sencillo para el filtro del historial.
    String periodoDe(DateTime? fecha) {
      final local = fecha?.toLocal();
      if (local == null) {
        return 'SIN FECHA'; // Conserva las ventas antiguas sin fecha.
      }
      if (mismoDia(local, hoy)) return 'HOY';
      if (local.isAfter(hoy.subtract(const Duration(days: 7)))) {
        return 'ÚLTIMOS 7 DÍAS';
      }
      if (local.year == hoy.year && local.month == hoy.month) {
        return 'ESTE MES';
      }
      return 'ANTERIORES'; // Agrupa lo más antiguo de una sola vez.
    }

    // Prepara todas las ventas visibles; el panel aplica estado, periodo y texto.
    final List<Map<String, dynamic>> filasVentas = [
      // Combina ambos estados sin alterar las tablas.
      for (final pendiente in _pendientes.where(
        (venta) => widget.mostrarHistorial || esDeHoy(venta.fechaCreacion),
      )) // Recorre las ventas guardadas en este dispositivo.
        {
          'cliente': pendiente.nombreCliente,
          'rut': pendiente.rutCliente, // Permite filtrar por el cliente real.
          'vehiculo': pendiente.registro.vehiculoNombre,
          'productos': pendiente.registro.productosResumen,
          'venta': pendiente.registro,
          'pendiente': pendiente,
          'estado': 'pendiente',
          'fecha': pendiente.fechaCreacion, // Permite filtrar por periodo.
        }, // Conserva el borrador detrás de la fila.
      for (final venta in ventasActivas.where(
        (venta) => widget.mostrarHistorial || esDeHoy(venta.fechaRegistro),
      )) // Recorre únicamente ventas concretadas en Supabase.
        {
          'cliente': venta.clienteNombre,
          'rut': venta.rutCliente, // Permite filtrar por el cliente real.
          'vehiculo': venta.vehiculoNombre,
          'productos': venta.productosResumen,
          'venta': venta,
          'estado': 'cerrada',
          'fecha': venta.fechaRegistro, // Permite filtrar por periodo.
        }, // Distingue el historial cerrado.
    ]; // Finaliza la lista completa de ventas visibles.

    // La vista de un cliente conserva solamente sus propias ventas.
    final bool soloCliente = widget.clienteId != null;
    final List<Map<String, dynamic>> filasVisibles = soloCliente
        ? filasVentas
              .where((fila) => fila['rut'].toString() == widget.clienteId)
              .toList() // Compara el RUT almacenado en cada venta.
        : filasVentas;

    return Scaffold(
      backgroundColor: Colors.white,

      // ============================================================
      // APP BAR
      // ============================================================
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
            tituloPagina: widget.mostrarHistorial
                ? 'Historial de ventas'
                : 'Ventas del día',
          ), // Reutiliza el encabezado de Inicio.
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
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.12,
              child: const MenuLateral(activo: 'Ventas'),
            ),

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

                  const SizedBox(height: 12),

                  // ==================================================
                  // TÍTULO
                  // ==================================================
                  if (widget.mostrarHistorial) ...[
                    if (widget.clienteId != null)
                      Align(
                        // Regresa al perfil del cliente desde el historial.
                        alignment: Alignment.centerLeft,
                        child: CartaNavegacion.accion(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.keyboard_return),
                          label: const Text('VOLVER'),
                        ),
                      ),
                    Text(
                      widget.clienteNombre == null
                          ? 'HISTORIAL DE VENTAS'
                          : 'HISTORIAL DE VENTAS DE ${widget.clienteNombre}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    const Center(
                      child: Text(
                        'VENTAS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ), // Mantiene el título centrado en el contenido sin depender de botones laterales.
                    ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // ERROR
                  // ==================================================
                  if (!widget.mostrarHistorial)
                    Text(
                      'VENTAS DEL DÍA: ${hoy.day.toString().padLeft(2, '0')}/${hoy.month.toString().padLeft(2, '0')}/${hoy.year}',
                    ), // Distingue claramente el alcance diario.
                  if (!widget.mostrarHistorial &&
                      ventasActivas.any((venta) => venta.fechaRegistro == null))
                    const Text(
                      'Las ventas sin fecha conocida están disponibles en el historial completo.',
                    ), // Mantiene consultables las ventas antiguas.
                  if (_error != null) Text(_error!),
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
                      child: Padding(
                        // Compensa los 14 px que TablaDatos reserva a la
                        // derecha para el scrollbar, así queda centrada.
                        padding: const EdgeInsets.only(left: 14),
                        child: PanelFiltros<Map<String, dynamic>>(
                          datos: filasVisibles, // Conserva solo las ventas que corresponden a la página.
                          textoAyuda: 'BUSCAR CLIENTE, VEHÍCULO O PRODUCTO', // Describe la búsqueda disponible.
                          camposBusqueda: [
                            // La vista de un cliente ya conoce su nombre.
                            if (!soloCliente)
                              (fila) => fila['cliente']
                                  .toString(), // Busca en el cliente.
                            (fila) => fila['vehiculo']
                                .toString(), // Busca en el vehículo.
                            (fila) => fila['productos']
                                .toString(), // Busca en los productos.
                          ],
                          categorias: [
                            // Permite elegir ventas cerradas, en proceso o ambas.
                            CategoriaFiltro<Map<String, dynamic>>(
                              id: 'estado',
                              etiqueta: 'ESTADO',
                              seleccionUnica: true, // Muestra ventas cerradas o pendientes, nunca ambas a la vez.
                              opcionesFijas: const [
                                'VENTAS CERRADAS',
                                'VENTAS PENDIENTES',
                              ], // Mantiene ambos estados incluso con cero ventas.
                              valor: (fila) => fila['estado'] == 'cerrada'
                                  ? 'VENTAS CERRADAS'
                                  : 'VENTAS PENDIENTES',
                            ),

                            // El filtro por cliente es innecesario si ya se
                            // muestran únicamente las ventas de un cliente.
                            if (!soloCliente)
                              CategoriaFiltro<Map<String, dynamic>>(
                                id: 'cliente',
                                etiqueta: 'CLIENTE',
                                valor: (fila) => fila['cliente'].toString(),
                              ),
                            // El historial completo también se filtra por periodo.
                            if (widget.mostrarHistorial)
                              CategoriaFiltro<Map<String, dynamic>>(
                                id: 'periodo',
                                etiqueta: 'PERIODO',
                                valor: (fila) =>
                                    periodoDe(fila['fecha'] as DateTime?),
                              ),
                          ],
                          child: (filtrados) => TablaDatos(
                            mostrarControles: false, // El panel ya aplica estado, periodo y búsqueda.
                            // Encabezados visibles de la tabla.
                            // La vista por cliente omite la columna de cliente
                            // porque todas sus filas muestran el mismo nombre.
                            nombresColumnas: soloCliente
                                ? const ['VEHÍCULO', 'PRODUCTOS', 'VER']
                                : const [
                                    'CLIENTE',
                                    'VEHÍCULO',
                                    'PRODUCTOS',
                                    'VER',
                                  ],

                            // Campos de cada columna (vacío si la celda es personalizada).
                            camposColumnas: soloCliente
                                ? const ['vehiculo', 'productos', '']
                                : const [
                                    'cliente',
                                    'vehiculo',
                                    'productos',
                                    '',
                                  ],

                            // Ancho proporcional de cada columna.
                            anchosColumnas: soloCliente
                                ? const [250, 450, 100]
                                : const [200, 200, 400, 100],

                            // Colores de cabecera alternando entre los dos rojos.
                            coloresEncabezados: soloCliente
                                ? const [_rojoClaro, _rojoOscuro, _rojoClaro]
                                : const [
                                    _rojoClaro,
                                    _rojoOscuro,
                                    _rojoClaro,
                                    _rojoOscuro,
                                  ],

                            // Las filas de ventas son más altas que el valor por defecto.
                            altoFila: 120,

                            filas: filtrados, // Muestra las ventas que pasan los filtros.

                            celdasPersonalizadas: soloCliente
                                // Sin columna de cliente, las celdas bajan un lugar.
                                ? {
                                    0: _celdaVehiculo,
                                    1: _celdaProductos,
                                    2: _celdaVer,
                                  }
                                : {
                                    0: _celdaCliente,
                                    1: _celdaVehiculo,
                                    2: _celdaProductos,
                                    3: _celdaVer,
                                  },
                          ), // Finaliza la tabla construida con las ventas filtradas.
                        ), // Finaliza el panel de filtros reutilizable.
                      ), // Finaliza la compensación del scrollbar.
                    ), // Finaliza el espacio restante de la página.
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
