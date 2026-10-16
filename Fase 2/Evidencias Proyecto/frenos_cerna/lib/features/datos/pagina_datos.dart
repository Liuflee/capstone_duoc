// Importa Flutter y las consultas existentes de ventas.
import 'package:flutter/material.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

// Presenta datos calculados únicamente con las tablas actuales.
class PaginaDatos extends StatefulWidget {
  const PaginaDatos({super.key}); // Crea la página.
  @override // Crea el estado de consulta.
  State<PaginaDatos> createState() => _PaginaDatosState();
} // Finaliza la página pública.

class _PaginaDatosState extends State<PaginaDatos> {
  late Future<List<VentaRegistro>> _ventas; // Conserva la consulta actual.
  @override // Consulta las ventas al abrir la página.
  void initState() {
    super.initState();
    _ventas = VentaRegistro.obtenerTodas();
  }

  @override // Construye la vista de datos reales.
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Datos',
    activo: 'Datos',
    child: FutureBuilder<List<VentaRegistro>>(
      future: _ventas, // Reutiliza las relaciones del repositorio existente.
      builder: (context, estado) {
        if (estado.hasError) {
          return Column(
            children: [
              Text('No se pudieron cargar los datos: ${estado.error}'),
              CartaNavegacion.accion(
                onPressed: () =>
                    setState(() => _ventas = VentaRegistro.obtenerTodas()),
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
        final ventas = estado.data!; // Obtiene las ventas recuperadas.
        final total = ventas.fold<double>(
          0,
          (suma, venta) => suma + venta.total,
        ); // Suma los detalles guardados sin inventar fechas.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                CartaNavegacion(
                  ancho: 260,
                  alto: 160,
                  numero: ventas.length.toString(),
                  texto: 'VENTAS REGISTRADAS',
                  icono: Icons.receipt_long,
                ), // Muestra la cantidad real de ventas.
                CartaNavegacion(
                  ancho: 320,
                  alto: 160,
                  numero: total.toStringAsFixed(0),
                  texto: 'TOTAL REGISTRADO',
                  icono: Icons.attach_money,
                ), // Muestra el importe real.
              ],
            ), // Finaliza los indicadores calculados.
            const SizedBox(
              height: 28,
            ), // Separa los indicadores de los registros.
            Expanded(
              child: TablaDatos(
                nombresColumnas: const ['CLIENTE', 'VEHÍCULO', 'TOTAL'],
                camposColumnas: const ['cliente', 'vehiculo', 'total'],
                anchosColumnas: const [3, 3, 2],
                filas: ventas
                    .map(
                      (venta) => <String, dynamic>{
                        'cliente': venta.clienteNombre,
                        'vehiculo': venta.vehiculoNombre,
                        'total': venta.total.toStringAsFixed(0),
                      },
                    )
                    .toList(),
              ),
            ), // Permite revisar y filtrar los datos que componen los indicadores.
          ],
        ); // Finaliza los datos de la página.
      }, // Finaliza los estados de consulta.
    ),
  ); // Finaliza el marco de página.
} // Finaliza el estado.
