import 'package:frenos_cerna/core/navigation/dimensiones_navegacion.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frenos_cerna/core/navigation/nav_rutas.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart';
import 'package:frenos_cerna/features/notificaciones/pagina_notificaciones.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas_historial.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
import 'package:material_ui/material_ui.dart';

enum _Destino {
  inicio('Inicio', Icons.home_outlined, Icons.home, 'Página Principal'),
  ventas('Ventas', Icons.receipt_long_outlined, Icons.receipt_long, 'Ventas'),
  inventario(
    'Inventario',
    Icons.inventory_2_outlined,
    Icons.inventory_2,
    'Inventario',
  ),
  clientes('Clientes', Icons.people_outline, Icons.people, 'Clientes'),
  mas('Más', Icons.menu, Icons.menu, 'Más');

  const _Destino(this.etiqueta, this.icono, this.iconoActivo, this.seccion);
  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
  final String seccion;
}

class NavegacionInferior extends StatelessWidget {
  final String activo;
  final bool esRaizSeccion;

  const NavegacionInferior({
    super.key,
    required this.activo,
    this.esRaizSeccion = true,
  });

  static Widget? para(
    BuildContext context, {
    required String activo,
    bool habilitada = true,
    bool esRaizSeccion = true,
  }) {
    if (!habilitada ||
        !DimensionesNavegacion.usaBarraInferior(context) ||
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      return null;
    }
    return NavegacionInferior(activo: activo, esRaizSeccion: esRaizSeccion);
  }

  void _abrir(BuildContext context, _Destino destino) {
    if (esRaizSeccion && destino.seccion == activo) return;

    final navegador = Navigator.of(context);
    navegador.popUntil((ruta) => ruta.isFirst);
    final pagina = switch (destino) {
      _Destino.inicio => null,
      _Destino.ventas => const PaginaVentas(),
      _Destino.inventario => const PaginaInventario(),
      _Destino.clientes => const PaginaClientes(),
      _Destino.mas => const _PaginaMas(),
    };
    if (pagina != null) navegador.push(NavegacionRutas.sinAnimacion(pagina));
  }

  @override
  Widget build(BuildContext context) {
    final paleta = PaletaTaller.de(context);
    final indice = _Destino.values.indexWhere(
      (destino) => destino.seccion == activo,
    );
    final colorActivo = paleta.oscura
        ? paleta.texto
        : paleta.adaptar(const Color(0xFF721919), tinta: true);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paleta.barra,
        border: Border(
          top: BorderSide(color: paleta.borde.withValues(alpha: .25)),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith(
            (estado) => IconThemeData(
              color: estado.contains(WidgetState.selected)
                  ? colorActivo
                  : paleta.texto.withValues(alpha: .7),
              size: 22,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (estado) => TextStyle(
              fontSize: 11,
              fontWeight: estado.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: estado.contains(WidgetState.selected)
                  ? colorActivo
                  : paleta.texto.withValues(alpha: .7),
            ),
          ),
        ),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: NavigationBar(
            height: DimensionesNavegacion.altoBarraInferior,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            indicatorColor: paleta.acento.withValues(alpha: .22),
            selectedIndex: indice < 0 ? _Destino.mas.index : indice,
            onDestinationSelected: (i) => _abrir(context, _Destino.values[i]),
            destinations: [
              for (final destino in _Destino.values)
                NavigationDestination(
                  icon: Icon(destino.icono),
                  selectedIcon: Icon(destino.iconoActivo),
                  label: destino.etiqueta,
                  tooltip: destino.etiqueta,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginaMas extends StatelessWidget {
  const _PaginaMas();

  @override
  Widget build(BuildContext context) => PaginaTematica(
    builder: (context) => EstructuraPagina(
      titulo: 'Más',
      activo: 'Más',
      mostrarVolver: true,
      esRaizSeccion: true,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 64),
        children: [
          _AccesoMas(
            icono: Icons.directions_car_outlined,
            titulo: 'Vehículos',
            abrir: () => Navigator.of(context)
                .push(NavegacionRutas.sinAnimacion(const PaginaVehiculos())),
          ),
          _AccesoMas(
            icono: Icons.history,
            titulo: 'Historial de ventas',
            abrir: () => Navigator.of(
              context,
            ).push(NavegacionRutas.sinAnimacion(const PaginaVentasHistorial())),
          ),
          _AccesoMas(
            icono: Icons.bookmark_border,
            titulo: 'Reservas',
            abrir: () => Navigator.of(
              context,
            ).push(NavegacionRutas.sinAnimacion(const PaginaNotificaciones())),
          ),
          _AccesoMas(
            icono: Icons.settings_outlined,
            titulo: 'Opciones',
            abrir: () => Navigator.of(context).pushNamed('/options'),
          ),
          if (kIsWeb ||
              Theme.of(context).platform != TargetPlatform.android) ...[
            _AccesoMas(
              icono: Icons.person_outline,
              titulo: 'Perfil',
              abrir: () => Navigator.of(context).pushNamed('/profile'),
            ),
            _AccesoMas(
              icono: Icons.dashboard_outlined,
              titulo: 'Dashboard',
              abrir: () => Navigator.of(context).pushNamed('/dashboard'),
            ),
            _AccesoMas(
              icono: Icons.info_outline,
              titulo: 'Información',
              abrir: () => Navigator.of(context).pushNamed('/information'),
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.power_settings_new),
            title: const Text('Cerrar aplicación'),
            onTap: NavegacionRutas.cerrarAplicacion,
          ),
        ],
      ),
    ),
  );
}

class _AccesoMas extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback abrir;

  const _AccesoMas({
    required this.icono,
    required this.titulo,
    required this.abrir,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icono),
    title: Text(titulo),
    trailing: const Icon(Icons.chevron_right),
    onTap: abrir,
  );
}
