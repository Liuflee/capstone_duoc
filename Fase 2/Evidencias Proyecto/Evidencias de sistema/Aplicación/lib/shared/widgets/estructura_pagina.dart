// Importa los widgets visuales de Flutter.
import 'package:flutter/material.dart';
// Reutiliza la barra superior existente sin cambiar su diseño.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
// Reutiliza el menú lateral existente sin cambiar sus dimensiones.
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';

// Compone páginas nuevas con las proporciones comunes de Inicio.
class EstructuraPagina extends StatelessWidget {
  final String titulo; // Título visible de la página.
  final String activo; // Sección activa del menú lateral.
  final Widget child; // Contenido específico de la página.
  final EdgeInsetsGeometry
  padding; // Margen del contenido definido por la página.
  const EstructuraPagina({
    super.key,
    required this.titulo,
    required this.activo,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(40, 24, 40, 24),
  }); // Configura la composición de la página.
  @override // Construye el marco común.
  Widget build(BuildContext context) {
    final pantalla = MediaQuery.sizeOf(
      context,
    ); // Obtiene el tamaño disponible.
    return Scaffold(
      backgroundColor:
          Colors.white, // Conserva el fondo de los diseños de Figma.
      drawer: Drawer(
        child: MenuLateral(activo: activo),
      ), // Conserva la navegación en Android.
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          pantalla.height * 0.10,
        ), // Comparte el alto de Inicio.
        child: SizedBox(
          height: pantalla.height * 0.10,
          child: BarraSuperior(tituloPagina: titulo),
        ), // Reutiliza el encabezado existente.
      ), // Finaliza el encabezado.
      body: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Extiende el menú verticalmente.
        children: [
          if (pantalla.width >= 700)
            SizedBox(
              width: pantalla.width * 0.12,
              child: MenuLateral(activo: activo),
            ), // Comparte el ancho lateral de Inicio.
          Expanded(
            child: Padding(
              padding: pantalla.width < 700
                  ? const EdgeInsets.all(16)
                  : padding,
              child: child,
            ),
          ), // Adapta los márgenes del contenido.
        ], // Finaliza las áreas de la página.
      ), // Finaliza la distribución horizontal.
    ); // Finaliza la página.
  } // Finaliza la construcción.
} // Finaliza el marco reutilizable.
