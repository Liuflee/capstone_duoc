
import 'package:flutter/material.dart';

// Se crea la clase barra superior
class BarraSuperior extends StatelessWidget {

  final String tituloPagina; // Nombre de la página actual
  final String nombreUsuario; // Nombre del usuario

  // Constructor de la clase
  const BarraSuperior({
    super.key,
    required this.tituloPagina,
    this.nombreUsuario = 'Leonardo',
  });

  @override
  Widget build(BuildContext context) {

    // Verifica si la pantalla tiene espacio suficiente
    final bool esPantallaGrande =
        MediaQuery.sizeOf(context).width >= 700;

    return Container(
      // Estilos del contenedor principal
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(
        color: Colors.grey[300],
      ),

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
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
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
                    child: Text(
                      nombreUsuario,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                ],

                // Ícono circular del usuario
                CircleAvatar(
                  backgroundColor: Colors.red[800],
                  child: const Icon(
                    Icons.build,
                    color: Colors.black,
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}
