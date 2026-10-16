// Reutiliza Flutter y la vista común de reservas.
import 'package:flutter/material.dart';
import 'package:frenos_cerna/features/notificaciones/presentation/vista_reservas.dart';

// Identifica una pantalla independiente del flujo de reservas.
class PaginaReservaProducto extends StatelessWidget {
  const PaginaReservaProducto({super.key}); // Crea la pantalla.
  @override // Construye la vista con su consulta correspondiente.
  Widget build(BuildContext context) => const VistaReservas(reservados: false);
} // Finaliza la pantalla.
