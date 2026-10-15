import 'package:flutter/material.dart';

// Se crea la clase CartaNavegacion, un botón reutilizable
class CartaNavegacion extends StatelessWidget {

  // Variables que definen las características de la tarjeta
  final double ancho; // Ancho de la tarjeta
  final double alto; // Alto de la tarjeta
  final IconData icono; // Icono de la tarjeta
  final String texto; // Texto de la tarjeta
  final String? numero; // Número opcional de la tarjeta
  final Color? color; // Color opcional de la tarjeta
  final VoidCallback? alPresionar; // Acción de la tarjeta

  // Se crea el constructor de la clase
  const CartaNavegacion({
    super.key,
    required this.ancho,
    required this.alto,
    required this.icono,
    required this.texto,
    this.numero,
    this.color,
    this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {

    // Se crea la superficie de la tarjeta
    // Material permite aplicar los efectos de InkWell
    return Material(

      // Si no se recibe un color, utiliza el gris predeterminado
      color: color ?? Colors.grey[300],

      // Se redondean los bordes de la tarjeta
      borderRadius: BorderRadius.circular(10),

      // Se crea el área interactiva de la tarjeta
      child: InkWell(

        // Ejecuta la función recibida al presionar
        onTap: alPresionar,

        // Mantiene el efecto dentro de los bordes redondeados
        borderRadius: BorderRadius.circular(10),

        // Agrega una capa oscura transparente al pasar el mouse
        // Esto permite conservar el color personalizado
        hoverColor: const Color(0x14000000),

        // Efecto visual al presionar la tarjeta
        splashColor: const Color(0x22000000),

        // Se establecen las dimensiones de la tarjeta
        child: SizedBox(
          width: ancho,
          height: alto,

          // Se agrega espacio entre el contenido y los bordes
          child: Padding(
            padding: const EdgeInsets.all(10),

            // Si la tarjeta recibe un número, utiliza Column
            // Si no recibe un número, utiliza Row
            child: numero != null

                // Diseño vertical para tarjetas con número
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      // Icono de la tarjeta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,

                        children: [
                          Icon(
                            icono,
                            size: 30,
                          ),
                        ],
                      ),

                      // Número de la tarjeta
                      Text(
                        numero!,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Descripción de la tarjeta
                      Text(
                        texto,
                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),

                    ],
                  )

                // Diseño horizontal para tarjetas sin número
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      // Icono de la tarjeta
                      Icon(
                        icono,
                        size: 40,
                      ),

                      // Separación entre el icono y el texto
                      const SizedBox(width: 10),

                      // Texto de la tarjeta
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
