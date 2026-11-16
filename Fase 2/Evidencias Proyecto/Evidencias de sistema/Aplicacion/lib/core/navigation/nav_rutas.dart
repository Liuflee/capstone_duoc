import 'dart:io' show exit;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:material_ui/material_ui.dart';

// se creara una clase para navegar entre las rutas sin animacion de transicion

class NavegacionRutas {
  NavegacionRutas._(); // Constructor privado para evitar instanciación

  static void cerrarAplicacion() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  static const inicio = '/inicio';

  static Route sinAnimacion(Widget pagina) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => pagina,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}
