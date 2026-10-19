import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas_historial.dart'; // Registra el acceso independiente al historial completo.
// Importa el registro de vehículos con vinculación de clientes.
import 'package:frenos_cerna/features/vehiculos/pagina_crear_vehiculo.dart';
// Importa una pantalla del prototipo con ruta en inglés.
import 'package:frenos_cerna/features/notificaciones/pagina_productos_reservados.dart';
// Importa una pantalla del prototipo con ruta en inglés.
import 'package:frenos_cerna/features/notificaciones/pagina_reserva_producto.dart';
// Importa una pantalla del prototipo con ruta en inglés.
import 'package:frenos_cerna/features/inventario/pagina_crear_producto.dart';
// Importa una pantalla del prototipo con ruta en inglés.
import 'package:frenos_cerna/features/datos/pagina_datos.dart';
// Importa una pantalla del prototipo con ruta en inglés.
import 'package:frenos_cerna/features/informacion/pagina_informacion.dart';
// Importa una pantalla del prototipo con ruta en inglés.
import 'package:frenos_cerna/features/opciones/pagina_opciones.dart';
// Importa una pantalla del prototipo con ruta en inglés.
import 'package:frenos_cerna/features/perfil/pagina_perfil.dart';
// Importaciones
import 'package:flutter/material.dart';

import 'package:frenos_cerna/core/navigation/nav_rutas.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';

import 'package:frenos_cerna/features/autenticacion/presentation/puerta_autenticacion.dart';

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
      // Declara las rutas nuevas sin cambiar las rutas existentes.
      routes: {
        '/sales/history': (context) => const PaginaVentasHistorial(), // Mantiene la ruta en inglés y el archivo en español.
        '/vehicles/new': (context) => const PaginaCrearVehiculo(),
        '/profile': (context) => const PaginaPerfil(),
        '/options': (context) => const PaginaOpciones(),
        '/information': (context) => const PaginaInformacion(),
        '/data': (context) => const PaginaDatos(),
        '/products/new': (context) => const PaginaCrearProducto(),
        '/notifications/reserve': (context) => const PaginaReservaProducto(),
        '/notifications/reserved': (context) =>
            const PaginaProductosReservados(),
      },
      // Aplica las preferencias sin modificar los widgets compartidos.
      builder: (context, child) => AnimatedBuilder(
        animation: PreferenciasVisuales.instancia,
        builder: (context, _) {
          final ajustes = PreferenciasVisuales.instancia;
          final entorno = MediaQuery.of(context);
          return ColorFiltered(
            colorFilter: ColorFilter.matrix(ajustes.matriz),
            child: MediaQuery(
              data: entorno.copyWith(
                textScaler: TextScaler.linear(
                  entorno.textScaler.scale(1) * ajustes.texto,
                ),
              ),
              child: ColoredBox(
                color: const Color(0xFFE0E0E0), // Prolonga el gris del encabezado detrás de la barra de estado.
                child: SafeArea(
                  bottom: false, // Conserva el tratamiento inferior de cada página y del teclado.
                  child: child!, // Mantiene todas las rutas debajo de la barra de estado y fuera de los recortes laterales.
                ),
              ),
            ),
          );
        },
      ),

      // Configuración visual general
      theme: ThemeData(
        // Fuente predeterminada
        fontFamily: 'Courier',

        // Configuración de las transiciones entre páginas
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            // Deshabilita animaciones de navegación en Windows
            TargetPlatform.windows: _SinAnimacionPageTransitionsBuilder(),

            // Deshabilita animaciones de navegación en Linux
            TargetPlatform.linux: _SinAnimacionPageTransitionsBuilder(),

            // Deshabilita animaciones de navegación en macOS
            TargetPlatform.macOS: _SinAnimacionPageTransitionsBuilder(),
          },
        ),
      ),

      // Configuración de las rutas de navegación
      onGenerateRoute: (settings) {
        // Ruta correspondiente a la página de inicio
        if (settings.name == NavegacionRutas.inicio) {
          // Navega a la página de inicio sin animación
          return NavegacionRutas.sinAnimacion(const PuertaAutenticacion());
        }

        // Devuelve null cuando no reconoce la ruta
        return null;
      },

      home: const PuertaAutenticacion(),
    );
  }
}

// Se crea una clase para eliminar las animaciones de navegación
class _SinAnimacionPageTransitionsBuilder extends PageTransitionsBuilder {
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
