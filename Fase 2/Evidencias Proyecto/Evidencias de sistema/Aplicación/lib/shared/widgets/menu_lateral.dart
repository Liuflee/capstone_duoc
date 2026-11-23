import 'package:frenos_cerna/core/navigation/dimensiones_navegacion.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart'; // Recupera el listado e historial de los vehículos.

import 'package:flutter/foundation.dart'; // Identifica la plataforma actual.
import 'package:material_ui/material_ui.dart';
import 'package:frenos_cerna/core/navigation/nav_rutas.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart';
import 'package:frenos_cerna/features/inicio/pagina_inicio.dart';

class MenuLateral extends StatelessWidget {
  // Comparte navegación, relieve y cierre en todas las páginas.
  final String activo; // Identifica la sección seleccionada.
  const MenuLateral({
    super.key,
    required this.activo,
  }); // Conserva el constructor existente.
  static Drawer? desplegable(BuildContext context, {required String activo}) =>
      DimensionesNavegacion.usaMenuDesplegable(context)
      ? Drawer(child: MenuLateral(activo: activo))
      : null;

  Widget _botonCerrar(BuildContext context, double alto) => SafeArea(
    top: false,
    minimum: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: SizedBox(
        width: double.infinity, // Da al cierre una base completa y definida dentro del menú.
        child: Semantics(
          button: true,
          label: 'Cerrar aplicación',
          child: InkWell(
            // Mantiene la salida fija y fuera de la lista desplazable.
            key: const ValueKey(
              'cerrar_aplicacion',
            ), // Permite comprobar que se vea completa al abrir.
            onTap: NavegacionRutas.cerrarAplicacion, // Conserva la acción para toda el área del botón.
            borderRadius: BorderRadius.circular(
              12,
            ), // Mantiene un área de interacción cómoda.
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reduce el tamaño sin ocultarlo en ventanas bajas.
                  Container(
                    width: alto < 500 ? 48 : 56,
                    height: alto < 500 ? 48 : 56,
                    decoration: BoxDecoration(
                      color: PaletaTaller.de(context)
                          .adaptar(Color(0xFFD96363)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.power_settings_new,
                      size: alto < 500 ? 28 : 32,
                      color: PaletaTaller.de(context).adaptar(Colors.black),
                    ),
                  ), // Conserva un área de pulsación mínima de 48 píxeles.
                  const SizedBox(height: 6), // Separa el icono de su texto.
                  Text(
                    'CERRAR\nAPLICACIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: PaletaTaller.de(context)
                          .adaptar(Colors.black, tinta: true),
                    ),
                  ), // Mantiene la descripción completa.
                ],
              ),
            ), // Finaliza la zona de cierre.
          ),
        ),
      ),
    ),
  ); // Respeta los bordes seguros de Android y el borde inferior de Windows.
  @override // Mantiene el cierre visible y desplaza únicamente las opciones.
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: PaletaTaller.de(context).adaptar(
        Color(0xFFD6D6D6),
      ), // Recupera el fondo gris original debajo de las opciones.
      border: Border(
        right: BorderSide(
          color: PaletaTaller.de(context).adaptar(Colors.black, linea: true),
          width: 1,
        ),
      ), // Define un borde continuo sobre el contenido.
      boxShadow: [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 14,
          spreadRadius: 1,
          offset: Offset(5, 0),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, limites) {
        // Proyecta la sombra sobre el lado del contenido.
        return Column(
          children: [
            // Usa la altura disponible sin imponer los 700 píxeles anteriores.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(children: _opciones(context)),
              ),
            ), // Desplaza las opciones sin ocultar la salida.
            _botonCerrar(
              context,
              limites.maxHeight,
            ), // Ancla el cierre al borde inferior visible.
          ],
        ); // Finaliza la distribución responsive.
      },
    ),
  ); // Finaliza la superficie elevada.
  List<Widget> _opciones(BuildContext context) {
    final navegador = Navigator.of(context);
    final escritorio =
        kIsWeb || Theme.of(context).platform != TargetPlatform.android;
    final seccion = activo == 'Vehiculos' ? 'Vehículos' : activo;

    Widget enlace(String titulo, IconData icono, VoidCallback navegar) {
      final seleccionado = titulo == seccion;
      return _MenuItem(
        icono: icono,
        texto: titulo,
        activo: seleccionado,
        alPulsar: () {
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            navegador.pop();
          }
          if (!seleccionado) navegar();
        },
      );
    }

    void reemplazar(Widget pagina) =>
        navegador.pushReplacement(NavegacionRutas.sinAnimacion(pagina));

    return [
      enlace(
        'Página Principal',
        Icons.home_outlined,
        () => reemplazar(const PaginaInicio()),
      ),
      enlace(
        'Clientes',
        Icons.people_outline,
        () => reemplazar(const PaginaClientes()),
      ),
      enlace(
        'Vehículos',
        Icons.directions_car_outlined,
        () => reemplazar(const PaginaVehiculos()),
      ),
      if (escritorio)
        enlace(
          'Perfil',
          Icons.person_outline,
          () => navegador.pushNamed('/profile'),
        ),
      enlace(
        'Inventario',
        Icons.inventory_2_outlined,
        () => reemplazar(const PaginaInventario()),
      ),
      if (escritorio)
        enlace(
          'Dashboard',
          Icons.dashboard_outlined,
          () => navegador.pushNamed('/dashboard'),
        ),
      enlace(
        'Opciones',
        Icons.settings_outlined,
        () => navegador.pushNamed('/options'),
      ),
      if (escritorio)
        enlace(
          'Información',
          Icons.info_outline,
          () => navegador.pushNamed('/information'),
        ),
    ];
  }
}

class ContenedorMenuLateral extends StatelessWidget {
  final String activo;

  const ContenedorMenuLateral({super.key, required this.activo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: MenuLateral(activo: activo),
          );
        },
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool activo;
  final VoidCallback alPulsar;

  const _MenuItem({
    required this.icono,
    required this.texto,
    required this.activo,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = PaletaTaller.de(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Semantics(
        selected: activo,
        child: Material(
          color: activo
              ? paleta == PaletaTaller.original
                    ? paleta.acento
                    : Color.alphaBlend(
                        paleta.acento.withValues(alpha: .34),
                        paleta.menu,
                      )
              : paleta.menu,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            overlayColor: activo
                ? const WidgetStatePropertyAll(Colors.transparent)
                : null,
            onTap: alPulsar,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(icono, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        texto,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: activo
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
