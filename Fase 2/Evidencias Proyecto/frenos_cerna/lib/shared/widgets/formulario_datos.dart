// Importa los controles y herramientas de distribución de Flutter.
import 'package:flutter/material.dart';

// Describe un campo que la página agrega al constructor del formulario.
class CampoFormularioDatos {
  // Controlador creado y liberado por la página que utiliza el formulario.
  final TextEditingController controlador;
  // Texto que se muestra permanentemente encima del campo.
  final String etiqueta;
  // Texto de ayuda que aparece dentro del campo cuando está vacío.
  final String textoAyuda;
  // Tipo de teclado apropiado para el dato solicitado.
  final TextInputType? tipoTeclado;
  // Validación opcional que se ejecuta desde la clave del formulario.
  final FormFieldValidator<String>? validador;
  // Permite desactivar individualmente la edición de un campo.
  final bool habilitado;
  // Permite ocultar el contenido de campos sensibles.
  final bool esContrasena;
  // Permite reaccionar a los cambios sin administrar el estado desde el formulario.
  final ValueChanged<String>? alCambiar;

  // Configura cada campo de manera independiente.
  const CampoFormularioDatos({
    required this.controlador, // Recibe el controlador administrado por la página.
    required this.etiqueta, // Recibe el título externo del campo.
    this.textoAyuda = '', // Permite omitir el texto interior.
    this.tipoTeclado, // Conserva el teclado predeterminado si no se especifica.
    this.validador, // Conserva la validación en la página si no se especifica.
    this.habilitado = true, // Permite escribir de forma predeterminada.
    this.esContrasena = false, // Muestra el contenido de forma predeterminada.
    this.alCambiar, // Permite omitir la notificación de cambios.
  }); // Finaliza la configuración del campo.
} // Finaliza el modelo de un campo del formulario.

// Formulario reutilizable sin botones, con campos distribuidos por filas y columnas.
class FormularioDatos extends StatelessWidget {
  // Campos ordenados de izquierda a derecha y de arriba hacia abajo.
  final List<CampoFormularioDatos> campos;
  // Cantidad de columnas; por defecto los campos se distribuyen verticalmente.
  final int columnas;
  // Cantidad mínima de filas; aumenta automáticamente si llegan más campos.
  final int? filas;
  // Ancho exterior opcional del formulario.
  final double? ancho;
  // Alto exterior opcional; habilita desplazamiento vertical cuando es necesario.
  final double? alto;
  // Ancho mínimo compartido por los campos, incluso cuando sus textos son cortos.
  final double anchoMinimoCampo;
  // Altura mínima compartida por las áreas de escritura.
  final double altoCampo;
  // Separación horizontal entre los campos.
  final double separacionColumnas;
  // Separación vertical entre las filas.
  final double separacionFilas;
  // Clave opcional para validar o reiniciar todos los campos desde la página.
  final GlobalKey<FormState>? claveFormulario;

  // Configura el tamaño y la distribución sin incorporar acciones de navegación.
  const FormularioDatos({
    super.key, // Conserva la identidad del formulario dentro de Flutter.
    required this.campos, // Recibe cualquier cantidad de campos.
    this.columnas = 1, // Utiliza una sola columna de forma predeterminada.
    this.filas, // Calcula las filas automáticamente cuando no se especifican.
    this.ancho, // Adapta el ancho al contenido y al espacio disponible por defecto.
    this.alto, // Utiliza la altura necesaria para todas las filas por defecto.
    this.anchoMinimoCampo = 280, // Evita que los campos cortos resulten demasiado pequeños.
    this.altoCampo = 56, // Mantiene una altura cómoda para escribir o pulsar.
    this.separacionColumnas = 20, // Separa visualmente las columnas.
    this.separacionFilas = 20, // Separa visualmente las filas.
    this.claveFormulario, // Permite validar desde una CartaNavegacion externa.
  }) : assert(columnas > 0), // Exige al menos una columna.
       assert(filas == null || filas > 0), // Exige filas positivas cuando se especifican.
       assert(ancho == null || (ancho > 0 && ancho < double.infinity)), // Exige un ancho exterior finito.
       assert(alto == null || (alto > 0 && alto < double.infinity)), // Exige un alto exterior finito.
       assert(anchoMinimoCampo > 0 && anchoMinimoCampo < double.infinity), // Exige un ancho mínimo válido.
       assert(altoCampo >= 48 && altoCampo < double.infinity), // Conserva espacio suficiente para editar.
       assert(separacionColumnas >= 0 && separacionColumnas < double.infinity), // Valida la separación horizontal.
       assert(separacionFilas >= 0 && separacionFilas < double.infinity); // Valida la separación vertical.

  @override // Construye el formulario a partir de los campos recibidos.
  Widget build(BuildContext context) {
    // Utiliza la tipografía de la página para medir y mostrar las etiquetas.
    final estiloEtiqueta = DefaultTextStyle.of(context).style.copyWith(fontSize: 18, fontWeight: FontWeight.bold);
    // Utiliza la misma tipografía en todas las áreas de escritura.
    final estiloCampo = Theme.of(context).textTheme.titleMedium!;
    // Respeta el tamaño de texto configurado en el dispositivo.
    final escalaTexto = MediaQuery.textScalerOf(context);
    // Respeta la dirección de escritura del entorno.
    final direccionTexto = Directionality.of(context);
    // Parte del ancho mínimo para igualar todos los campos al más grande.
    double anchoComun = anchoMinimoCampo;
    // Mide los textos de configuración sin cambiar el tamaño mientras se escribe.
    for (final campo in campos) {
      // Compara el título y el texto interior con sus respectivos estilos.
      for (final entrada in [(campo.etiqueta, estiloEtiqueta), (campo.textoAyuda, estiloCampo)]) {
        // Calcula el espacio que necesita cada texto sin saltos automáticos.
        final medida = TextPainter(text: TextSpan(text: entrada.$1, style: entrada.$2), textDirection: direccionTexto, textScaler: escalaTexto);
        medida.layout(); // Obtiene el ancho natural del texto.
        final anchoTexto = medida.width + 32; // Reserva espacio para el relleno interior del campo.
        if (anchoTexto > anchoComun) anchoComun = anchoTexto; // Conserva el ancho del texto más grande.
        medida.dispose(); // Libera los recursos utilizados para medir.
      } // Finaliza la comparación de textos del campo.
    } // Finaliza el cálculo del ancho compartido.
    // Calcula cuántas filas hacen falta para no ocultar ningún campo.
    final filasNecesarias = (campos.length / columnas).ceil();
    // Respeta las filas solicitadas y agrega más cuando llegan campos adicionales.
    final cantidadFilas = filas != null && filas! > filasNecesarias ? filas! : filasNecesarias;
    // Limita el exterior sin forzar a que las columnas se compriman en pantallas pequeñas.
    return SizedBox(
      width: ancho, // Aplica el ancho exterior personalizado si existe.
      height: alto, // Aplica el alto exterior personalizado si existe.
      child: LayoutBuilder(
        builder: (context, restricciones) {
          // Calcula el ancho natural de la cuadrícula completa.
          final anchoNatural = anchoComun * columnas + separacionColumnas * (columnas - 1);
          // Ocupa el ancho explícito cuando es mayor que el mínimo necesario.
          final anchoSolicitado = ancho != null && restricciones.hasBoundedWidth ? restricciones.maxWidth : anchoNatural;
          // Mantiene las columnas legibles si el ancho solicitado es demasiado pequeño.
          final anchoCuadricula = anchoSolicitado > anchoNatural ? anchoSolicitado : anchoNatural;
          // Reparte el ancho de la cuadrícula en campos exactamente iguales.
          final anchoCelda = (anchoCuadricula - separacionColumnas * (columnas - 1)) / columnas;
          // Parte de una altura mínima para las etiquetas de todos los campos.
          double altoEtiqueta = 24;
          // Mide las etiquetas con el ancho definitivo para igualar su altura.
          for (final campo in campos) {
            // Permite que los títulos largos ocupen varias líneas.
            final medida = TextPainter(text: TextSpan(text: campo.etiqueta, style: estiloEtiqueta), textDirection: direccionTexto, textScaler: escalaTexto);
            medida.layout(maxWidth: anchoCelda); // Calcula los saltos de línea necesarios.
            if (medida.height > altoEtiqueta) altoEtiqueta = medida.height; // Conserva la etiqueta más alta.
            medida.dispose(); // Libera los recursos de la medición.
          } // Finaliza el cálculo de la altura compartida.
          // Agrupa todos los campos para permitir validarlos desde la página.
          final contenido = Form(
            key: claveFormulario, // Expone validación y reinicio al botón externo.
            child: Column(
              mainAxisSize: MainAxisSize.min, // Utiliza únicamente la altura de las filas.
              children: [ // Construye las filas configuradas.
                for (int fila = 0; fila < cantidadFilas; fila++) // Recorre las filas de la cuadrícula.
                  Padding(
                    padding: EdgeInsets.only(bottom: fila < cantidadFilas - 1 ? separacionFilas : 0), // Separa las filas sin margen inferior adicional.
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Alinea todas las celdas desde su borde superior.
                      children: [ // Construye las columnas de la fila actual.
                        for (int columna = 0; columna < columnas; columna++) // Recorre las columnas solicitadas.
                          Padding(
                            padding: EdgeInsets.only(right: columna < columnas - 1 ? separacionColumnas : 0), // Separa las columnas sin margen derecho adicional.
                            child: SizedBox(
                              width: anchoCelda, // Asigna el mismo ancho a todas las celdas.
                              child: fila * columnas + columna < campos.length
                                  ? _construirCampo(campos[fila * columnas + columna], altoEtiqueta, estiloEtiqueta, estiloCampo) // Construye el campo que corresponde a la celda.
                                  : SizedBox(height: altoEtiqueta + 10 + altoCampo + 56), // Conserva el espacio de las celdas vacías.
                            ), // Finaliza el tamaño de la celda.
                          ), // Finaliza la separación de la columna.
                      ], // Finaliza las columnas de la fila.
                    ), // Finaliza la fila del formulario.
                  ), // Finaliza la separación entre filas.
              ], // Finaliza las filas del formulario.
            ), // Finaliza la distribución vertical.
          ); // Finaliza el formulario sin botones.
          // Desplaza horizontalmente la cuadrícula cuando no cabe en el exterior.
          final desplazamientoHorizontal = SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Conserva las columnas solicitadas también en Android.
            child: SizedBox(width: anchoCuadricula, child: contenido), // Mantiene el ancho uniforme de la cuadrícula.
          ); // Finaliza el desplazamiento horizontal.
          // Habilita desplazamiento vertical únicamente si se limitó el alto.
          return alto == null ? desplazamientoHorizontal : SingleChildScrollView(child: desplazamientoHorizontal);
        }, // Finaliza la adaptación al espacio disponible.
      ), // Finaliza el cálculo de las dimensiones del formulario.
    ); // Finaliza el tamaño exterior.
  } // Finaliza la construcción del formulario.

  // Construye una celda con etiqueta externa y área de escritura uniforme.
  Widget _construirCampo(CampoFormularioDatos campo, double altoEtiqueta, TextStyle estiloEtiqueta, TextStyle estiloCampo) {
    // Distribuye la etiqueta y su campo verticalmente.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Iguala el ancho de la etiqueta y el campo.
      children: [ // Define los elementos que componen la celda.
        SizedBox(
          height: altoEtiqueta, // Reserva la altura de la etiqueta más grande.
          child: Align(alignment: Alignment.bottomLeft, child: Text(campo.etiqueta, style: estiloEtiqueta)), // Alinea los títulos con el inicio de sus campos.
        ), // Finaliza el espacio compartido para las etiquetas.
        const SizedBox(height: 10), // Separa el título del área de escritura.
        TextFormField(
          controller: campo.controlador, // Utiliza el controlador de la página.
          keyboardType: campo.tipoTeclado, // Muestra el teclado apropiado para el dato.
          validator: campo.validador, // Ejecuta la validación configurada para el campo.
          enabled: campo.habilitado, // Permite desactivar individualmente el campo.
          obscureText: campo.esContrasena, // Oculta el contenido cuando corresponde.
          onChanged: campo.alCambiar, // Notifica cambios si la página lo solicita.
          style: estiloCampo, // Mantiene la misma tipografía en todas las celdas.
          decoration: InputDecoration(
            hintText: campo.textoAyuda, // Muestra el texto interior definido en el constructor.
            filled: true, // Habilita el fondo del área de escritura.
            fillColor: Colors.white, // Utiliza un fondo claro para los campos.
            border: const OutlineInputBorder(), // Dibuja el borde del campo.
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: (altoCampo - 24) / 2), // Aplica la altura común manteniendo el relleno horizontal.
            helperText: ' ', // Reserva espacio para validaciones sin desplazar las filas.
            helperStyle: const TextStyle(height: 1, fontSize: 12), // Establece una altura uniforme para los mensajes.
            error: null, // Deja que TextFormField administre la validación.
          ), // Finaliza el estilo del campo.
          errorBuilder: (context, mensaje) => SizedBox(
            height: 12, // Conserva el mismo espacio reservado por el texto de ayuda.
            child: Text(mensaje, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1, color: Theme.of(context).colorScheme.error)), // Evita que la validación desalineé las celdas.
          ), // Finaliza el mensaje de validación de tamaño uniforme.
        ), // Finaliza el campo editable.
      ], // Finaliza los elementos de la celda.
    ); // Finaliza la distribución del campo.
  } // Finaliza la construcción de una celda.
} // Finaliza el widget reutilizable.
