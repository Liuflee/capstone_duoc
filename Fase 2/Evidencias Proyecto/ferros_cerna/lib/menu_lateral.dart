import 'package:flutter/material.dart';

// Asegúrate de que los nombres de los archivos coincidan con los tuyos
import 'main.dart';
import 'pagina_clientes.dart';
import 'pagina_inventario.dart';

class MenuLateral extends StatelessWidget {
  final String activo;

  const MenuLateral({super.key, required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[350],
      child: Column(
        children: [
          const SizedBox(height: 20),

          // BOTÓN PÁGINA PRINCIPAL
          InkWell(
            onTap: () {
              if (activo != 'Inicio') {
                // pushAndRemoveUntil borra el historial para que Inicio sea la base
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaginaPrincipal(),
                  ),
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: _MenuItem(
              icono: Icons.home,
              texto: 'Página\nPrincipal',
              activo: activo == 'Inicio',
            ),
          ),

          // BOTÓN CLIENTES
          InkWell(
            onTap: () {
              if (activo != 'Clientes') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaginaClientes(),
                  ),
                );
              }
            },
            child: _MenuItem(
              icono: Icons.person_outline,
              texto: 'Clientes',
              activo: activo == 'Clientes',
            ),
          ),

          // BOTÓN PERFIL (Sin ruta por ahora)
          const _MenuItem(
            icono: Icons.sentiment_satisfied,
            texto: 'Perfil',
            activo: false,
          ),

          // BOTÓN INVENTARIO
          InkWell(
            onTap: () {
              if (activo != 'Inventario') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaginaInventario(),
                  ),
                );
              }
            },
            child: _MenuItem(
              icono: Icons.cases_outlined,
              texto: 'Inventario',
              activo: activo == 'Inventario',
            ),
          ),

          const Spacer(),

          // BOTÓN CERRAR APLICACIÓN
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    // Lógica para cerrar sesión o salir de la app
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.power_settings_new,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'CERRAR\nAPLICACIÓN',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      color: activo ? Colors.red[400] : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(icono, color: activo ? Colors.black : Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: activo ? Colors.black : Colors.black87,
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
