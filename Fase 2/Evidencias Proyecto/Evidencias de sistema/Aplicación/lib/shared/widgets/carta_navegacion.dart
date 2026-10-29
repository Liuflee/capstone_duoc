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
  final Widget? contenido; // Contenido de las acciones que conservan sus dimensiones anteriores.
  final Widget? iconoAccion; // Icono original de una acción compacta.
  final ButtonStyle?
  estilo; // Dimensiones y colores configurados por la página.
  final String tipoBoton; // Tipo anterior utilizado para conservar sus medidas predeterminadas.
  final String? ayuda; // Descripción accesible de las acciones con iconos.
  final bool conservarEstiloOriginal; // Permite que el login conserve sus medidas y estilos anteriores.

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
    this.contenido, // Permite representar acciones existentes sin reconstruir su contenido.
    this.iconoAccion, // Permite conservar el icono de una acción.
    this.estilo, // Permite conservar las medidas de una acción.
    this.tipoBoton =
        'elevated', // Conserva el estilo de referencia predeterminado.
    this.ayuda, // Permite añadir una descripción al pasar el cursor.
    this.conservarEstiloOriginal =
        false, // Mantiene el tamaño medio en las páginas de trabajo.
  });

  // Adapta las acciones existentes a una carta sin cambiar sus callbacks ni medidas.
  const CartaNavegacion.accion({
    super.key, // Conserva la identidad de la acción.
    VoidCallback?
    onPressed, // Recibe la acción original, incluyendo el estado desactivado.
    Widget? child, // Recibe el contenido de una acción de texto o icono.
    Widget? label, // Recibe la etiqueta de una acción con icono.
    Widget? icon, // Recibe el icono de una acción con etiqueta.
    ButtonStyle? style, // Conserva las medidas y colores originales.
    String? tooltip, // Conserva la ayuda de las acciones con iconos.
    this.conservarEstiloOriginal = false, // Evita aplicar los ajustes generales cuando la página conserva su diseño original.
    this.tipoBoton = 'elevated', // Identifica las medidas predeterminadas del botón anterior.
  }) : ancho = 0,
       alto = 0,
       texto = '',
       numero = null,
       color = null,
       icono = null, // Reserva el constructor normal para las cartas de navegación originales.
       contenido = child ?? label,
       iconoAccion = icon,
       estilo = style,
       ayuda = tooltip,
       alPresionar = onPressed; // Conserva la configuración de la acción.

  @override
  Widget build(BuildContext context) {
    // Usa la variante compacta cuando la página proporciona el contenido original.

    // Centraliza las acciones y conserva las medidas nativas de Windows y Android.
    if (contenido != null) {
      final formaCarta = ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ); // Comparte los bordes de las cartas de navegación.
      final base = tipoBoton == 'icon'
          ? IconButton.styleFrom(
              visualDensity: VisualDensity.standard, // Mantiene el área de 48 píxeles también en Windows.
              foregroundColor: Colors.black,
              minimumSize: const Size(48, 48),
            ) // Conserva un área cómoda para las acciones de tabla.
          : ElevatedButton.styleFrom(
              visualDensity: VisualDensity.standard, // Evita que el escritorio reduzca los botones a un tamaño demasiado pequeño.
              backgroundColor: const Color(0xFFBDBDBD),
              foregroundColor: Colors.black,
              minimumSize: const Size(240, 70),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ), // Conserva la misma fuente que el resto de la aplicación.
            ); // Unifica las acciones con el gris y tamaño medio del proyecto.
      final configuracion = conservarEstiloOriginal
          ? (estilo?.merge(formaCarta) ?? formaCarta) // Recupera exactamente los estilos nativos y explícitos que tenía el login.
          : base
                .merge(estilo)
                .merge(formaCarta)
                .merge(
                  tipoBoton == 'icon'
                      ? const ButtonStyle()
                      : const ButtonStyle(
                          fixedSize: WidgetStatePropertyAll(Size(240, 70)),
                          minimumSize: WidgetStatePropertyAll(Size(240, 70)),
                          maximumSize: WidgetStatePropertyAll(Size(240, 70)),
                          foregroundColor: WidgetStatePropertyAll(Colors.black),
                          elevation: WidgetStatePropertyAll(
                            0,
                          ), // Conserva la superficie plana de Añadir cliente.
                          side: WidgetStatePropertyAll(BorderSide.none), // Evita contornos diferentes entre tipos de acción.
                          surfaceTintColor: WidgetStatePropertyAll(
                            Colors.transparent,
                          ), // Evita tintes ajenos a la paleta.
                          shadowColor: WidgetStatePropertyAll(
                            Colors.transparent,
                          ), // Mantiene el mismo diseño de tarjeta.
                          iconSize: WidgetStatePropertyAll(32), // Conserva un icono legible dentro del tamaño acordado.
                        ),
                ); // Iguala las acciones con Añadir cliente sin cambiar los iconos de las tablas ni el login.
      final Widget accion = switch (tipoBoton) {
        'icon' => IconButton(
          onPressed: alPresionar,
          icon: contenido!,
          tooltip: ayuda,
          style: configuracion,
        ), // Conserva las dimensiones de las acciones de tabla.
        'text' =>
          iconoAccion == null
              ? TextButton(
                  onPressed: alPresionar,
                  style: configuracion,
                  child: contenido!,
                ) // Conserva las acciones de texto de los diálogos.
              : TextButton.icon(
                  onPressed: alPresionar,
                  style: configuracion,
                  icon: iconoAccion!,
                  label: contenido!,
                ), // Conserva las acciones de texto con icono.
        'filled' =>
          iconoAccion == null
              ? FilledButton(
                  onPressed: alPresionar,
                  style: configuracion,
                  child: contenido!,
                ) // Conserva las dimensiones del acceso y registro.
              : FilledButton.icon(
                  onPressed: alPresionar,
                  style: configuracion,
                  icon: iconoAccion!,
                  label: contenido!,
                ), // Conserva las acciones principales con icono.
        'outlined' =>
          iconoAccion == null
              ? OutlinedButton(
                  onPressed: alPresionar,
                  style: configuracion,
                  child: contenido!,
                ) // Conserva las dimensiones de las acciones secundarias.
              : OutlinedButton.icon(
                  onPressed: alPresionar,
                  style: configuracion,
                  icon: iconoAccion!,
                  label: contenido!,
                ), // Conserva las acciones secundarias con icono.
        _ =>
          iconoAccion == null
              ? ElevatedButton(
                  onPressed: alPresionar,
                  style: configuracion,
                  child: contenido!,
                ) // Conserva las dimensiones de las acciones elevadas.
              : ElevatedButton.icon(
                  onPressed: alPresionar,
                  style: configuracion,
                  icon: iconoAccion!,
                  label: contenido!,
                ), // Conserva las medidas exactas de icono, texto y espaciado.
      }; // Finaliza la construcción de la acción centralizada.
      final control = ayuda == null || tipoBoton == 'icon'
          ? accion
          : Tooltip(
              message: ayuda!,
              child: accion,
            ); // Conserva la descripción accesible sin duplicarla.
      if (conservarEstiloOriginal) return control; // Conserva el ancho original del formulario sin centrar ni limitar el botón.
      return Align(
        alignment: Alignment.center,
        widthFactor: 1,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: tipoBoton == 'icon' ? 56 : 240),
          child: control,
        ),
      ); // Evita botones que ocupen todo el ancho de los formularios.
    } // Finaliza la variante de acción con dimensiones conservadas.
    // Finaliza la variante para acciones existentes.

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

                          child: Icon(icono, size: 30),
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
                                color: Colors.black,
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
                                color: Colors.black,
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
                        Icon(icono, size: 40),

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
                            color: Colors.black,
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
