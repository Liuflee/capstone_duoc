
// Importaciones
import 'package:flutter/material.dart';

import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

import 'package:frenos_cerna/features/inventario/pagina_inventario.dart';
import 'package:frenos_cerna/features/notificaciones/pagina_notificaciones.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas.dart';

// Se crea la clase PaginaInicio que extiende StatelessWidget
class PaginaInicio extends StatelessWidget {

  // Constructor de la clase PaginaInicio
  const PaginaInicio({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // Color de fondo de la página
      backgroundColor: Colors.grey[200],

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
                child: const BarraSuperior(
                  tituloPagina: 'Página Principal',
                ),
              ),

              // ZONA DE WIDGETS
              Expanded( // Ocupa la altura restante de la página
                child: Row(

                  // Extiende los elementos verticalmente
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    // BARRA LATERAL
                    SizedBox(
                      width: ancho * 0.12,

                      // Se llama el widget del menú lateral
                      child: const MenuLateral(
                        activo: 'Página Principal',
                      ),
                    ),

                    // CONTENIDO PRINCIPAL
                    Expanded( // Ocupa el ancho restante
                      child: Container(

                        // Estilos del contenedor principal
                        width: double.infinity,

                        // Padding superior reducido a 12
                        // para acercar el contenido a la barra superior
                        padding: const EdgeInsets.fromLTRB(
                          20, 12, 20, 20,
                        ),

                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),

                        // Se calculan las dimensiones del contenido
                        child: LayoutBuilder(

                          builder: (context, espacio) {

                            // Ancho disponible del contenido principal
                            final double anchoContenido =
                                espacio.maxWidth;

                            // Alto disponible del contenido principal
                            final double altoContenido =
                                espacio.maxHeight;

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
                            final double altoImportante =
                                (altoContenido * 0.27)
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
                            final double altoTrabajo =
                                (altoContenido * 0.17)
                                    .clamp(110.0, 160.0)
                                    .toDouble();

                            // Función que permite navegar a otra página
                            void abrirPagina(Widget pagina) {

                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (context) => pagina,
                                ),
                              );

                            }

                            // Permite desplazarse verticalmente
                            // si el contenido supera el espacio disponible
                            return SingleChildScrollView(

                              // Se distribuyen las secciones verticalmente
                              child: Column(

                                // Ocupa todo el ancho disponible
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,

                                // Posiciona el contenido desde arriba
                                // evitando espacios vacíos innecesarios
                                mainAxisAlignment:
                                    MainAxisAlignment.start,

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
                                          abrirPagina(
                                            const PaginaVentas(),
                                          );
                                        },
                                      ),

                                      // Tarjeta notificaciones
                                      CartaNavegacion(
                                        ancho: anchoImportante,
                                        alto: altoImportante,
                                        icono: Icons.warning_amber_rounded,
                                        numero: '1',
                                        texto: 'NOTIFICACIONES',

                                        // Color opcional
                                        // color: Colors.amber[100],

                                        // Navega a notificaciones
                                        alPresionar: () {
                                          abrirPagina(
                                            const PaginaNotificaciones(),
                                          );
                                        },
                                      ),

                                      // Tarjeta productos faltantes
                                      CartaNavegacion(
                                        ancho: anchoImportante,
                                        alto: altoImportante,
                                        icono: Icons.help_outline,
                                        numero: '23',
                                        texto: 'PRODUCTOS\nFALTANTES',

                                        // Color opcional
                                        // color: Colors.orange[100],

                                        // Navega a inventario
                                        alPresionar: () {
                                          abrirPagina(
                                            const PaginaInventario(),
                                          );
                                        },
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
                                        texto: 'HISTORIAL\nVEHÍCULOS',

                                        // Navega al historial de vehículos
                                        alPresionar: () {
                                          abrirPagina(
                                            const PaginaVehiculos(),
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
                                          abrirPagina(
                                            const PaginaInventario(),
                                          );
                                        },
                                      ),

                                      // Tarjeta notificaciones
                                      CartaNavegacion(
                                        ancho: anchoTrabajo,
                                        alto: altoTrabajo,
                                        icono: Icons.warning_amber_rounded,
                                        texto: 'NOTIFICACIONES',

                                        // Navega a notificaciones
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
                                          abrirPagina(
                                            const PaginaVentas(),
                                          );
                                        },
                                      ),

                                      // Tarjeta datos
                                      CartaNavegacion(
                                        ancho: anchoTrabajo,
                                        alto: altoTrabajo,
                                        icono: Icons.bar_chart,
                                        texto: 'DATOS',

                                        // Navegación pendiente
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
