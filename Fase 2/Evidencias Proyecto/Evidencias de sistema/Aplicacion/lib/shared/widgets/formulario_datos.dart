import 'package:frenos_cerna/core/tema/paleta_taller.dart';
// Importa los controles y herramientas de distribución de Flutter.
import 'package:material_ui/material_ui.dart';
// Conserva la visibilidad de contraseña y el diseño del acceso existente.
import 'package:frenos_cerna/shared/widgets/campo_formulario.dart';

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
  final bool ajustarAlAnchoDisponible; // Permite adaptar formularios de una columna al espacio de la página.
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
  // Campo individual para integrar controles en formularios que la página ya administra.
  final Widget? campoIndividual;

  // Configura el tamaño y la distribución sin incorporar acciones de navegación.
  const FormularioDatos({
    super.key, // Conserva la identidad del formulario dentro de Flutter.
    required this.campos, // Recibe cualquier cantidad de campos.
    this.columnas = 1, // Utiliza una sola columna de forma predeterminada.
    this.filas, // Calcula las filas automáticamente cuando no se especifican.
    this.ancho, // Adapta el ancho al contenido y al espacio disponible por defecto.
    this.ajustarAlAnchoDisponible = false, // Conserva las dimensiones originales salvo indicación explícita.
    this.alto, // Utiliza la altura necesaria para todas las filas por defecto.
    this.anchoMinimoCampo =
        280, // Evita que los campos cortos resulten demasiado pequeños.
    this.altoCampo = 56, // Mantiene una altura cómoda para escribir o pulsar.
    this.separacionColumnas = 20, // Separa visualmente las columnas.
    this.separacionFilas = 20, // Separa visualmente las filas.
    this.claveFormulario, // Permite validar desde una CartaNavegacion externa.
    this.campoIndividual, // Conserva la configuración de campos individuales existentes.
  }) : assert(columnas > 0), // Exige al menos una columna.
       assert(
         filas == null || filas > 0,
       ), // Exige filas positivas cuando se especifican.
       assert(
         ancho == null || (ancho > 0 && ancho < double.infinity),
       ), // Exige un ancho exterior finito.
       assert(
         alto == null || (alto > 0 && alto < double.infinity),
       ), // Exige un alto exterior finito.
       assert(
         anchoMinimoCampo > 0 && anchoMinimoCampo < double.infinity,
       ), // Exige un ancho mínimo válido.
       assert(
         altoCampo >= 48 && altoCampo < double.infinity,
       ), // Conserva espacio suficiente para editar.
       assert(
         separacionColumnas >= 0 && separacionColumnas < double.infinity,
       ), // Valida la separación horizontal.
       assert(
         separacionFilas >= 0 && separacionFilas < double.infinity,
       ); // Valida la separación vertical.

  // Integra un campo en formularios o diálogos existentes sin anidar otro Form.
  factory FormularioDatos.campo({
    Key? key, // Conserva la identidad del campo.
    TextEditingController? controller, // Conserva el controlador de la página.
    InputDecoration?
    decoration, // Conserva las etiquetas y textos de ayuda del campo.
    TextInputType? keyboardType, // Conserva el teclado apropiado para el dato.
    TextStyle? style, // Conserva el tamaño de texto del campo.
    TextAlign textAlign = TextAlign.start, // Conserva la alineación del texto.
    ValueChanged<String>? onChanged, // Conserva las acciones al escribir.
    FormFieldValidator<String>?
    validator, // Conserva la validación de la página.
    bool autofocus = false, // Conserva el enfoque inicial del campo.
    bool obscureText = false, // Permite ocultar contraseñas.
    bool enabled = true, // Permite desactivar el campo durante el guardado.
    TextInputAction? textInputAction, // Conserva la acción del teclado.
  }) => FormularioDatos(
    key: key,
    campos: const [], // Utiliza la variante de campo individual.
    campoIndividual: TextFormField(
      controller: controller,
      decoration: decoration,
      keyboardType:
          keyboardType, // Conserva el contenido y la presentación del campo.
      style: style,
      textAlign: textAlign,
      onChanged: onChanged,
      validator: validator, // Conserva la edición y la validación.
      autofocus: autofocus,
      obscureText: obscureText,
      enabled: enabled,
      textInputAction: textInputAction, // Conserva el comportamiento del teclado y el estado.
    ), // Finaliza el campo reutilizable integrado en el formulario padre.
  ); // Finaliza la construcción del campo individual.

  // Integra el acceso y registro sin perder validación ni visibilidad de contraseña.
  factory FormularioDatos.acceso({
    required TextEditingController
    controller, // Conserva el controlador de autenticación.
    required String etiqueta, // Conserva la etiqueta del campo de acceso.
    required IconData icono, // Conserva el icono del campo.
    String? hint, // Conserva el texto interior opcional.
    TextInputType? tipoTeclado, // Conserva el teclado del correo electrónico.
    TextInputAction? accion, // Conserva el avance entre campos.
    FormFieldValidator<String>?
    validador, // Conserva las validaciones del acceso.
    bool esContrasena = false, // Permite mostrar u ocultar la contraseña.
  }) => FormularioDatos(
    campos: const [], // Utiliza el formulario padre que administra la autenticación.
    campoIndividual: CampoFormulario(
      controller: controller,
      etiqueta: etiqueta,
      icono: icono,
      hint: hint, // Conserva el contenido del campo.
      tipoTeclado: tipoTeclado,
      accion: accion,
      validador: validador,
      esContrasena: esContrasena, // Conserva validación y visibilidad.
    ), // Finaliza el campo de autenticación integrado.
  ); // Finaliza la variante de acceso del formulario.

  @override // Construye el formulario a partir de los campos recibidos.
  Widget build(BuildContext context) {
    // Conserva el Form de la página cuando se utiliza un campo individual.
    if (campoIndividual != null) return campoIndividual!;
    // Utiliza la tipografía de la página para medir y mostrar las etiquetas.
    final estiloEtiqueta = DefaultTextStyle.of(context).style
        .copyWith(fontSize: 18, fontWeight: FontWeight.bold);
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
      for (final entrada in [
        (campo.etiqueta, estiloEtiqueta),
        (campo.textoAyuda, estiloCampo),
      ]) {
        // Calcula el espacio que necesita cada texto sin saltos automáticos.
        final medida = TextPainter(
          text: TextSpan(text: entrada.$1, style: entrada.$2),
          textDirection: direccionTexto,
          textScaler: escalaTexto,
        );
        medida.layout(); // Obtiene el ancho natural del texto.
        final anchoTexto =
            medida.width +
            32; // Reserva espacio para el relleno interior del campo.
        if (anchoTexto > anchoComun) {
          anchoComun = anchoTexto; // Conserva el ancho del texto más grande.
        } // Finaliza la comparación de anchos.
        medida.dispose(); // Libera los recursos utilizados para medir.
      } // Finaliza la comparación de textos del campo.
    } // Finaliza el cálculo del ancho compartido.
    return SizedBox(
      width: ancho,
      height: alto,
      child: LayoutBuilder(
        builder: (context, espacio) {
          final anchoNatural =
              anchoComun * columnas + separacionColumnas * (columnas - 1);
          final anchoDisponible = espacio.hasBoundedWidth
              ? espacio.maxWidth
              : anchoNatural;
          final anchoFormulario = ajustarAlAnchoDisponible || ancho != null
              ? anchoDisponible
              : anchoNatural.clamp(0.0, anchoDisponible).toDouble();
          final columnasVisibles =
              ((anchoFormulario + separacionColumnas) /
                      (anchoComun + separacionColumnas))
                  .floor()
                  .clamp(1, columnas)
                  .toInt();
          final anchoCampo =
              (anchoFormulario - separacionColumnas * (columnasVisibles - 1)) /
              columnasVisibles;
          double altoEtiqueta = 24;
          for (final campo in campos) {
            final medida = TextPainter(
              text: TextSpan(text: campo.etiqueta, style: estiloEtiqueta),
              textDirection: direccionTexto,
              textScaler: escalaTexto,
            )..layout(maxWidth: anchoCampo);
            if (medida.height > altoEtiqueta) altoEtiqueta = medida.height;
            medida.dispose();
          }

          final camposDisponibles =
              columnasVisibles == columnas && filas != null
              ? (filas! * columnas).clamp(campos.length, 1 << 30).toInt()
              : campos.length;
          final contenido = Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: anchoFormulario,
              child: Form(
                key: claveFormulario,
                child: Wrap(
                  spacing: separacionColumnas,
                  runSpacing: separacionFilas,
                  children: [
                    for (int i = 0; i < camposDisponibles; i++)
                      SizedBox(
                        width: anchoCampo,
                        child: i < campos.length
                            ? _construirCampo(
                                context,
                                campos[i],
                                altoEtiqueta,
                                estiloEtiqueta,
                                estiloCampo,
                              )
                            : SizedBox(height: altoEtiqueta + 10 + altoCampo),
                      ),
                  ],
                ),
              ),
            ),
          );
          return alto == null
              ? contenido
              : SingleChildScrollView(child: contenido);
        },
      ),
    );
  }

  // Construye una celda con etiqueta externa y área de escritura uniforme.
  Widget _construirCampo(
    BuildContext context,
    CampoFormularioDatos campo,
    double altoEtiqueta,
    TextStyle estiloEtiqueta,
    TextStyle estiloCampo,
  ) {
    // Distribuye la etiqueta y su campo verticalmente.
    return Column(
      crossAxisAlignment: CrossAxisAlignment
          .stretch, // Iguala el ancho de la etiqueta y el campo.
      children: [
        // Define los elementos que componen la celda.
        SizedBox(
          height: altoEtiqueta, // Reserva la altura de la etiqueta más grande.
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(campo.etiqueta, style: estiloEtiqueta),
          ), // Alinea los títulos con el inicio de sus campos.
        ), // Finaliza el espacio compartido para las etiquetas.
        const SizedBox(height: 10), // Separa el título del área de escritura.
        TextFormField(
          controller: campo.controlador, // Utiliza el controlador de la página.
          keyboardType:
              campo.tipoTeclado, // Muestra el teclado apropiado para el dato.
          validator: campo
              .validador, // Ejecuta la validación configurada para el campo.
          enabled:
              campo.habilitado, // Permite desactivar individualmente el campo.
          obscureText:
              campo.esContrasena, // Oculta el contenido cuando corresponde.
          onChanged:
              campo.alCambiar, // Notifica cambios si la página lo solicita.
          style:
              estiloCampo, // Mantiene la misma tipografía en todas las celdas.
          decoration: InputDecoration(
            hintText: campo.textoAyuda, // Muestra el texto interior definido en el constructor.
            filled: true, // Habilita el fondo del área de escritura.
            fillColor: PaletaTaller.de(
              context,
            ).adaptar(Colors.white), // Utiliza un fondo claro para los campos.
            border: const OutlineInputBorder(), // Dibuja el borde del campo.
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: (altoCampo - 24) / 2,
            ), // Aplica la altura común manteniendo el relleno horizontal.
            helperText: ' ', // Reserva espacio para validaciones sin desplazar las filas.
            helperStyle: const TextStyle(
              height: 1,
              fontSize: 12,
            ), // Establece una altura uniforme para los mensajes.
            error: null, // Deja que TextFormField administre la validación.
          ), // Finaliza el estilo del campo.
          errorBuilder: (context, mensaje) => SizedBox(
            height: 12, // Conserva el mismo espacio reservado por el texto de ayuda.
            child: Text(
              mensaje,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1,
                color: Theme.of(context).colorScheme.error,
              ),
            ), // Evita que la validación desalineé las celdas.
          ), // Finaliza el mensaje de validación de tamaño uniforme.
        ), // Finaliza el campo editable.
      ], // Finaliza los elementos de la celda.
    ); // Finaliza la distribución del campo.
  } // Finaliza la construcción de una celda.
} // Finaliza el widget reutilizable.
