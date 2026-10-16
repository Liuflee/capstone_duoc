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
class FiltrosTabla extends StatefulWidget {
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

  @override // Mantiene el estado de apertura entre selecciones.
  State<FiltrosTabla> createState() => _FiltrosTablaState();
} // Finaliza la configuración pública del selector.

// Conserva el menú abierto cuando la página actualiza el filtro seleccionado.
class _FiltrosTablaState extends State<FiltrosTabla> {
  // Controla explícitamente la apertura y el cierre del menú superpuesto.
  final MenuController _controladorMenu = MenuController();

  @override // Implementa la construcción visual del widget.
  Widget build(BuildContext context) {
    // Comprueba que los identificadores no se repitan dentro de esta tabla.
    assert(widget.filtros.map((filtro) => filtro.id).toSet().length == widget.filtros.length);
    // Comprueba que la selección corresponda a una opción disponible.
    assert(widget.filtroSeleccionado == null || widget.filtros.any((filtro) => filtro.id == widget.filtroSeleccionado));
    // Calcula el mismo ancho proporcional que utiliza el buscador.
    final double ancho = widget.anchoTabla * 0.33;
    // Obtiene el nombre del filtro seleccionado para mostrarlo en el botón.
    final seleccion = widget.filtros.where((filtro) => filtro.id == widget.filtroSeleccionado);
    // Limita el botón al tamaño compartido con el buscador.
    return SizedBox(
      width: ancho, // Ocupa el 33 % del ancho recibido.
      height: 48, // Mantiene la misma altura del buscador.
      child: MenuAnchor(
        controller: _controladorMenu, // Conserva el control del menú entre reconstrucciones.
        crossAxisUnconstrained: false, // Ajusta el ancho del desplegable al botón.
        consumeOutsideTap: true, // Cierra al pulsar fuera sin activar la tabla de fondo.
        onOpen: () => setState(() {}), // Actualiza la flecha al desplegar el menú.
        onClose: () => setState(() {}), // Actualiza la flecha al contraer el menú.
        style: MenuStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero), // Elimina márgenes internos que alteraban la alineación del menú.
          visualDensity: VisualDensity.standard, // Evita que la densidad de escritorio reduzca el ancho del menú.
          alignment: Alignment.bottomLeft, // Alinea el menú con el borde izquierdo e inferior del selector.
          fixedSize: WidgetStatePropertyAll(Size.fromWidth(ancho)), // Iguala exactamente el ancho del menú al selector.
          backgroundColor: WidgetStatePropertyAll(Colors.grey[300]), // Conserva el fondo gris.
          minimumSize: WidgetStatePropertyAll(Size(ancho, 0)), // Usa el ancho del selector.
          maximumSize: WidgetStatePropertyAll(Size(ancho, double.infinity)), // Limita el ancho y permite desplazamiento vertical.
        ), // Finaliza el diseño del desplegable.
        menuChildren: [ // Construye el menú sobre la tabla sin desplazarla.
          for (final filtro in widget.filtros) // Genera una opción por filtro recibido.
            MenuItemButton(
              style: const ButtonStyle(
                textStyle: WidgetStatePropertyAll(TextStyle(fontFamily: 'Courier', fontSize: 14, fontWeight: FontWeight.normal)), // Conserva la fuente y el grosor normal del selector.
              ), // Finaliza el estilo de las opciones.
              closeOnActivate: false, // Mantiene abierto el menú al seleccionar una opción.
              onPressed: () => widget.alSeleccionar(filtro.id), // Actualiza el filtro sin cerrar el menú.
              child: RadioGroup<String>(
                groupValue: widget.filtroSeleccionado, // Comparte una única selección entre las opciones.
                onChanged: (_) {}, // El elemento del menú administra la selección completa.
                child: Row(
                  children: [ // Distribuye el indicador circular y su descripción.
                    IgnorePointer(
                      child: ExcludeFocus(
                        child: Radio<String>(value: filtro.id), // Marca solo el identificador seleccionado.
                      ), // Deja la interacción de teclado al elemento del menú.
                    ), // Deja la selección y el cierre al elemento del menú.
                    Expanded(
                      child: Text('FILTRO : ${filtro.texto.toUpperCase()}'), // Muestra el nombre del filtro en mayúsculas y permite varias líneas.
                    ), // Limita el texto al espacio restante.
                  ], // Finaliza los elementos de la opción.
                ), // Finaliza la fila de la opción.
              ), // Finaliza el grupo que refleja la selección de la página.
            ), // Finaliza la opción seleccionable.
        ], // Finaliza las opciones; Flutter permite desplazarlas si no caben en pantalla.
        builder: (context, controlador, child) => InkWell(
          onTap: widget.filtros.isEmpty ? null : () { // Permite alternar la apertura si existen opciones.
            if (controlador.isOpen) { // Comprueba si el menú ya está desplegado.
              controlador.close(); // Contrae el menú al volver a pulsar el selector.
            } else { // Abre el menú cuando está cerrado.
              controlador.open(); // Despliega las opciones sobre la tabla.
            } // Finaliza la alternancia del menú.
          }, // Finaliza la acción del selector.
          child: Container(
          color: Colors.grey[300], // Reproduce el fondo del buscador.
          padding: const EdgeInsets.symmetric(horizontal: 10), // Separa el contenido de los bordes.
          child: Row(
            children: [ // Distribuye el texto y la flecha del desplegable.
              Expanded(
                child: Text(
                  seleccion.isEmpty ? widget.textoAyuda.toUpperCase() : 'FILTRO : ${seleccion.first.texto.toUpperCase()}', // Muestra la indicación o el filtro seleccionado en mayúsculas.
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 14, fontWeight: FontWeight.normal), // Mantiene el mismo grosor normal en el botón y sus opciones.
                  maxLines: 1, // Conserva la altura del botón.
                  overflow: TextOverflow.ellipsis, // Ajusta los nombres largos al ancho disponible.
                ), // Finaliza el texto visible del botón.
              ), // Reserva espacio para la flecha.
              Icon(controlador.isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.black), // Indica si se puede contraer o desplegar.
            ], // Finaliza los elementos del botón.
          ), // Finaliza la fila del botón.
        ), // Finaliza el fondo del botón.
        ), // Finaliza el botón que alterna la apertura del menú.
      ), // Finaliza el menú superpuesto.
    ); // Finaliza el tamaño del selector.
  } // Finaliza la construcción visual.
} // Finaliza el widget reutilizable.
