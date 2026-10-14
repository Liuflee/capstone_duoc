
import 'package:flutter/material.dart';

// Se crea la clase CartaNavegacion, un botón reutilizable
class CartaNavegacion extends StatelessWidget {

  // Variables que definen las características del botón
  final double ancho; // Ancho del botón
  final double alto; // Alto del botón
  final IconData icono; // Icono del botón
  final String texto; // Texto del botón
  final String? numero; // Número opcional del botón
  final VoidCallback? alPresionar; // Acción del botón

  // Se crea el constructor de la clase
  const CartaNavegacion({
    super.key,
    required this.ancho,
    required this.alto,
    required this.icono,
    required this.texto,
    this.numero,
    this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {

    // Se crea el material que permite mostrar efectos visuales
    return Material(
      color: Colors.grey[300], // Color de fondo
      borderRadius: BorderRadius.circular(10), // Bordes redondeados

      // Se crea el área interactiva del botón
      child: InkWell(
        onTap: alPresionar, // Función al presionar el botón
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.grey[400], // Color al pasar el mouse

        // Se definen las dimensiones del botón
        child: SizedBox(
          width: ancho,
          height: alto,

          // Espaciado interior del botón
          child: Padding(
            padding: const EdgeInsets.all(10),

            // Se determina la distribución del contenido
            // Si existe un número, se utiliza Column
            // Si no existe un número, se utiliza Row
            child: numero != null

                // Diseño vertical para botones con número
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      // Icono del botón
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            icono,
                            size: 30,
                          ),
                        ],
                      ),

                      // Número del botón
                      Text(
                        numero!,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Texto descriptivo del botón
                      Text(
                        texto,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),

                    ],
                  )

                // Diseño horizontal para botones sin número
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      // Icono del botón
                      Icon(
                        icono,
                        size: 40,
                      ),

                      // Separación entre icono y texto
                      const SizedBox(width: 10),

                      // Texto descriptivo del botón
                      Flexible(
                        child: Text(
                          texto,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
