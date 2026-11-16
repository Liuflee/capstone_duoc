import 'package:frenos_cerna/core/tema/paleta_taller.dart';

// Importa Flutter y los widgets compartidos de la aplicación.
import 'package:material_ui/material_ui.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';

// Presenta las preguntas de ayuda con la distribución vertical de Figma.
class PaginaInformacion extends StatelessWidget {
  const PaginaInformacion({super.key}); // Crea la página de ayuda.
  static const _preguntas = <String, String>{
    '¿Qué hace la ventana “Clientes”?': 'Permite consultar, registrar y editar clientes. El buscador y los filtros actúan sobre los datos mostrados en la tabla.',
    '¿Qué hace la ventana “Perfil”?': 'Permite ver tu perfil y consultar los perfiles de dueño y mecánico disponibles. Solo el dueño puede crear, editar o retirar perfiles; no puede retirar su propio perfil.',
    '¿Qué hace la ventana “Opciones”?': 'Permite ajustar el brillo, el tamaño del texto y la saturación de la aplicación durante esta sesión.',
    '¿Qué hace la ventana “Historial Vehículos”?': 'Muestra los vehículos registrados y permite revisar las ventas asociadas a cada patente.',
    '¿Qué hace la ventana “Inventario”?': 'Permite consultar productos en bodega o sin stock, registrar productos y editar los datos de un producto.',
    '¿Cómo registro una venta?': 'Abre Nueva venta desde Inicio, selecciona o crea un cliente y añade productos. Registrar venta conserva la venta pendiente en este dispositivo. Desde Ventas abre su detalle y confirma el pago para guardarla en el historial.',
  }; // Define información de las funciones reales del proyecto.

  @override // Construye las preguntas desplegables.
  Widget build(BuildContext context) => PaginaTematica(builder: _pagina);
  Widget _pagina(BuildContext context) => EstructuraPagina(
    titulo: 'Información',
    activo: 'Información', // Identifica la sección.
    child: ListView(
      children: [
        for (final pregunta in _preguntas.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ExpansionTile(
              key: PageStorageKey(pregunta.key),
              backgroundColor: PaletaTaller.de(context)
                  .adaptar(Color(0xFFD9D9D9)),
              collapsedBackgroundColor: PaletaTaller.de(context)
                  .adaptar(Color(0xFFD9D9D9)),
              title: Text(pregunta.key),
              childrenPadding: const EdgeInsets.all(20),
              children: [Text(pregunta.value, textAlign: TextAlign.left)],
            ),
          ),
      ],
    ),
  );
}
