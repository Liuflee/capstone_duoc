import 'package:flutter/material.dart'; // Conserva compatibilidad con los accesos anteriores.
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas_historial.dart'; // Unifica todos los accesos al historial completo.

class PaginaHistorialVentas extends StatelessWidget {
  // Redirige las rutas existentes al nuevo historial.
  const PaginaHistorialVentas({
    super.key,
  }); // Conserva el constructor utilizado por las otras páginas.
  @override // Presenta el historial completo sin registrar una venta nueva.
  Widget build(BuildContext context) => const PaginaVentasHistorial(); // Comparte filtros, tabla y navegación del historial nuevo.
} // Finaliza la compatibilidad de navegación.
