import 'package:flutter/material.dart';

// se creara una clase para navegar entre las rutas sin animacion de transicion

class NavegacionRutas {
  NavegacionRutas._(); // Constructor privado para evitar instanciación
  static Route sinAnimacion(Widget pagina) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => pagina,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}