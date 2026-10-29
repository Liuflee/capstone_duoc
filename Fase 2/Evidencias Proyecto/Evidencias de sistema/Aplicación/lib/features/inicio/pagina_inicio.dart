import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart'; // Abre directamente el registro de una venta.
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas_historial.dart'; // Abre el historial completo.
import 'package:frenos_cerna/core/data/perfil_sesion.dart'; // Conserva el perfil autenticado para toda la navegación.
// Importaciones
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/autenticacion/data/autenticacion_repository.dart';
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

import 'package:frenos_cerna/features/inventario/pagina_inventario.dart';
import 'package:frenos_cerna/features/notificaciones/pagina_notificaciones.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas.dart';

// Se crea la clase PaginaInicio que extiende StatelessWidget
class PaginaInicio extends StatelessWidget {
  final PerfilUsuario? perfilUsuario;
  final bool modoPrueba;
  final VoidCallback? onSalirModoPrueba;

  // Constructor de la clase PaginaInicio
  const PaginaInicio({
    super.key,
    this.perfilUsuario,
    this.modoPrueba = false,
    this.onSalirModoPrueba,
  });

  @override
  Widget build(BuildContext context) {
    final plataforma = Theme.of(context).platform; // Identifica el dispositivo sin depender del tamaño de la ventana.
    final esMovil =
        plataforma == TargetPlatform.android ||
        plataforma == TargetPlatform.iOS; // Reserva el escaneo para celulares.
    if (perfilUsuario != null && !modoPrueba) {
      PerfilSesion.conservar(
        perfilUsuario!,
      ); // Conserva el perfil cargado al iniciar sesión para las demás vistas.
    }
    return Scaffold(
      // Conserva la navegación lateral en pantallas pequeñas.
      drawer: const Drawer(child: MenuLateral(activo: 'Página Principal')),
      // Color de fondo de la página
      backgroundColor: Colors.white,

      // Cuerpo de la página
      body: LayoutBuilder(
        // Se obtienen las dimensiones disponibles de la ventana
        builder: (context, constraints) {
          // Dimensiones de la ventana
          final double ancho = constraints.maxWidth;
          final double alto = constraints.maxHeight;

          // Se crea la distribución vertical de la página
          return Column(
            children: [
              // BARRA SUPERIOR
              SizedBox(
                width: ancho,
                height: alto * 0.10,

                // Se llama el widget de barra superior
                child: BarraSuperior(
                  tituloPagina: 'Página Principal',
                  nombreUsuario: perfilUsuario?.nombre, // Recupera el perfil compartido al volver desde el menú.
                  rolUsuario: modoPrueba
                      ? 'Sin sesión'
                      : perfilUsuario?.rol.etiqueta,
                  onCerrarSesion: modoPrueba
                      ? () async => onSalirModoPrueba?.call()
                      : () async {
                          await SupabaseDatabase.client.auth.signOut(
                            scope: SignOutScope.local,
                          );
                        },
                ),
              ),

              // ZONA DE WIDGETS
              Expanded(
                // Ocupa la altura restante de la página
                child: Row(
                  // Extiende los elementos verticalmente
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    // BARRA LATERAL
                    if (ancho >= 700) // Comparte el menú de escritorio y permite usar el desplegable en móvil.
                      SizedBox(
                        width: ancho * 0.12,

                        // Se llama el widget del menú lateral
                        child: const MenuLateral(activo: 'Página Principal'),
                      ),

                    // CONTENIDO PRINCIPAL
                    Expanded(
                      // Ocupa el ancho restante
                      child: Container(
                        // Estilos del contenedor principal
                        width: double.infinity,

                        // Padding superior reducido a 12
                        // para acercar el contenido a la barra superior
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

                        // Se calculan las dimensiones del contenido
                        child: LayoutBuilder(
                          builder: (context, espacio) {
                            // Ancho disponible del contenido principal
                            final double anchoContenido = espacio.maxWidth;

                            // Alto disponible del contenido principal
                            final double altoContenido = espacio.maxHeight;

                            // Separación entre tarjetas
                            const double separacion = 20;

                            // DIMENSIONES DE TARJETAS IMPORTANTES

                            // Calcula el ancho proporcional
                            // con un mínimo de 170 y máximo de 260
                            final double anchoImportante =
                                (anchoContenido * 0.17)
                                    .clamp(170.0, 260.0)
                                    .toDouble();

                            // Calcula el alto proporcional
                            // con un mínimo de 170 y máximo de 240
                            final double altoImportante = (altoContenido * 0.27)
                                .clamp(170.0, 240.0)
                                .toDouble();

                            // DIMENSIONES DE TARJETAS DE TRABAJO

                            // Se calcula el ancho necesario para
                            // distribuir tres tarjetas en una fila
                            // descontando las dos separaciones
                            final double anchoTrabajo =
                                ((anchoContenido - separacion * 2) / 3)
                                    .clamp(160.0, 360.0)
                                    .toDouble();

                            // Calcula el alto proporcional
                            // con un mínimo de 110 y máximo de 160
                            final double altoTrabajo = (altoContenido * 0.17)
                                .clamp(110.0, 160.0)
                                .toDouble();

                            // Función que permite navegar a otra página
                            void abrirPagina(Widget pagina) {
                              Navigator.push(
                                context,

                                MaterialPageRoute(builder: (context) => pagina),
                              );
                            }

                            // Permite desplazarse verticalmente
                            // si el contenido supera el espacio disponible
                            return SingleChildScrollView(
                              // Se distribuyen las secciones verticalmente
                              child: Column(
                                // Ocupa todo el ancho disponible
                                crossAxisAlignment: CrossAxisAlignment.stretch,

                                // Posiciona el contenido desde arriba
                                // evitando espacios vacíos innecesarios
                                mainAxisAlignment: MainAxisAlignment.start,

                                children: [
                                  // SECCIÓN IMPORTANTE

                                  // Título de la sección
                                  const Text(
                                    'IMPORTANTE',

                                    textAlign: TextAlign.center,

                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  // Separación entre título y tarjetas
                                  const SizedBox(height: 20),

                                  // Contenedor de tarjetas importantes
                                  Wrap(
                                    // Separación horizontal
                                    spacing: separacion,

                                    // Separación vertical
                                    runSpacing: separacion,

                                    // Centra las tarjetas
                                    alignment: WrapAlignment.center,

                                    children: [
                                      // Tarjeta ventas del día
                                      CartaNavegacion(
                                        ancho: anchoImportante,
                                        alto: altoImportante,
                                        icono: Icons.people_outline,
                                        numero: '2',
                                        texto: 'VENTAS DEL\nDÍA',

                                        // Color opcional
                                        // color: Colors.red[100],

                                        // Navega a ventas
                                        alPresionar: () {
                                          abrirPagina(const PaginaVentas());
                                        },
                                      ),

                                      // Tarjeta para reservar productos.
                                      CartaNavegacion(
                                        ancho: anchoImportante,
                                        alto: altoImportante,
                                        icono: Icons.add,

                                        texto: 'NUEVA VENTA',

                                        color: const Color(0xFFD96363), // Usa el rojo compartido por las acciones de registro.
                                        // Abre directamente el registro de una nueva venta
                                        alPresionar: () {
                                          abrirPagina(const PaginaCrearVenta());
                                        },
                                      ),

                                      // Tarjeta de escaneo en móvil y acceso a datos en escritorio.
                                      CartaNavegacion(
                                        ancho: anchoImportante,
                                        alto: altoImportante,
                                        icono: esMovil
                                            ? Icons.barcode_reader
                                            : Icons.bar_chart, // Representa la acción disponible en cada dispositivo.
                                        texto: esMovil
                                            ? 'ESCANEAR PRODUCTO'
                                            : 'DATOS',

                                        // Color opcional
                                        // color: Colors.orange[100],

                                        // Mantiene el escaneo pendiente y conserva la ruta de datos en escritorio.
                                        alPresionar: esMovil
                                            ? null
                                            : () => Navigator.pushNamed(
                                                context,
                                                '/data',
                                              ),
                                      ),
                                    ],
                                  ),

                                  // SEPARACIÓN ENTRE SECCIONES
                                  const SizedBox(height: 36),

                                  // SECCIÓN TRABAJO

                                  // Título de la sección
                                  const Text(
                                    'TRABAJO',

                                    textAlign: TextAlign.center,

                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  // Separación entre título y tarjetas
                                  const SizedBox(height: 20),

                                  // PRIMERA FILA DE TRABAJO
                                  // Contiene tres tarjetas
                                  Wrap(
                                    spacing: separacion,
                                    runSpacing: separacion,
                                    alignment: WrapAlignment.center,

                                    children: [
                                      // Tarjeta historial de vehículos
                                      CartaNavegacion(
                                        ancho: anchoTrabajo,
                                        alto: altoTrabajo,
                                        icono: Icons.menu_book,
                                        texto: 'HISTORIAL\nDE VENTAS',

                                        // Abre el historial completo de ventas
                                        alPresionar: () {
                                          abrirPagina(
                                            const PaginaVentasHistorial(),
                                          );
                                        },
                                      ),

                                      // Tarjeta inventario
                                      CartaNavegacion(
                                        ancho: anchoTrabajo,
                                        alto: altoTrabajo,
                                        icono: Icons.cases_outlined,
                                        texto: 'INVENTARIO',

                                        // Navega a inventario
                                        alPresionar: () {
                                          abrirPagina(const PaginaInventario());
                                        },
                                      ),

                                      // Tarjeta notificaciones
                                      CartaNavegacion(
                                        ancho: anchoTrabajo,
                                        alto: altoTrabajo,
                                        icono: Icons.bookmark_add_outlined,
                                        texto: 'RESERVAR PRODUCTO',

                                        // Conserva el acceso a las opciones de reserva
                                        alPresionar: () {
                                          abrirPagina(
                                            const PaginaNotificaciones(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                                  // Separación entre las filas de trabajo
                                  const SizedBox(height: 20),

                                  // SEGUNDA FILA DE TRABAJO
                                  // Contiene dos tarjetas
                                  Wrap(
                                    spacing: separacion,
                                    runSpacing: separacion,
                                    alignment: WrapAlignment.center,

                                    children: [
                                      // Tarjeta ventas
                                      CartaNavegacion(
                                        ancho: anchoTrabajo,
                                        alto: altoTrabajo,
                                        icono: Icons.attach_money,
                                        texto: 'VENTAS',

                                        // Navega a ventas
                                        alPresionar: () {
                                          abrirPagina(const PaginaVentas());
                                        },
                                      ),

                                      // Abre el resumen del negocio.
                                      CartaNavegacion(
                                        ancho: anchoTrabajo,
                                        alto: altoTrabajo,
                                        icono: Icons.dashboard_outlined,
                                        texto: 'DASHBOARD',

                                        alPresionar: () => Navigator.pushNamed(
                                          context,
                                          '/dashboard',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
