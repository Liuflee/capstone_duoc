import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart'; // Integra las ventas todavía locales.
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta_pendiente.dart'; // Abre el historial de una venta sin pago.
import 'package:frenos_cerna/shared/widgets/filtros_tabla.dart'; // Filtra las ventas por estado.
import 'package:frenos_cerna/shared/widgets/buscador_tabla.dart'; // Conserva la búsqueda de la tabla.
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
  const PaginaVentas({
    super.key,
    this.mostrarHistorial =
        false, // La vista principal muestra únicamente el día actual.
    this.ahora, // Mantiene el reloj real por defecto.
    this.repositorioPendientes,
    this.cargarVentas,
  });

  @override
  State<PaginaVentas> createState() => _PaginaVentasState();
}

class _PaginaVentasState extends State<PaginaVentas> {
  List<VentaEnProceso> ventasActivas = [];
  final _busqueda = TextEditingController(); // Conserva la búsqueda de Ventas.
  String _estado = 'todas'; // Muestra inicialmente todos los estados.
  List<VentaPendiente> _pendientes =
      []; // Conserva las ventas guardadas localmente.
  VentasPendientesRepository get _repositorio =>
      widget.repositorioPendientes ??
      VentasPendientesRepository
          .instancia; // Usa el mismo catálogo al crear y editar.
  @override // Libera los recursos al salir de Ventas.
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  } // Evita conservar el controlador de una página cerrada.

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

  Widget _controlesVentas() => Padding(
    padding: const EdgeInsets.only(left: 14, bottom: 20),
    child: LayoutBuilder(
      builder: (context, limites) {
        // Alinea los controles con el ancho visible de la tabla.
        final ancho = (limites.maxWidth - 14).clamp(
          0.0,
          double.infinity,
        ); // Excluye el espacio del scrollbar.
        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Conserva filtros y búsqueda en sus extremos.
              FiltrosTabla(
                anchoTabla: ancho,
                filtros: const [
                  OpcionFiltroTabla(id: 'todas', texto: 'TODAS LAS VENTAS'),
                  OpcionFiltroTabla(id: 'cerrada', texto: 'VENTA CERRADA'),
                  OpcionFiltroTabla(id: 'pendiente', texto: 'VENTA EN PROCESO'),
                ],
                filtroSeleccionado: _estado,
                alSeleccionar: (valor) => setState(() => _estado = valor),
              ), // Filtra por el origen real de la venta.
              BuscadorTabla(
                anchoTabla: ancho,
                controlador: _busqueda,
                alCambiar: (_) => setState(() {}),
              ), // Busca por cliente, vehículo o producto sin cambiar el estado.
            ],
          ),
        ); // Finaliza los controles de la tabla.
      },
    ),
  ); // Finaliza la adaptación del ancho.

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande =
        MediaQuery.of(context).size.width >=
        700; // Comparte el punto de adaptación del menú principal.

    // Convierte las ventas a registros que entiende TablaDatos.
    // El objeto original se conserva para usarlo al ver el detalle.

    final hoy = (widget.ahora?.call() ?? DateTime.now())
        .toLocal(); // Compara los días en la misma zona horaria.
    bool esDeHoy(DateTime? fecha) =>
        fecha != null &&
        fecha.toLocal().year == hoy.year &&
        fecha.toLocal().month == hoy.month &&
        fecha.toLocal().day ==
            hoy.day; // Excluye ventas sin fecha conocida de la vista diaria.
    final consulta = _busqueda.text
        .trim()
        .toLowerCase(); // Normaliza la búsqueda.
    final List<Map<String, dynamic>> filasVentas =
        [
              // Combina ambos estados sin alterar las tablas.
              for (final pendiente in _pendientes.where(
                (venta) =>
                    widget.mostrarHistorial || esDeHoy(venta.fechaCreacion),
              )) // Recorre las ventas guardadas en este dispositivo.
                {
                  'cliente': pendiente.nombreCliente,
                  'vehiculo': pendiente.registro.vehiculoNombre,
                  'productos': pendiente.registro.productosResumen,
                  'venta': pendiente.registro,
                  'pendiente': pendiente,
                  'estado': 'pendiente',
                }, // Conserva el borrador detrás de la fila.
              for (final venta in ventasActivas.where(
                (venta) =>
                    widget.mostrarHistorial || esDeHoy(venta.fechaRegistro),
              )) // Recorre únicamente ventas concretadas en Supabase.
                {
                  'cliente': venta.clienteNombre,
                  'vehiculo': venta.vehiculoNombre,
                  'productos': venta.productosResumen,
                  'venta': venta,
                  'estado': 'cerrada',
                }, // Distingue el historial cerrado.
            ]
            .where(
              (fila) =>
                  (_estado == 'todas' || fila['estado'] == _estado) &&
                  ['cliente', 'vehiculo', 'productos'].any(
                    (campo) =>
                        fila[campo].toString().toLowerCase().contains(consulta),
                  ),
            )
            .toList(); // Combina estado y búsqueda.

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
                  Text(
                    widget.mostrarHistorial ? 'HISTORIAL DE VENTAS' : 'VENTAS',

                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
                  _controlesVentas(), // Mantiene el filtro por estado encima de la tabla.
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
                        child: TablaDatos(
                          mostrarControles: false, // La página aplica el filtro por estado y la búsqueda.
                          // Encabezados visibles de la tabla.
                          nombresColumnas: const [
                            'CLIENTE',
                            'VEHÍCULO',
                            'PRODUCTOS',
                            'VER',
                          ],

                          // Campos de cada columna (vacío si la celda es personalizada).
                          camposColumnas: const [
                            'cliente',
                            'vehiculo',
                            'productos',
                            '',
                          ],

                          // Ancho proporcional de cada columna.
                          anchosColumnas: const [200, 200, 400, 100],

                          // Colores de cabecera alternando entre los dos rojos.
                          coloresEncabezados: const [
                            _rojoClaro,
                            _rojoOscuro,
                            _rojoClaro,
                            _rojoOscuro,
                          ],

                          // Las filas de ventas son más altas que el valor por defecto.
                          altoFila: 120,

                          filas: filasVentas,

                          celdasPersonalizadas: {
                            // Columna 0: cliente con avatar.
                            0: (context, fila) {
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },

                            // Columna 1: vehículo.
                            1: (context, fila) {
                              final venta = fila['venta'] as VentaEnProceso;

                              return Text(
                                venta.vehiculoNombre,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 18),
                              );
                            },

                            // Columna 2: resumen de productos.
                            2: (context, fila) {
                              final venta = fila['venta'] as VentaEnProceso;

                              return Text(
                                venta.productosResumen,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              );
                            },

                            // Columna 3: botón para ver el detalle de la venta.
                            3: (context, fila) {
                              final venta = fila['venta'] as VentaEnProceso;

                              return CartaNavegacion.accion(
                                // Conserva las medidas y la función de la acción original.
                                tipoBoton: 'icon',

                                tooltip: 'Ver venta',
                                child: const Icon(
                                  Icons.search,
                                  size: 40,
                                  color: Colors.black,
                                ),

                                onPressed: () async {
                                  // Abre el detalle según el estado real.
                                  final pendiente =
                                      fila['pendiente'] as VentaPendiente?; // Recupera el borrador local si corresponde.
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      settings: RouteSettings(
                                        name: pendiente == null
                                            ? '/sales/closed'
                                            : '/sales/pending',
                                      ),
                                      builder: (context) => pendiente != null
                                          ? PaginaDetalleVentaPendiente(
                                              venta: pendiente,
                                              repositorio: _repositorio,
                                            )
                                          : PaginaDetalleVenta(
                                              idVenta: venta.id,
                                              rutCliente: venta.rutCliente, // Abre el perfil por su relación real.
                                              clienteNombre: venta.clienteNombre
                                                  .replaceAll('\n', ' '),
                                              vehiculoNombre:
                                                  venta.vehiculoNombre,
                                              total: venta.total,
                                              desdeHistorial: false,
                                            ),
                                    ),
                                  ); // Conserva historial cerrado sin edición ni confirmación.
                                  if (mounted) await _cargarVentas(); // Refresca la lista después de editar o confirmar el pago.
                                },
                              );
                            },
                          },
                        ),
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
