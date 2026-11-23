import 'package:frenos_cerna/core/navigation/dimensiones_navegacion.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Permite cerrar únicamente la sesión de este dispositivo.
import 'package:frenos_cerna/core/data/supabase_database.dart'; // Reutiliza la sesión autenticada.
import 'package:frenos_cerna/features/autenticacion/presentation/puerta_autenticacion.dart'; // Regresa al acceso existente sin modificar su diseño.
import 'package:material_ui/material_ui.dart'; // Construye la identidad, el título y las acciones de la barra compartida.

import 'package:frenos_cerna/core/data/perfil_sesion.dart'; // Comparte el perfil entre páginas sin volver a cargar el nombre.
import 'package:frenos_cerna/features/autenticacion/data/autenticacion_repository.dart'; // Recupera el nombre real del perfil.

export 'package:frenos_cerna/core/navigation/dimensiones_navegacion.dart';

class BarraSuperior extends StatefulWidget {
  final bool mostrarVolver;
  final String tituloPagina; // Conserva el título de la vista.
  final String?
  nombreUsuario; // Permite proporcionar el perfil ya cargado en Inicio.
  final String? rolUsuario; // Conserva el rol visible.
  final Future<void> Function()?
  onCerrarSesion; // Conserva la salida existente.
  const BarraSuperior({
    super.key,
    required this.tituloPagina,
    this.nombreUsuario,
    this.mostrarVolver = false,
    this.rolUsuario,
    this.onCerrarSesion,
  }); // Evita nombres personales predeterminados.
  @override
  State<BarraSuperior> createState() => _BarraSuperiorState(); // Conserva la consulta mientras la barra esté montada.
}

class _BarraSuperiorState extends State<BarraSuperior> {
  late Future<PerfilUsuario?>
  _perfil; // Reutiliza la consulta entre reconstrucciones.
  @override
  void initState() {
    super.initState(); // Inicializa el estado visual.
    _perfil = widget.nombreUsuario == null
        ? PerfilSesion.obtener()
        : Future.value(null); // Aprovecha el perfil proporcionado por Inicio.
  }

  Future<void> _salir() async {
    final navegador = Navigator.of(
      context,
      rootNavigator: true,
    ); // Conserva el navegador aunque la sesión reconstruya Inicio.
    if (widget.onCerrarSesion != null) {
      await widget.onCerrarSesion!(); // Conserva la salida personalizada y el modo de prueba.
    } else if (SupabaseDatabase.isConfigured) {
      await SupabaseDatabase.client.auth.signOut(
        scope: SignOutScope.local,
      ); // Cierra la sesión desde cualquier vista.
    }
    PerfilSesion.limpiar(); // Evita conservar el nombre al volver al acceso.
    if (!navegador.mounted) {
      return; // Evita navegar si ya se cerró la aplicación.
    }
    navegador.pushAndRemoveUntil<void>(
      MaterialPageRoute(builder: (_) => const PuertaAutenticacion()),
      (_) => false, // Elimina las páginas de la sesión anterior para impedir volver atrás.
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PerfilUsuario?>(
    future: _perfil, // Comparte la consulta de la sesión.
    initialData: PerfilSesion
        .actual, // Presenta el nombre guardado desde el primer fotograma.
    builder: (context, estado) => _ContenidoBarraSuperior(
      mostrarVolver: widget.mostrarVolver,
      tituloPagina: widget.tituloPagina, // Conserva el título de cada vista.
      nombreUsuario: widget.nombreUsuario ?? estado.data?.nombre ?? '', // Evita mostrar un nombre provisional mientras se obtiene el perfil real.
      rolUsuario:
          widget.rolUsuario, // Conserva la presentación del rol existente.
      onCerrarSesion: _salir, // Ofrece la misma salida y regreso al login en todas las páginas.
    ),
  );
}

class _ContenidoBarraSuperior extends StatelessWidget {
  final bool mostrarVolver;
  final String tituloPagina;
  final String nombreUsuario;
  final String? rolUsuario;
  final Future<void> Function() onCerrarSesion;

  const _ContenidoBarraSuperior({
    required this.mostrarVolver,
    required this.tituloPagina,
    required this.nombreUsuario,
    required this.rolUsuario,
    required this.onCerrarSesion,
  });

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      await onCerrarSesion();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('No se pudo cerrar la sesión: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final anchoMenu = DimensionesNavegacion.anchoMenuEn(context);
    final escritorio = anchoMenu > 0;
    final paleta = PaletaTaller.de(context);
    final tema = Theme.of(context);
    final ladoCuenta = ancho >= 1050 ? 220.0 : 144.0;
    final titulo = Semantics(
      header: true,
      child: Tooltip(
        message: tituloPagina,
        child: Text(
          tituloPagina,
          key: const ValueKey('titulo_pagina'),
          textAlign: escritorio ? TextAlign.center : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tema.textTheme.titleLarge?.copyWith(
            fontSize: escritorio ? 21 : 19,
            fontWeight: FontWeight.w700,
            color: paleta.adaptar(const Color(0xFF721919), tinta: true),
          ),
        ),
      ),
    );
    final volver =
        (mostrarVolver || !escritorio) && Navigator.of(context).canPop()
        ? IconButton(
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          )
        : null;
    final salir = IconButton(
      tooltip: 'Cerrar sesión',
      onPressed: () => _cerrarSesion(context),
      icon: const Icon(Icons.logout_outlined),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: paleta.barra,
        border: Border(
          bottom: BorderSide(color: paleta.borde.withValues(alpha: .25)),
        ),
      ),
      child: Row(
        children: [
          if (escritorio)
            SizedBox(
              width: anchoMenu,
              height: double.infinity,
              child: ColoredBox(
                key: const ValueKey('identidad_empresa'),
                color: paleta.barra,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo_frenos_cerna.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Frenos Cerna',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (DimensionesNavegacion.usaMenuDesplegable(context))
            IconButton(
              tooltip: 'Abrir menú',
              onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          if (escritorio)
            SizedBox(
              width: ladoCuenta,
              child: Align(alignment: Alignment.centerLeft, child: volver),
            )
          else
            volver ??
                SizedBox(
                  width: DimensionesNavegacion.usaMenuDesplegable(context)
                      ? 0
                      : 16,
                ),
          Expanded(child: titulo),
          if (escritorio)
            SizedBox(
              width: ladoCuenta,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            nombreUsuario,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.labelLarge,
                          ),
                        ),
                        if (rolUsuario != null)
                          Flexible(
                            child: Text(
                              rolUsuario!,
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tema.textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                  salir,
                  const SizedBox(width: 8),
                ],
              ),
            )
          else
            salir,
        ],
      ),
    );
  }
}
