// Importa Flutter y los widgets compartidos de la aplicación.
import 'package:flutter/material.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
import 'package:frenos_cerna/shared/widgets/buscador_tabla.dart';

// Presenta las preguntas de ayuda con la distribución vertical de Figma.
class PaginaInformacion extends StatefulWidget {
  const PaginaInformacion({super.key}); // Crea la página de ayuda.
  @override // Crea el estado de búsqueda.
  State<PaginaInformacion> createState() => _PaginaInformacionState();
} // Finaliza la página pública.

class _PaginaInformacionState extends State<PaginaInformacion> {
  final _busqueda = TextEditingController(); // Administra el texto de búsqueda.
  static const _preguntas = <String, String>{
    '¿Qué hace la ventana “Clientes”?': 'Permite consultar, registrar y editar clientes. El buscador y los filtros actúan sobre los datos mostrados en la tabla.',
    '¿Qué hace la ventana “Perfil”?': 'Permite ver tu perfil y consultar los perfiles de dueño y mecánico disponibles. Solo el dueño puede crear, editar o retirar perfiles; no puede retirar su propio perfil.',
    '¿Qué hace la ventana “Opciones”?': 'Permite ajustar el brillo, el tamaño del texto y la saturación de la aplicación durante esta sesión.',
    '¿Qué hace la ventana “Historial Vehículos”?': 'Muestra los vehículos registrados y permite revisar las ventas asociadas a cada patente.',
    '¿Qué hace la ventana “Inventario”?': 'Permite consultar productos en bodega o sin stock, registrar productos y editar los datos de un producto.',
    '¿Cómo registro una venta?': 'Abre Nueva venta desde Inicio, selecciona o crea un cliente y añade productos. Registrar venta conserva la venta pendiente en este dispositivo. Desde Ventas abre su detalle y confirma el pago para guardarla en el historial.',
  }; // Define información de las funciones reales del proyecto.
  @override // Libera los recursos de búsqueda.
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override // Construye las preguntas desplegables.
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Información',
    activo: 'Información', // Identifica la sección.
    child: LayoutBuilder(
      builder: (context, espacio) => Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Alinea preguntas y respuestas.
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: BuscadorTabla(
              anchoTabla: espacio.maxWidth,
              controlador: _busqueda,
              textoAyuda: 'BUSCAR PREGUNTA',
              alCambiar: (_) => setState(() {}),
            ),
          ), // Reutiliza el buscador con su proporción habitual.
          const SizedBox(height: 32), // Separa la búsqueda de las preguntas.
          Expanded(
            child: ListView(
              children: [
                for (final pregunta in _preguntas.entries.where(
                  (entrada) => (entrada.key + entrada.value)
                      .toLowerCase()
                      .contains(_busqueda.text.trim().toLowerCase()),
                )) // Busca en preguntas y respuestas.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ExpansionTile(
                      key: PageStorageKey(pregunta.key),
                      backgroundColor: const Color(0xFFD9D9D9),
                      collapsedBackgroundColor: const Color(
                        0xFFD9D9D9,
                      ), // Conserva los bloques grises de Figma.
                      title: Text(pregunta.key),
                      childrenPadding: const EdgeInsets.all(20),
                      children: [
                        Text(pregunta.value),
                      ], // Permite abrir y cerrar cada respuesta.
                    ),
                  ), // Finaliza una pregunta.
              ], // Finaliza las preguntas filtradas.
            ),
          ), // Permite desplazar las preguntas.
        ], // Finaliza los elementos de la página.
      ),
    ), // Finaliza el cálculo del ancho.
  ); // Finaliza el diseño de ayuda.
} // Finaliza el estado de la página.
