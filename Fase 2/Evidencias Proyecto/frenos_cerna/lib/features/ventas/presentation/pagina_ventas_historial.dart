import 'package:flutter/material.dart'; // Construye la vista independiente del historial completo.
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart'; // Comparte los borradores locales del usuario.
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart'; // Permite consultar las ventas concretadas.
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas.dart'; // Conserva el mismo diseño y los mismos filtros de Ventas.

class PaginaVentasHistorial extends StatelessWidget {
  // Separa el historial completo de la vista diaria.
  final VentasPendientesRepository?
  repositorioPendientes; // Conserva el mismo usuario al abrir una pendiente.
  final Future<List<VentaRegistro>> Function()?
  cargarVentas; // Permite comprobar el historial sin conexión real.
  const PaginaVentasHistorial({
    super.key,
    this.repositorioPendientes,
    this.cargarVentas,
  }); // Configura el origen del historial.
  @override // Utiliza la misma composición sin duplicar consultas o acciones.
  Widget build(BuildContext context) => PaginaVentas(
    mostrarHistorial: true,
    repositorioPendientes: repositorioPendientes,
    cargarVentas: cargarVentas,
  ); // Incluye todos los días y las ventas sin fecha conocida.
} // Finaliza la página independiente de historial.
