// Importa el historial real y sus páginas de detalle.
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas_historial.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_detalle_vehiculo.dart';
import 'package:frenos_cerna/features/clientes/widgets/lista_vehiculos_cliente.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
// Importa la distribución reutilizable de campos.
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';
// Importa las cartas que conservan las acciones de la página.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
// Importaciones de Flutter y los componentes del proyecto
import 'package:flutter/material.dart';

import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';

import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

// Se crea la página de consulta, que recibe el cliente seleccionado
class PaginaVerCliente extends StatefulWidget {
  // Cliente cuyos datos se mostrarán sin modificarse
  final Cliente cliente;

  final Future<List<VentaRegistro>> Function(String)?
  cargarHistorial; // Permite verificar la consulta sin conexión real.
  final Future<List<HistorialVehiculo>> Function(String)? cargarVehiculos;
  // Constructor de la página
  const PaginaVerCliente({
    super.key,
    required this.cliente,
    this.cargarHistorial,
    this.cargarVehiculos,
  });

  @override
  State<PaginaVerCliente> createState() => _PaginaVerClienteState();
}

// Se crea el estado para administrar los campos y las operaciones de Supabase
class _PaginaVerClienteState extends State<PaginaVerCliente> {
  // Cantidad de ventas que se muestran como vista previa del historial.
  static const int _ventasVistaPrevia = 5;

  // Controladores de los campos que pueden editarse
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _fonoCtrl;

  // Evita que se repitan las operaciones mientras se guarda
  List<VentaRegistro> _ventas = []; // Conserva el historial real.
  String? _errorHistorial; // Conserva los errores de carga.
  bool _cargandoHistorial = true;
  List<HistorialVehiculo> _vehiculos = [];
  bool _cargandoVehiculos = true;
  String? _errorVehiculos;

  @override
  void initState() {
    super.initState();

    // Se cargan los datos originales en los campos del formulario
    _nombreCtrl = TextEditingController(text: widget.cliente.nombre);
    _fonoCtrl = TextEditingController(text: widget.cliente.numero);
    _cargarHistorial(); // Consulta las ventas del cliente.
    _cargarVehiculos();
  }

  @override
  void dispose() {
    // Libera los controladores cuando se cierra la página
    _nombreCtrl.dispose();
    _fonoCtrl.dispose();

    super.dispose();
  }

  // Esta vista consulta al cliente sin operaciones de actualización.
  // Conserva el historial del cliente para consultar sus ventas.

  Future<void> _cargarHistorial() async {
    try {
      final ventas =
          await (widget.cargarHistorial?.call(widget.cliente.id) ??
              VentaRegistro.obtenerPorCliente(widget.cliente.id));
      if (mounted) {
        setState(() {
          _ventas = ventas;
          _errorHistorial = null;
          _cargandoHistorial = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorHistorial = error.toString();
          _cargandoHistorial = false;
        });
      }
    }
  } // Recupera el historial real.

  Future<void> _cargarVehiculos() async {
    try {
      final vehiculos =
          await (widget.cargarVehiculos?.call(widget.cliente.id) ??
              cargarVehiculosDeCliente(widget.cliente.id));
      if (!mounted) return;
      setState(() {
        _vehiculos = vehiculos;
        _errorVehiculos = null;
        _cargandoVehiculos = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorVehiculos = error.toString();
        _cargandoVehiculos = false;
      });
    }
  }

  void _abrirVehiculo(HistorialVehiculo vehiculo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaginaDetalleVehiculo(vehiculo: vehiculo),
      ),
    );
  }

  // Abre el historial completo de ventas filtrado por este cliente.
  void _abrirHistorialCompleto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaginaVentasHistorial(
          clienteId: widget.cliente.id,
          clienteNombre: widget.cliente.nombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Ver cliente “${widget.cliente.nombre}”',
    activo: 'Clientes', // Conserva el título dinámico.
    child: SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, espacio) {
          final formulario = Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'DATOS DEL CLIENTE',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                FormularioDatos(
                  ancho: espacio.maxWidth >= 900
                      ? espacio.maxWidth * 0.68
                      : espacio.maxWidth,
                  campos: [
                    CampoFormularioDatos(
                      controlador: _nombreCtrl,
                      etiqueta: 'NOMBRE:',
                      textoAyuda: 'Nombre del cliente',
                      habilitado: false,
                    ),
                    CampoFormularioDatos(
                      controlador: _fonoCtrl,
                      etiqueta: 'NÚMERO:',
                      textoAyuda: 'Teléfono del cliente',
                      tipoTeclado: TextInputType.phone,
                      habilitado: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                ListaVehiculosCliente(
                  vehiculos: _vehiculos,
                  cargando: _cargandoVehiculos,
                  error: _errorVehiculos,
                  alReintentar: () {
                    setState(() {
                      _cargandoVehiculos = true;
                      _errorVehiculos = null;
                    });
                    _cargarVehiculos();
                  },
                  alAbrir: _abrirVehiculo,
                ),
              ],
            ),
          ); // Agrupa los datos y acciones del cliente.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CartaNavegacion.accion(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_return),
                  label: const Text('VOLVER'),
                ),
              ), // Regresa sin modificar datos.
              const SizedBox(height: 24), // Separa el regreso del perfil.
              if (espacio.maxWidth >= 900)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: formulario),
                    const SizedBox(width: 40),
                    Expanded(flex: 3, child: _resumenCliente()),
                  ],
                ) // Sitúa el resumen a la derecha como Figma.
              else ...[
                formulario,
                const SizedBox(height: 28),
                _resumenCliente(),
              ], // Apila los datos sin reducir acciones en Android.
              const SizedBox(height: 28),
              _historialVentas(),
            ],
          ); // Finaliza la distribución del cliente.
        },
      ),
    ), // Permite desplazar la página.
  ); // Finaliza el marco común.

  Widget _historialVentas() {
    // Vista previa: muestra únicamente las ventas más recientes del cliente.
    final previa = _ventas.take(_ventasVistaPrevia).toList();
    final hayMas = _ventas.length > _ventasVistaPrevia;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'HISTORIAL DE VENTAS',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              hayMas
                  ? 'Mostrando ${previa.length} de ${_ventas.length} ventas'
                  : '${_ventas.length} ${_ventas.length == 1 ? 'venta' : 'ventas'}',
              style: const TextStyle(color: Color(0xFF616161)),
            ),
          ],
        ),
        if (hayMas) ...[
          // Acceso al historial completo del cliente con sus filtros.
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: CartaNavegacion.accion(
              onPressed: _abrirHistorialCompleto,
              icon: const Icon(Icons.history),
              label: const Text('VER HISTORIAL\nCOMPLETO'),
              tooltip: 'Ver historial completo de ventas del cliente',
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_cargandoHistorial)
        const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_errorHistorial != null)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text('No se pudo cargar el historial: $_errorHistorial'),
              const SizedBox(height: 12),
              CartaNavegacion.accion(
                onPressed: () {
                  setState(() => _cargandoHistorial = true);
                  _cargarHistorial();
                },
                child: const Text('REINTENTAR'),
              ),
            ],
          ),
        )
      else if (_ventas.isEmpty)
        Container(
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Este cliente aún no tiene ventas registradas.'),
        )
      else
        SizedBox(
          height: 400,
          child: TablaDatos(
            nombresColumnas: const ['NOMBRE PRODUCTO', 'EXPANDIR'],
            camposColumnas: const ['producto', ''],
            anchosColumnas: const [550, 130],
            filas: previa
                .map(
                  (venta) => <String, dynamic>{
                    'producto': venta.productosResumen,
                    'fecha': venta.fecha,
                    'venta': venta,
                  },
                )
                .toList(),
            celdasPersonalizadas: {
              1: (context, fila) => CartaNavegacion.accion(
                tipoBoton: 'icon',
                tooltip: 'Ver detalle de venta',
                child: const Icon(Icons.arrow_drop_down, size: 40),
                onPressed: () {
                  final venta = fila['venta'] as VentaRegistro;
                  Navigator.push(
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
                  );
                },
              ),
            },
          ),
        ),
      ],
    );
  }

  // Resume la identidad del cliente sin fotografías.
  Widget _resumenCliente() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F7F7),
      border: Border.all(color: const Color(0xFFE0E0E0)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: const Color(0xFFFF6D6D),
          child: const Icon(
            Icons.person_outline,
            size: 68,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.cliente.nombre,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text('RUT: ${widget.cliente.id}'),
        const SizedBox(height: 4),
        Text(
          widget.cliente.numero,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ],
    ),
  );
}
