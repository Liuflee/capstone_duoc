import 'package:ferros_cerna/pagina_inventario.dart';
import 'package:flutter/material.dart';
import 'menu_lateral.dart';

void main() {
  runApp(const MiAplicacion());
}

class MiAplicacion extends StatelessWidget {
  const MiAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Frenos Cerna',
      theme: ThemeData(
        fontFamily: 'Courier', 
      ),
      home: const PaginaPrincipal(),
    );
  }
}

class PaginaPrincipal extends StatelessWidget {
  const PaginaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el ancho de la pantalla
    final anchoPantalla = MediaQuery.of(context).size.width;
    // Definimos si es una pantalla grande (Desktop/Tablet) o pequeña (Teléfono)
    final esPantallaGrande = anchoPantalla > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
        // Si es pantalla pequeña, el botón del Drawer aparece automáticamente
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (esPantallaGrande) // Solo mostramos el logo en el AppBar si hay espacio
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[500],
                    child: const Icon(Icons.settings_input_component, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('Frenos\nCerna', style: TextStyle(color: Colors.black, fontSize: 16)),
                ],
              ),
            const Text('Inicio', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
            Row(
              children: [
                if (esPantallaGrande) // Ocultamos el nombre en celular para ahorrar espacio
                  const Text('Leonardo', style: TextStyle(color: Colors.black, fontSize: 16)),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.red[800],
                  child: const Icon(Icons.build, color: Colors.black),
                ),
              ],
            )
          ],
        ),
      ),
      // Si es pantalla pequeña, usamos un Drawer (menú hamburguesa)
      drawer: esPantallaGrande ? null : const Drawer(child: MenuLateral(activo: 'Inicio')),
        body: Row(
          children: [
            if (esPantallaGrande) const ContenedorMenuLateral(activo: 'Inicio'),
          
          // CONTENIDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('IMPORTANTE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    // Usamos WRAP en lugar de ROW. Se adaptará a la pantalla.
                    Wrap(
                      spacing: 20, // Espacio horizontal entre tarjetas
                      runSpacing: 20, // Espacio vertical cuando saltan de línea
                      alignment: WrapAlignment.center,
                      children: const [
                        _InfoCard(icono: Icons.people_outline, numero: '2', texto: 'VENTAS DEL\nDÍA'),
                        _InfoCard(icono: Icons.warning_amber_rounded, numero: '1', texto: 'NOTIFICACIONES'),
                        _InfoCard(icono: Icons.help_outline, numero: '23', texto: 'PRODUCTOS\nFALTANTES'),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text('TRABAJO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    // Usamos WRAP nuevamente
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        const _ActionCard(icono: Icons.menu_book, texto: 'HISTORIAL\nVEHÍCULOS'),
                        InkWell(
                          onTap: () {
                            // Esto hace la navegación a la nueva página
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PaginaInventario()),
                            );
                          },
                          child: const _ActionCard(icono: Icons.cases_outlined, texto: 'INVENTARIO'),
                        ),
                        _ActionCard(icono: Icons.warning_amber_rounded, texto: 'NOTIFICACIONES'),
                        _ActionCard(icono: Icons.attach_money, texto: 'VENTAS'),
                        _ActionCard(icono: Icons.bar_chart, texto: 'DATOS'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _InfoCard extends StatelessWidget {
  final IconData icono;
  final String numero;
  final String texto;

  const _InfoCard({required this.icono, required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Icon(icono, size: 30)],
          ),
          Text(numero, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _ActionCard({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 40),
          const SizedBox(width: 10),
          Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}