// Importa los widgets visuales de Flutter.
import 'package:flutter/material.dart';

// Buscador reutilizable que la página coloca encima de su tabla, a la derecha.
class BuscadorTabla extends StatelessWidget {
  // Recibe el ancho completo del contenedor que también contiene la tabla.
  final double anchoTabla;
  // Utiliza el controlador administrado y liberado por la página.
  final TextEditingController controlador;
  // Notifica el texto para que la página filtre los datos de su tabla.
  final ValueChanged<String> alCambiar;
  // Permite personalizar la indicación según la tabla utilizada.
  final String textoAyuda;

  // Configura los datos del buscador desde la página que lo utiliza.
  const BuscadorTabla({
    super.key, // Conserva la identidad del widget dentro de Flutter.
    required this.anchoTabla, // Ancho disponible compartido con la tabla.
    required this.controlador, // Controlador del texto de búsqueda.
    required this.alCambiar, // Acción ejecutada al escribir.
    this.textoAyuda = 'BUSCAR', // Texto predeterminado del buscador.
  }) : assert(
         anchoTabla >= 0 && anchoTabla < double.infinity,
       ); // Exige un ancho válido.

  @override // Implementa la construcción visual del widget.
  Widget build(BuildContext context) {
    // Ocupa el 33 % del ancho recibido, sin agregar espacio alrededor.
    return SizedBox(
      width: anchoTabla * 0.33, // Mantiene la proporción solicitada.
      height: 48, // Comparte la altura con el selector de filtros.
      child: Container(
        color: Colors.grey[300], // Reproduce el fondo del buscador de Clientes.
        padding: const EdgeInsets.only(
          left: 10,
        ), // Separa el texto del borde izquierdo.
        child: Row(
          children: [
            // Distribuye el campo y la lupa horizontalmente.
            Expanded(
              child: TextField(
                controller:
                    controlador, // Muestra el texto administrado por la página.
                onChanged: alCambiar, // Permite filtrar mientras se escribe.
                decoration: InputDecoration(
                  hintText: textoAyuda, // Describe qué datos se pueden buscar.
                  border: InputBorder.none, // Conserva el diseño sin borde.
                ), // Finaliza la decoración del campo.
              ), // Finaliza el campo editable.
            ), // Asigna al texto el espacio restante.
            const IconButton(
              onPressed:
                  null, // La búsqueda se realiza automáticamente al escribir.
              icon: Icon(
                Icons.search,
                color: Colors.black,
              ), // Conserva la lupa negra.
            ), // Finaliza el icono del buscador.
          ], // Finaliza los elementos horizontales.
        ), // Finaliza la fila del buscador.
      ), // Finaliza el fondo del buscador.
    ); // Finaliza el tamaño del buscador.
  } // Finaliza la construcción visual.
} // Finaliza el widget reutilizable.
