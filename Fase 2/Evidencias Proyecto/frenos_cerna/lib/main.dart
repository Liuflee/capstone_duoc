
// Importaciones
import 'package:flutter/material.dart';

import 'package:frenos_cerna/core/navigation/nav_rutas.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';

import 'package:frenos_cerna/features/inicio/pagina_inicio.dart';

// Función principal de la aplicación
Future<void> main() async {

  // Inicializa los servicios de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la conexión con Supabase
  await SupabaseDatabase.initialize();

  // Ejecuta la aplicación
  runApp(const MiAplicacion());

}

// Se crea la clase principal de la aplicación
class MiAplicacion extends StatelessWidget {

  // Constructor de la clase
  const MiAplicacion({super.key});

  @override
  Widget build(BuildContext context) {

    // Configuración general de la aplicación
    return MaterialApp(

      // Oculta la etiqueta de DEBUG
      debugShowCheckedModeBanner: false,

      // Nombre de la aplicación
      title: 'Frenos Cerna',

      // Configuración visual general
      theme: ThemeData(

        // Fuente predeterminada
        fontFamily: 'Courier',

        // Configuración de las transiciones entre páginas
        pageTransitionsTheme: const PageTransitionsTheme(

          builders: {

            // Deshabilita animaciones de navegación en Windows
            TargetPlatform.windows:
                _SinAnimacionPageTransitionsBuilder(),

            // Deshabilita animaciones de navegación en Linux
            TargetPlatform.linux:
                _SinAnimacionPageTransitionsBuilder(),

            // Deshabilita animaciones de navegación en macOS
            TargetPlatform.macOS:
                _SinAnimacionPageTransitionsBuilder(),

          },
        ),
      ),

      // Configuración de las rutas de navegación
      onGenerateRoute: (settings) {

        // Ruta correspondiente a la página de inicio
        if (settings.name == NavegacionRutas.inicio) {

          // Navega a la página de inicio sin animación
          return NavegacionRutas.sinAnimacion(
            const PaginaInicio(),
          );

        }

        // Devuelve null cuando no reconoce la ruta
        return null;

      },

      // PÁGINA INICIAL DE LA APLICACIÓN

      // AQUÍ SE CAMBIA POR LA RUTA DEL LOGIN
      // CUANDO SE DESARROLLE EL SISTEMA DE AUTENTICACIÓN

      // Por ahora se muestra directamente la página de inicio
      home: const PaginaInicio(),

    );
  }
}

// Se crea una clase para eliminar las animaciones de navegación
class _SinAnimacionPageTransitionsBuilder
    extends PageTransitionsBuilder {

  // Constructor de la clase
  const _SinAnimacionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(

    // Ruta que se está mostrando
    PageRoute<T> route,

    // Contexto de Flutter
    BuildContext context,

    // Animación de entrada
    Animation<double> animation,

    // Animación de salida
    Animation<double> secondaryAnimation,

    // Widget correspondiente a la página
    Widget child,

  ) {

    // Devuelve directamente la página
    // sin aplicar animaciones de transición
    return child;

  }
}
