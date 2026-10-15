import 'package:flutter/material.dart';

// Se crea la clase CartaNavegacion, un botón reutilizable
class CartaNavegacion extends StatelessWidget {

  // Variables que definen las características de la tarjeta
  final double ancho; // Ancho de la tarjeta
  final double alto; // Alto de la tarjeta
  final IconData? icono; // Icono opcional de la tarjeta
  final String texto; // Texto de la tarjeta
  final String? numero; // Número opcional de la tarjeta
  final Color? color; // Color opcional de la tarjeta
  final VoidCallback? alPresionar; // Acción de la tarjeta

  // Se crea el constructor de la clase
  const CartaNavegacion({
    super.key,
    required this.ancho,
    required this.alto,
    required this.texto,
    this.icono,
    this.numero,
    this.color,
    this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {

    // Se crea la superficie de la tarjeta
    // Material permite aplicar los efectos visuales de InkWell
    return Material(

      // Si no recibe un color, utiliza el gris predeterminado
      color: color ?? Colors.grey[300],

      // Redondea los bordes de la tarjeta
      borderRadius: BorderRadius.circular(10),

      // Se crea el área interactiva de la tarjeta
      child: InkWell(

        // Ejecuta la función recibida al presionar
        onTap: alPresionar,

        // Mantiene los efectos dentro de los bordes redondeados
        borderRadius: BorderRadius.circular(10),

        // Agrega una capa transparente al pasar el mouse
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

            // Se determina la distribución del contenido
            // Si existe un número, utiliza el diseño vertical
            // Si no existe un número, utiliza el diseño horizontal
            child: numero != null

                // DISEÑO VERTICAL PARA TARJETAS IMPORTANTES
                ? Stack(
                    fit: StackFit.expand,

                    children: [

                      // Si existe un icono, se muestra
                      // en la esquina superior izquierda
                      if (icono != null)
                        Positioned(
                          top: 0,
                          left: 0,

                          child: Icon(
                            icono,
                            size: 30,
                          ),
                        ),

                      // Se centra el número y el texto
                      // independientemente de la posición del icono
                      Center(
                        child: Column(

                          // La columna ocupa solamente
                          // el espacio necesario para su contenido
                          mainAxisSize: MainAxisSize.min,

                          children: [

                            // Número de la tarjeta
                            Text(
                              numero!,

                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Separación entre número y texto
                            const SizedBox(height: 4),

                            // Descripción de la tarjeta
                            Text(
                              texto,
                              textAlign: TextAlign.center,

                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),

                          ],
                        ),
                      ),

                    ],
                  )

                // DISEÑO HORIZONTAL PARA TARJETAS DE TRABAJO
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      // Si existe un icono, se muestra
                      // junto a su separación del texto
                      if (icono != null) ...[

                        // Icono de la tarjeta
                        Icon(
                          icono,
                          size: 40,
                        ),

                        // Separación entre icono y texto
                        const SizedBox(width: 10),

                      ],

                      // Texto descriptivo de la tarjeta
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
