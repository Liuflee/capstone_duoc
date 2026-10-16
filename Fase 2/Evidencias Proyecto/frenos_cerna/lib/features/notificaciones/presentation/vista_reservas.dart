// Importa Flutter, datos y widgets compartidos.
import 'package:flutter/material.dart';
import 'package:frenos_cerna/features/notificaciones/data/reservas_repository.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

// Compone el catálogo y la lista de reservas conservando los controles compartidos.
class VistaReservas extends StatefulWidget {
  final bool reservados; // Selecciona la consulta y la acción de la pantalla.
  const VistaReservas({
    super.key,
    required this.reservados,
  }); // Configura la pantalla.
  @override // Crea el estado de consulta.
  State<VistaReservas> createState() => _VistaReservasState();
} // Finaliza la vista pública.

class _VistaReservasState extends State<VistaReservas> {
  late Future<List<Map<String, dynamic>>>
  _datos; // Conserva la consulta actual.
  bool _procesando = false; // Evita acciones simultáneas sobre reservas.
  @override // Consulta al abrir la pantalla.
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _datos = widget.reservados
        ? ReservasRepository.reservados()
        : ReservasRepository.catalogo();
  } // Selecciona la fuente real.

  Future<void> _accion(Map<String, dynamic> fila) async {
    if (_procesando) {
      return; // Evita registros duplicados por pulsaciones simultáneas.
    }
    setState(() => _procesando = true); // Actualiza las acciones.
    try {
      if (widget.reservados) {
        await ReservasRepository.remover(fila['id'].toString());
      } // Quita la reserva seleccionada.
      else {
        await ReservasRepository.reservar(fila['codigo_producto'].toString());
      } // Reserva el producto seleccionado.
      if (!mounted) return; // Evita avisos al cerrar la página.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.reservados ? 'Reserva eliminada.' : 'Producto reservado.',
          ),
        ),
      ); // Confirma la operación completada.
      setState(_recargar); // Recupera los datos actualizados.
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo completar la reserva: $error')),
        );
      }
    } // Conserva errores de conexión y duplicados.
    finally {
      if (mounted) setState(() => _procesando = false);
    } // Restablece las acciones.
  } // Finaliza la operación.

  @override // Construye la pantalla de reservas.
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: widget.reservados ? 'Productos reservados' : 'Reserva de producto',
    activo: 'Notificaciones',
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Alinea los controles con la tabla.
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: CartaNavegacion.accion(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_return),
            label: const Text('VOLVER A NOTIFICACIONES'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2A0A0),
              foregroundColor: Colors.black,
            ),
          ),
        ), // Conserva la navegación de regreso.
        const SizedBox(
          height: 28,
        ), // Separa el regreso de los controles de tabla.
        const Text(
          'Selección temporal de esta sesión. El esquema actual no incluye reservas persistentes.',
        ), // Indica el alcance real de la selección.
        const SizedBox(height: 16), // Separa la aclaración de la tabla.
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _datos, // Espera la consulta persistente.
            builder: (context, estado) {
              if (estado.hasError) {
                return Column(
                  children: [
                    Text(
                      'No se pudieron cargar los productos: ${estado.error}',
                    ),
                    CartaNavegacion.accion(
                      onPressed: () => setState(_recargar),
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                ); // Permite recuperar una consulta fallida.
              }
              if (!estado.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                ); // Conserva el estado de carga.
              }
              final filas = estado.data!.map((fila) {
                final producto = fila;
                return <String, dynamic>{
                  ...fila,
                  'nombre':
                      producto['cod_barra'] ??
                      producto['codigo_producto'].toString(),
                  'precio': producto['precio'],
                };
              }).toList(); // No inventa fechas de disponibilidad.
              return TablaDatos(
                nombresColumnas: [
                  'PRODUCTO',
                  'PRECIO',
                  widget.reservados ? 'REMOVER' : 'RESERVAR',
                ], // Conserva las columnas de las pantallas de reservas.
                camposColumnas: const ['nombre', 'precio', ''],
                anchosColumnas: const [420, 300, 290],
                filas: filas, // Conserva búsqueda y filtro por datos reales.
                celdasPersonalizadas: {
                  2: (context, fila) => CartaNavegacion.accion(
                    tipoBoton: 'icon',
                    onPressed: _procesando ? null : () => _accion(fila),
                    child: Icon(
                      widget.reservados
                          ? Icons.cancel_outlined
                          : Icons.add_circle_outline,
                      color: widget.reservados ? Colors.red : Colors.black,
                      size: 34,
                    ),
                  ),
                }, // Conserva las acciones de añadir y quitar.
              ); // Finaliza la tabla compartida.
            }, // Finaliza los estados de consulta.
          ),
        ), // Conserva el espacio disponible para la tabla.
      ], // Finaliza los elementos de la pantalla.
    ),
  ); // Finaliza el marco común.
} // Finaliza el estado de reservas.
