import 'package:flutter/material.dart'; // Conserva la entrada existente desde Inicio.
import 'package:frenos_cerna/features/notificaciones/presentation/vista_reservas.dart'; // Presenta las reservas persistentes.

class PaginaNotificaciones extends StatelessWidget {
  const PaginaNotificaciones({super.key}); // Mantiene las llamadas existentes.
  @override
  Widget build(BuildContext context) => const VistaReservas(reservados: false); // Muestra reservas en lugar de precios del inventario.
}
