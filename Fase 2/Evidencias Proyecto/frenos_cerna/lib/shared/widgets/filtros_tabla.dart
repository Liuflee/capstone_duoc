// Importa los controles y menús visuales de Flutter.
import 'package:flutter/material.dart';

// Representa una opción que la página conecta con su filtrado o consulta.
class OpcionFiltroTabla {
  // Identificador único que recibe la página cuando se selecciona la opción.
  final String id;
  // Nombre visible del filtro en el menú.
  final String texto;

  // Define manualmente cada filtro desde el constructor de la página.
  const OpcionFiltroTabla({
    required this.id, // Identifica la consulta o condición de filtrado.
    required this.texto, // Describe la opción para el usuario.
  }); // Finaliza el constructor de la opción.
} // Finaliza el modelo de una opción.

// Selector reutilizable que la página coloca encima de su tabla, a la izquierda.
class FiltrosTabla extends StatelessWidget {
  // Recibe el mismo ancho de tabla utilizado por BuscadorTabla.
  final double anchoTabla;
  // Opciones configuradas manualmente por la página.
  final List<OpcionFiltroTabla> filtros;
  // Identificador seleccionado; null representa la ausencia de selección.
  final String? filtroSeleccionado;
  // Entrega el identificador para que la página actualice los datos de la tabla.
  final ValueChanged<String> alSeleccionar;
  // Texto del botón cuando todavía no existe una opción seleccionada.
  final String textoAyuda;

  // Configura el selector sin acoplarlo a una tabla de la base de datos.
  const FiltrosTabla({
    super.key, // Conserva la identidad del widget dentro de Flutter.
    required this.anchoTabla, // Ancho disponible compartido con la tabla.
    required this.filtros, // Opciones que aparecerán en el menú.
    required this.filtroSeleccionado, // Selección única controlada por la página.
    required this.alSeleccionar, // Acción que aplica el filtro elegido.
    this.textoAyuda = 'FILTROS', // Texto inicial del botón.
  }) : assert(anchoTabla >= 0 && anchoTabla < double.infinity); // Exige un ancho válido.

  @override // Implementa la construcción visual del widget.
  Widget build(BuildContext context) {
    // Comprueba que los identificadores no se repitan dentro de esta tabla.
    assert(filtros.map((filtro) => filtro.id).toSet().length == filtros.length);
    // Comprueba que la selección corresponda a una opción disponible.
    assert(filtroSeleccionado == null || filtros.any((filtro) => filtro.id == filtroSeleccionado));
    // Calcula el mismo ancho proporcional que utiliza el buscador.
    final double ancho = anchoTabla * 0.33;
    // Obtiene el nombre del filtro seleccionado para mostrarlo en el botón.
    final seleccion = filtros.where((filtro) => filtro.id == filtroSeleccionado);
    // Limita el botón al tamaño compartido con el buscador.
    return SizedBox(
      width: ancho, // Ocupa el 33 % del ancho recibido.
      height: 48, // Mantiene la misma altura del buscador.
      child: PopupMenuButton<String>(
        enabled: filtros.isNotEmpty, // Desactiva la apertura cuando no hay opciones.
        tooltip: textoAyuda, // Describe el control al usar mouse o accesibilidad.
        position: PopupMenuPosition.under, // Abre el menú debajo del botón.
        constraints: BoxConstraints.tightFor(width: ancho), // Iguala el ancho del menú al botón.
        color: Colors.grey[300], // Mantiene el fondo gris del buscador.
        onSelected: alSeleccionar, // Entrega el identificador y cierra el menú.
        itemBuilder: (context) => [ // Construye el menú sobre la página sin desplazar la tabla.
          for (final filtro in filtros) // Genera una opción por cada filtro recibido.
            PopupMenuItem<String>(
              value: filtro.id, // Asocia la opción con su identificador.
              child: RadioGroup<String>(
                groupValue: filtroSeleccionado, // Comparte una única selección entre las opciones.
                onChanged: (_) {}, // El elemento del menú administra la selección completa.
                child: Row(
                  children: [ // Distribuye el indicador circular y su descripción.
                    IgnorePointer(
                      child: ExcludeFocus(
                        child: Radio<String>(value: filtro.id), // Marca solo el identificador seleccionado.
                      ), // Deja la interacción de teclado al elemento del menú.
                    ), // Deja la selección y el cierre al elemento del menú.
                    Expanded(
                      child: Text(filtro.texto), // Permite ajustar el texto a varias líneas.
                    ), // Limita el texto al espacio restante.
                  ], // Finaliza los elementos de la opción.
                ), // Finaliza la fila de la opción.
              ), // Finaliza el grupo que refleja la selección de la página.
            ), // Finaliza la opción seleccionable.
        ], // Finaliza las opciones; Flutter permite desplazarlas si no caben en pantalla.
        child: Container(
          color: Colors.grey[300], // Reproduce el fondo del buscador.
          padding: const EdgeInsets.symmetric(horizontal: 10), // Separa el contenido de los bordes.
          child: Row(
            children: [ // Distribuye el texto y la flecha del desplegable.
              Expanded(
                child: Text(
                  seleccion.isEmpty ? textoAyuda : seleccion.first.texto, // Muestra la selección actual.
                  maxLines: 1, // Conserva la altura del botón.
                  overflow: TextOverflow.ellipsis, // Ajusta los nombres largos al ancho disponible.
                ), // Finaliza el texto visible del botón.
              ), // Reserva espacio para la flecha.
              const Icon(Icons.arrow_drop_down, color: Colors.black), // Indica la apertura hacia abajo.
            ], // Finaliza los elementos del botón.
          ), // Finaliza la fila del botón.
        ), // Finaliza el fondo del botón.
      ), // Finaliza el menú superpuesto.
    ); // Finaliza el tamaño del selector.
  } // Finaliza la construcción visual.
} // Finaliza el widget reutilizable.
