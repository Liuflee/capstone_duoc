// Importa el historial real y sus páginas de detalle.
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_detalle_vehiculo.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
// Importa la distribución reutilizable de campos.
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';
// Importa las cartas que conservan las acciones de la página.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
// Importaciones de Flutter y los componentes del proyecto
import 'package:flutter/material.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';

import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

// Se crea la página de edición, que recibe el cliente seleccionado
class PaginaEditarCliente extends StatefulWidget {
  // Cliente cuyos datos se mostrarán y podrán modificarse
  final Cliente cliente;

  final Future<List<VentaRegistro>> Function(String)?
  cargarHistorial; // Permite verificar la consulta sin conexión real.
  // Constructor de la página
  const PaginaEditarCliente({
    super.key,
    required this.cliente,
    this.cargarHistorial,
  });

  @override
  State<PaginaEditarCliente> createState() => _PaginaEditarClienteState();
}

// Se crea el estado para administrar los campos y las operaciones de Supabase
class _PaginaEditarClienteState extends State<PaginaEditarCliente> {
  // Controladores de los campos que pueden editarse
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _fonoCtrl;

  // Evita que se repitan las operaciones mientras se guarda
  List<VentaRegistro> _ventas = []; // Conserva el historial real.
  String? _errorHistorial; // Conserva los errores de carga.
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    // Se cargan los datos originales en los campos del formulario
    _nombreCtrl = TextEditingController(text: widget.cliente.nombre);
    _fonoCtrl = TextEditingController(text: widget.cliente.numero);
    _cargarHistorial(); // Consulta las ventas del cliente.
  }

  @override
  void dispose() {
    // Libera los controladores cuando se cierra la página
    _nombreCtrl.dispose();
    _fonoCtrl.dispose();

    super.dispose();
  }

  // Se crea la función para actualizar los datos del cliente en Supabase
  Future<void> _guardarCliente() async {
    // Obtiene el nombre y el teléfono ingresados en el formulario
    final String nombre = _nombreCtrl.text.trim();
    final int? fono = int.tryParse(_fonoCtrl.text.trim());

    // Comprueba que los campos tengan valores válidos
    if (fono == null || nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre y teléfono válidos.')),
      );
      return;
    }

    // Deshabilita los botones mientras se envían los datos
    setState(() {
      _guardando = true;
    });

    try {
      // Actualiza el registro identificado por su RUT
      await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .update({'nombre': nombre, 'fono': fono})
          .eq('rut', int.parse(widget.cliente.id));

      // Evita utilizar el contexto si la página ya fue cerrada
      if (!mounted) return;

      // Vuelve a Clientes e indica que el listado debe actualizarse
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      // Informa si la actualización no se completó
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el cliente: $error')),
      );
    } finally {
      // Vuelve a habilitar los botones si la página continúa abierta
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // Conserva el historial del cliente para consultar sus ventas.

  Future<void> _cargarHistorial() async {
    try {
      final ventas =
          await (widget.cargarHistorial?.call(widget.cliente.id) ??
              VentaRegistro.obtenerPorCliente(widget.cliente.id));
      if (mounted) setState(() => _ventas = ventas);
    } catch (error) {
      if (mounted) setState(() => _errorHistorial = error.toString());
    }
  } // Recupera el historial real.

  Future<void> _revisarVehiculo() async {
    try {
      final datos = await SupabaseDatabase.client
          .from(SupabaseTables.vehiculos)
          .select(
            'patente, kilometraje, rut_cliente, cliente(nombre), modelo_vehiculo(modelo, marca_vehiculo(marca))',
          )
          .eq('rut_cliente', int.parse(widget.cliente.id))
          .limit(1);
      if (!mounted) return;
      if (datos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El cliente aún no tiene una patente registrada.'),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaginaDetalleVehiculo(
            vehiculo: HistorialVehiculo.fromJson(
              Map<String, dynamic>.from(datos.first),
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el vehículo: $error')),
        );
      }
    }
  } // Revisa un vehículo existente sin crear relaciones ficticias.

  @override
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Cliente “${widget.cliente.nombre}”',
    activo: 'Clientes', // Conserva el título dinámico.
    child: SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, espacio) {
          final formulario = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'VEHÍCULO DEL CLIENTE: ${widget.cliente.vehiculo}',
                style: const TextStyle(fontSize: 20),
              ), // Consulta el vehículo registrado sin inventar una columna de Cliente.
              Align(
                alignment: Alignment.centerLeft,
                child: CartaNavegacion.accion(
                  onPressed: _revisarVehiculo,
                  icon: const Icon(Icons.search),
                  label: const Text('REVISAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB7B7B7),
                    foregroundColor: Colors.black,
                  ),
                ),
              ), // Abre el vehículo registrado del cliente.
              const SizedBox(
                height: 44,
              ), // Separa el vehículo de los datos editables.
              FormularioDatos(
                ancho: 780,
                campos: [
                  CampoFormularioDatos(
                    controlador: _nombreCtrl,
                    etiqueta: 'NOMBRE:',
                    textoAyuda: 'Editar nombre',
                    habilitado: !_guardando,
                  ), // Conserva la edición de nombre.
                  CampoFormularioDatos(
                    controlador: _fonoCtrl,
                    etiqueta: 'NÚMERO:',
                    textoAyuda: 'Editar número',
                    tipoTeclado: TextInputType.phone,
                    habilitado: !_guardando,
                  ), // Conserva la edición de teléfono.
                ],
              ), // Alinea ambos campos del cliente.
            ],
          ); // Finaliza los datos editables.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 24), // Separa las acciones del historial.
              Align(
                alignment: Alignment.centerRight,
                child: const SizedBox.shrink(),
              ), // Conserva la función de guardado.
              const SizedBox(height: 28), // Separa la acción del historial.
              const Text(
                'HISTORIAL DE VENTAS',
                style: TextStyle(fontSize: 22),
              ), // Conserva el título de Figma.
              const SizedBox(height: 18), // Separa la tabla del título.
              if (_errorHistorial != null)
                Text(
                  'No se pudo cargar el historial: $_errorHistorial',
                ), // Informa errores reales.
              SizedBox(
                height: 400,
                child: TablaDatos(
                  nombresColumnas: const ['NOMBRE PRODUCTO', 'EXPANDIR'],
                  camposColumnas: const ['producto', ''],
                  anchosColumnas: const [
                    550,
                    130,
                  ], // Conserva el ancho y las proporciones del historial.
                  filas: _ventas
                      .map(
                        (venta) => <String, dynamic>{
                          'producto': venta.productosResumen,
                          'fecha': venta.fecha,
                          'venta': venta,
                        },
                      )
                      .toList(), // Sustituye los ejemplos por el historial del cliente.
                  celdasPersonalizadas: {
                    1: (context, fila) => CartaNavegacion.accion(
                      tipoBoton: 'icon',
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
                  }, // Abre el detalle de la venta correcta.
                ),
              ), // Mantiene los filtros encima de las filas.
            ],
          ); // Finaliza la distribución del cliente.
        },
      ),
    ), // Permite desplazar la página.
  ); // Finaliza el marco común.

  // Construye el resumen del cliente sin usar fotografías.
  Widget _resumenCliente() => Column(
    children: [
      CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFFFF6D6D),
        child: const Icon(Icons.person_outline, size: 80, color: Colors.black),
      ), // Conserva el avatar del prototipo sin imagen de cliente.
      const SizedBox(height: 16), // Separa el avatar del nombre.
      Text(
        widget.cliente.nombre,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22),
      ), // Conserva la identidad original.
      Text(
        widget.cliente.numero,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20),
      ), // Conserva el teléfono.
      const SizedBox(height: 30), // Separa la acción de guardar.
      CartaNavegacion.accion(
        onPressed: _guardando ? null : _guardarCliente,
        icon: const Icon(Icons.save_outlined),
        label: const Text('GUARDAR CAMBIOS'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD96363),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ), // Guarda los datos editados sin eliminar el cliente.
    ],
  ); // Finaliza el resumen.
}
