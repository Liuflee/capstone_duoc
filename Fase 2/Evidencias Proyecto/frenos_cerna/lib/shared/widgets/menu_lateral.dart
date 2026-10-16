import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart'; // Recupera el listado e historial de los vehículos.

import 'dart:io' show exit; // Permite cerrar el proceso de escritorio.

import 'package:flutter/foundation.dart'; // Identifica la plataforma actual.
import 'package:flutter/services.dart'; // Solicita el cierre de la actividad Android.
import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/navigation/nav_rutas.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart';
import 'package:frenos_cerna/features/inicio/pagina_inicio.dart';

// Asegúrate de que los nombres de los archivos coincidan con los tuyos

class MenuLateral extends StatelessWidget {
  // Comparte navegación, relieve y cierre en todas las páginas.
  final String activo; // Identifica la sección seleccionada.
  const MenuLateral({
    super.key,
    required this.activo,
  }); // Conserva el constructor existente.
  void _cerrarAplicacion() {
    // Conserva la salida según la plataforma.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      exit(0);
    } else {
      SystemNavigator.pop();
    } // Cierra Windows o la actividad de Android.
  } // Finaliza la acción de cierre.

  Widget _botonCerrar(double alto) => SafeArea(
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
            onTap: _cerrarAplicacion, // Conserva la acción para toda el área del botón.
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFD96363),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.power_settings_new,
                      size: alto < 500 ? 28 : 32,
                      color: Colors.black,
                    ),
                  ), // Conserva un área de pulsación mínima de 48 píxeles.
                  const SizedBox(height: 6), // Separa el icono de su texto.
                  const Text(
                    'CERRAR\nAPLICACIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black),
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
    decoration: const BoxDecoration(
      color: Color(
        0xFFD6D6D6,
      ), // Recupera el fondo gris original debajo de las opciones.
      border: Border(
        right: BorderSide(color: Colors.black, width: 1),
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
                child: Column(children: _opciones(context)),
              ),
            ), // Desplaza las opciones sin ocultar la salida.
            _botonCerrar(
              limites.maxHeight,
            ), // Ancla el cierre al borde inferior visible.
          ],
        ); // Finaliza la distribución responsive.
      },
    ),
  ); // Finaliza la superficie elevada.
  List<Widget> _opciones(BuildContext context) => [
    // Conserva el orden de navegación.

    // BOTÓN PÁGINA PRINCIPAL
    InkWell(
      onTap: () {
        if (activo != 'Página Principal') {
          Navigator.pushReplacement(
            context,
            NavegacionRutas.sinAnimacion(const PaginaInicio()),
          );
        }
      },
      child: _MenuItem(
        icono: Icons.home,
        texto: 'Página\nPrincipal',
        activo: activo == 'Página Principal',
      ),
    ),

    // BOTÓN CLIENTES
    InkWell(
      onTap: () {
        if (activo != 'Clientes') {
          Navigator.pushReplacement(
            context,
            NavegacionRutas.sinAnimacion(const PaginaClientes()),
          );
        }
      },
      child: _MenuItem(
        icono: Icons.person_outline,
        texto: 'Clientes',
        activo: activo == 'Clientes',
      ),
    ),

    InkWell(
      onTap: () {
        if (activo != 'Vehiculos' && activo != 'Vehículos') {
          Navigator.pushReplacement(
            context,
            NavegacionRutas.sinAnimacion(const PaginaVehiculos()),
          );
        }
      }, // Recupera el acceso al historial de vehículos.
      child: _MenuItem(
        icono: Icons.directions_car_outlined,
        texto: 'Vehículos',
        activo: activo == 'Vehiculos' || activo == 'Vehículos',
      ), // Añade Vehículos debajo de Clientes.
    ),
    InkWell(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: _MenuItem(
        icono: Icons.sentiment_satisfied,
        texto: 'Perfil',
        activo: activo == 'Perfil',
      ),
    ), // Conecta la sección de perfiles desde todas las páginas.
    // BOTÓN INVENTARIO
    InkWell(
      onTap: () {
        if (activo != 'Inventario') {
          Navigator.pushReplacement(
            context,
            NavegacionRutas.sinAnimacion(const PaginaInventario()),
          );
        }
      },
      child: _MenuItem(
        icono: Icons.cases_outlined,
        texto: 'Inventario',
        activo: activo == 'Inventario',
      ),
    ),

    // BOTÓN PAGINAS DE PRUEBA
    InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/options',
        ); // Abre Opciones conservando el diseño del menú.
      },
      child: _MenuItem(
        icono: Icons.science_outlined,
        texto: 'Opciones',
        activo: activo == 'Opciones',
      ),
    ),
    InkWell(
      onTap: () => Navigator.pushNamed(context, '/information'),
      child: _MenuItem(
        icono: Icons.info_outline,
        texto: 'Información',
        activo: activo == 'Información',
      ),
    ), // Conecta la página de ayuda sin cambiar el estilo.
  ]; // Finaliza las opciones.
} // Finaliza el widget compartido.

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

// Widget interno para el diseño de cada ítem

class _MenuItem extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool activo;

  const _MenuItem({
    required this.icono,
    required this.texto,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: activo
          ? const Color.fromARGB(255, 163, 35, 33)
          : const Color.fromARGB(255, 114, 25, 25),
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          const SizedBox(width: 10),

          Icon(icono, color: activo ? Colors.black : Colors.white),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: activo ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
