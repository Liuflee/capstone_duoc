import 'package:flutter/material.dart';

// Se crea la clase barra superior
class BarraSuperior extends StatelessWidget {
  final String tituloPagina; // Nombre de la página actual
  final String nombreUsuario; // Nombre del usuario
  final String? rolUsuario;
  final Future<void> Function()? onCerrarSesion;

  // Constructor de la clase
  const BarraSuperior({
    super.key,
    required this.tituloPagina,
    this.nombreUsuario = 'Leonardo',
    this.rolUsuario,
    this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    // Verifica si la pantalla tiene espacio suficiente
    final bool esPantallaGrande = MediaQuery.sizeOf(context).width >= 700;

    return Container(
      // Estilos del contenedor principal
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(color: Colors.grey[300]),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // Logo y nombre de la empresa
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (esPantallaGrande) ...[
                  // Contenedor del logo
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.asset(
                      'assets/images/logo_frenos_cerna.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Nombre de la empresa
                  const Flexible(
                    child: Text(
                      'Frenos\nCerna',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ] else
                  // Botón del menú en pantallas pequeñas
                  IconButton(
                    onPressed: () {
                      Scaffold.maybeOf(context)?.openDrawer();
                    },
                    icon: const Icon(Icons.menu),
                  ),
              ],
            ),
          ),

          // Título de la página
          Expanded(
            flex: 4,
            child: Center(
              child: Text(
                tituloPagina,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Información del usuario
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,

              children: [
                // Nombre visible solamente en pantallas grandes
                if (esPantallaGrande) ...[
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          nombreUsuario,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        if (rolUsuario != null)
                          Text(
                            rolUsuario!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),
                ],

                // Ícono circular del usuario
                Tooltip(
                  message: rolUsuario ?? 'Usuario',
                  child: CircleAvatar(
                    backgroundColor: Colors.red[800],
                    child: const Icon(Icons.build, color: Colors.black),
                  ),
                ),

                if (onCerrarSesion != null)
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: () async {
                      try {
                        await onCerrarSesion!();
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('No se pudo cerrar la sesión: $error'),
                            ),
                          );
                      }
                    },
                    icon: const Icon(Icons.logout),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
