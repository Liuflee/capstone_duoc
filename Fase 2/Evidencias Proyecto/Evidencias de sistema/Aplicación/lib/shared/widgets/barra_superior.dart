import 'package:supabase_flutter/supabase_flutter.dart'; // Permite cerrar únicamente la sesión de este dispositivo.
import 'package:frenos_cerna/core/data/supabase_database.dart'; // Reutiliza la sesión autenticada.
import 'package:frenos_cerna/features/autenticacion/presentation/puerta_autenticacion.dart'; // Regresa al acceso existente sin modificar su diseño.
import 'package:flutter/material.dart'; // Construye la identidad, el título y las acciones de la barra compartida.

import 'package:frenos_cerna/core/data/perfil_sesion.dart'; // Comparte el perfil entre páginas sin volver a cargar el nombre.
import 'package:frenos_cerna/features/autenticacion/data/autenticacion_repository.dart'; // Recupera el nombre real del perfil.

class BarraSuperior extends StatefulWidget {
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
      tituloPagina: widget.tituloPagina, // Conserva el título de cada vista.
      nombreUsuario: widget.nombreUsuario ?? estado.data?.nombre ?? '', // Evita mostrar un nombre provisional mientras se obtiene el perfil real.
      rolUsuario:
          widget.rolUsuario, // Conserva la presentación del rol existente.
      onCerrarSesion: _salir, // Ofrece la misma salida y regreso al login en todas las páginas.
    ),
  );
}

class _ContenidoBarraSuperior extends StatelessWidget {
  // Mantiene una única presentación para todas las páginas.
  final String tituloPagina; // Identifica la vista actual.
  final String nombreUsuario; // Presenta al usuario activo.
  final String? rolUsuario; // Describe su rol cuando está disponible.
  final Future<void> Function()?
  onCerrarSesion; // Conserva la salida de la sesión existente.
  const _ContenidoBarraSuperior({
    required this.tituloPagina,
    this.nombreUsuario = 'Usuario',
    this.rolUsuario,
    this.onCerrarSesion,
  }); // Conserva los constructores utilizados por las páginas.

  Future<void> _cerrarSesion(BuildContext context) async {
    // Conserva el tratamiento de errores de autenticación.
    try {
      await onCerrarSesion?.call();
    } catch (error) {
      // Ejecuta la acción proporcionada por la página.
      if (!context.mounted) {
        return; // Evita mostrar avisos desde una página cerrada.
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('No se pudo cerrar la sesión: $error')),
        ); // Informa el error sin cerrar la vista.
    } // Finaliza la salida de sesión.
  } // Finaliza la acción del usuario.

  Widget _marca(double ancho) => Container(
    // Ocupa todo el espacio de la marca sobre el menú.
    key: const ValueKey(
      'identidad_empresa',
    ), // Conserva la referencia de distribución de la barra.
    width: ancho,
    height: double.infinity,
    color: const Color(
      0xFFE0E0E0,
    ), // Iguala el fondo del logo con el gris de la barra superior.
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ), // Mantiene separación alrededor de la marca.
    child: Tooltip(
      message: 'Frenos Cerna',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Centra la identidad en su área completa.
          Flexible(
            child: Image.asset(
              'assets/images/logo_frenos_cerna.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
          ), // Conserva el logo original con mayor presencia.
          if (ancho >= 150) ...[
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'FRENOS\nCERNA',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF721919),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ], // Conserva la identidad escrita en escritorio.
        ],
      ),
    ), // Finaliza el contenido de la marca.
  ); // Finaliza el área blanca completa.

  Widget _titulo(bool compacto) => Tooltip(
    message: tituloPagina,
    child: Semantics(
      header: true,
      child: Container(
        // Destaca el título y conserva su nombre completo en la ayuda.
        key: const ValueKey(
          'titulo_pagina',
        ), // Permite comprobar el centro respecto del contenido.
        padding: EdgeInsets.symmetric(
          horizontal: compacto ? 12 : 20,
          vertical: compacto ? 6 : 10,
        ), // Ajusta la presentación a la altura disponible.
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: Color(0xFFA32321), width: 4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ), // Utiliza una superficie clara y un acento del rojo existente.
        child: Text(
          tituloPagina,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF721919),
            fontSize: compacto ? 18 : 22,
            fontWeight: FontWeight.w700,
          ),
        ), // Mejora la jerarquía del nombre sin cambiar el contenido de las páginas.
      ),
    ),
  ); // Finaliza el título destacado.

  Widget _usuario(BuildContext context, {required bool mostrarDatos}) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      // Conserva la información y las acciones de la cuenta.
      if (mostrarDatos) ...[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nombreUsuario,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
              if (rolUsuario != null)
                Text(
                  rolUsuario!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF616161),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
      ], // Evita reducir el espacio del título en móvil.
      Tooltip(
        message: rolUsuario ?? 'Usuario',
        child: const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFA32321),
          child: Icon(Icons.build, color: Colors.white, size: 21),
        ),
      ), // Conserva el indicador de usuario con mayor contraste.
      if (onCerrarSesion != null)
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () => _cerrarSesion(context),
          icon: const Icon(Icons.logout, size: 22),
        ), // Mantiene la función de salida de la sesión.
    ],
  ); // Finaliza la zona de usuario.

  @override // Alinea el título con el espacio real situado a la derecha del menú lateral.
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limites) {
      // Usa las dimensiones recibidas por la barra.
      final ancho = limites.maxWidth; // Conserva el ancho total de la página.
      final alto = limites.hasBoundedHeight
          ? limites.maxHeight
          : 72.0; // Respeta la altura común que asignan las páginas.
      final escritorio =
          MediaQuery.sizeOf(context).width >=
          700; // Comparte el punto de adaptación del menú lateral.
      final anchoMenu = escritorio ? ancho * 0.12 : 0.0; // Reserva exactamente el doce por ciento utilizado por el menú.
      final anchoUsuario = escritorio
          ? ((ancho - anchoMenu) * 0.20).clamp(112.0, 220.0)
          : (onCerrarSesion == null ? 44.0 : 92.0); // Limita el bloque de la cuenta sin desplazar el título.
      final reserva =
          anchoUsuario +
          12; // Reserva el mismo espacio a ambos lados del título.
      return Container(
        width: ancho,
        height: alto,
        decoration: const BoxDecoration(
          color: Color(0xFFE0E0E0),
          border: Border(bottom: BorderSide(color: Color(0xFFCCCCCC))),
        ),
        child: Row(
          children: [
            // Conserva el fondo gris de la barra.
            if (escritorio)
              SizedBox(
                width: anchoMenu,
                child: _marca(anchoMenu),
              ), // Sitúa el logo sobre la zona del menú.
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centra con independencia del ancho del usuario.
                  Positioned.fill(
                    left: reserva,
                    right: reserva,
                    top: 6,
                    bottom: 6,
                    child: Center(child: _titulo(!escritorio || alto < 80)),
                  ), // Hace coincidir el centro del título con el centro del contenido de cada página.
                  if (!escritorio)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Abrir menú',
                        onPressed: () =>
                            Scaffold.maybeOf(context)?.openDrawer(),
                        icon: const Icon(Icons.menu),
                      ),
                    ), // Conserva la navegación móvil.
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    width: anchoUsuario,
                    child: _usuario(context, mostrarDatos: escritorio),
                  ), // Mantiene los controles de cuenta en el extremo derecho.
                ],
              ),
            ), // Finaliza la zona que corresponde al contenido.
          ],
        ),
      ); // Finaliza la superficie de la barra.
    },
  ); // Finaliza el encabezado compartido.
} // Finaliza el widget.
