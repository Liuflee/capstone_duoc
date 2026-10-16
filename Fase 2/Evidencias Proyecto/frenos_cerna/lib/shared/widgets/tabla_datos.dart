import 'package:flutter/material.dart';
// Reutiliza los controles superiores con las dimensiones del ancho visible.
import 'package:frenos_cerna/shared/widgets/buscador_tabla.dart';
// Reutiliza las opciones de selección única para cada tabla.
import 'package:frenos_cerna/shared/widgets/filtros_tabla.dart';

// Define cómo construir una celda especial a partir de los datos de una fila.
// Permite mostrar iconos, botones, imágenes o cualquier otro widget.
typedef ConstructorCeldaTabla = Widget Function(
  BuildContext context,
  Map<String, dynamic> fila,
);

// Tabla reutilizable y ajustable: número de columnas, ancho y color de cada
// cabecera se configuran desde el constructor.
// Los datos, las cabeceras y las acciones se configuran desde el constructor.
class TablaDatos extends StatefulWidget {
  // Adapta las tablas de detalle conservando cada celda y sus acciones originales.
  static Widget desdeCeldas({
    required List<DataColumn>
    columns, // Recibe los encabezados de la tabla anterior.
    required List<DataRow>
    rows, // Recibe las celdas y callbacks de los registros originales.
    WidgetStateProperty<Color?>?
    headingRowColor, // Conserva el color de encabezado configurado.
    TableBorder?
    border, // Acepta el borde de la tabla anterior para conservar su color.
    double? dataRowMaxHeight, // Conserva la altura de las filas del detalle.
  }) {
    // Genera claves independientes para cada columna de datos.
    final claves = List.generate(columns.length, (indice) => 'columna_$indice');
    // Extrae texto visible de celdas simples para buscar y filtrar el detalle.
    String textoCelda(Widget contenido) => contenido is Text
        ? contenido.data ?? contenido.textSpan?.toPlainText() ?? ''
        : '';
    // Calcula el ancho natural que ocupaba cada columna de la tabla anterior.
    double anchoColumna(BuildContext context, int indice) {
      final tema = Theme.of(
        context,
      ); // Recupera la tipografía usada por la tabla original.
      double medir(Widget contenido, TextStyle estilo) {
        if (contenido is! Text) {
          return 48; // Conserva el espacio de las acciones de las celdas.
        } // Finaliza la comprobación del tipo de contenido.
        final medida = TextPainter(
          text: TextSpan(
            text: textoCelda(contenido),
            style: estilo.merge(contenido.style),
          ), // Respeta la fuente específica de cada texto.
          textDirection: Directionality.of(
            context,
          ), // Respeta la dirección de escritura.
          textScaler: MediaQuery.textScalerOf(
            context,
          ), // Respeta la escala del dispositivo.
        ); // Finaliza la configuración de medición.
        medida.layout(); // Obtiene el ancho de la línea más larga.
        final resultado = medida
            .width; // Conserva el ancho calculado antes de liberar recursos.
        medida.dispose(); // Libera los recursos de la medición.
        return resultado; // Entrega el ancho natural del contenido.
      } // Finaliza la medición de una celda.

      double mayor = medir(
        columns[indice].label,
        tema.dataTableTheme.headingTextStyle ?? tema.textTheme.titleSmall!,
      ); // Parte del encabezado original.
      for (final fila in rows) {
        final ancho = medir(
          fila.cells[indice].child,
          tema.dataTableTheme.dataTextStyle ?? tema.textTheme.bodyMedium!,
        ); // Compara el contenido de cada fila.
        if (ancho > mayor) mayor = ancho; // Conserva el contenido más ancho.
      } // Finaliza la comparación de celdas.
      return mayor +
          (indice == 0 ? 24 : 28) +
          (indice == columns.length - 1 ? 24 : 28); // Conserva los márgenes y la separación de columnas originales.
    } // Finaliza el cálculo del ancho anterior.

    // Adapta los registros sin perder los widgets originales.
    final registros = [
      for (final fila in rows) // Recorre las filas del detalle.
        <String, dynamic>{
          for (int indice = 0; indice < fila.cells.length; indice++)
            claves[indice]: textoCelda(
              fila.cells[indice].child,
            ), // Asocia cada texto a su filtro.
          '_celdas':
              fila.cells, // Conserva botones, iconos y acciones de cada celda.
        }, // Finaliza el registro adaptado.
    ]; // Finaliza los datos de la tabla reutilizable.
    // Limita la altura cuando la tabla se encuentra dentro de una página desplazable.
    return LayoutBuilder(
      builder: (context, restricciones) => SizedBox(
        width: restricciones.hasBoundedWidth
            ? null
            : List.generate(
                columns.length,
                (indice) => anchoColumna(context, indice),
              ).reduce((anterior, siguiente) => anterior + siguiente), // Conserva el ancho natural de las tablas con desplazamiento horizontal.
        height: restricciones.hasBoundedHeight
            ? restricciones.maxHeight
            : (124 + rows.length * (dataRowMaxHeight ?? 70))
                  .clamp(260.0, 520.0)
                  .toDouble(), // Conserva el ancho del padre y permite desplazar las filas.
        child: TablaDatos(
          nombresColumnas: [
            for (int indice = 0; indice < columns.length; indice++)
              textoCelda(columns[indice].label).isEmpty
                  ? 'COLUMNA ${indice + 1}'
                  : textoCelda(columns[indice].label),
          ], // Reutiliza los encabezados visibles.
          camposColumnas: [
            for (int indice = 0; indice < columns.length; indice++)
              RegExp(r'^(VER|REVISAR|EXPANDIR|BORRAR|CAMBIAR|REMOVER|AÑADIR)$')
                      .hasMatch(textoCelda(columns[indice].label).toUpperCase())
                  ? ''
                  : claves[indice],
          ], // Excluye las acciones de los filtros de datos.
          anchosColumnas: List.generate(
            columns.length,
            (indice) => anchoColumna(context, indice),
          ), // Conserva las proporciones naturales dentro del ancho original.
          filas: registros, // Presenta los registros adaptados.
          altoFila:
              dataRowMaxHeight ??
              70, // Conserva el alto configurado en el detalle.
          colorEncabezado:
              headingRowColor?.resolve({}) ??
              const Color(
                0xFFEF6767,
              ), // Conserva el color de la tabla anterior.
          colorBorde:
              border?.top.color ??
              Colors.black, // Conserva el color del borde original.
          celdasPersonalizadas: {
            for (
              int indice = 0;
              indice < columns.length;
              indice++
            ) // Recupera el contenido original de cada columna.
              indice: (context, registro) {
                final celda =
                    (registro['_celdas']
                        as List<
                          DataCell
                        >)[indice]; // Conserva la celda del registro filtrado.
                return celda.onTap == null
                    ? celda.child
                    : InkWell(
                        onTap: celda.onTap,
                        child: celda.child,
                      ); // Conserva las acciones originales de la celda.
              }, // Finaliza la recuperación de una celda.
          }, // Finaliza las celdas personalizadas.
        ), // Finaliza la tabla compartida.
      ), // Finaliza la altura delimitada.
    ); // Finaliza la adaptación al contenedor original.
  } // Finaliza la adaptación de tablas de detalle.

  // Permite que la página conserve controles externos si ya los administra.
  final bool mostrarControles;
  // Opciones configurables; cada identificador corresponde a un campo de datos.
  final List<OpcionFiltroTabla>? filtros;

  // Títulos visibles en el encabezado, en el orden de las columnas.
  final List<String> nombresColumnas;

  // Campos del registro que se mostrarán en cada columna.
  // Por ejemplo: ['nombre', 'fono', 'rut', '', ''].
  // Un campo vacío es válido cuando la celda se construye manualmente.
  final List<String> camposColumnas;

  // Anchos deseados de las columnas. Se interpretan como proporciones.
  // Por ejemplo: [300, 150, 150, 100, 100].
  final List<double> anchosColumnas;

  // Registros recibidos desde la página que consulta la base de datos.
  final List<Map<String, dynamic>> filas;

  // Permite reemplazar una celda por un widget personalizado.
  // Las claves del mapa son los índices de las columnas, comenzando en cero.
  final Map<int, ConstructorCeldaTabla> celdasPersonalizadas;

  // Color individual de cada cabecera. Si es null, o si una posición
  // es null, se usa colorEncabezado. Debe tener un elemento por columna.
  final List<Color?>? coloresEncabezados;

  // Color del texto de cada cabecera (mismo criterio que coloresEncabezados).
  final List<Color?>? coloresTextoEncabezados;

  // Propiedades visuales opcionales.
  final double altoEncabezado;
  final double altoFila;
  final Color colorEncabezado;
  final Color colorBorde;
  final String mensajeSinDatos;

  // Se crea el constructor de la tabla.
  const TablaDatos({
    super.key,
    required this.nombresColumnas,
    required this.camposColumnas,
    required this.anchosColumnas,
    required this.filas,
    this.mostrarControles =
        true, // Integra buscador y filtros encima de la cabecera.
    this.filtros, // Genera opciones desde las columnas cuando no se personalizan.
    this.celdasPersonalizadas = const {},
    this.coloresEncabezados,
    this.coloresTextoEncabezados,
    this.altoEncabezado = 56,
    this.altoFila = 70,
    this.colorEncabezado = const Color(0xFFEF6767),
    this.colorBorde = Colors.black,
    this.mensajeSinDatos = 'No hay registros para mostrar',
  }) : assert(nombresColumnas.length >= 1),
       assert(camposColumnas.length == nombresColumnas.length),
       assert(anchosColumnas.length == nombresColumnas.length),
       assert(
         coloresEncabezados == null ||
             coloresEncabezados.length == nombresColumnas.length,
       ),
       assert(
         coloresTextoEncabezados == null ||
             coloresTextoEncabezados.length == nombresColumnas.length,
       );

  @override
  State<TablaDatos> createState() => _TablaDatosState();
}

class _TablaDatosState extends State<TablaDatos> {
  // Conserva el texto de búsqueda de esta tabla independientemente de otras tablas.
  final TextEditingController _buscador = TextEditingController();
  // Una selección nula busca en todos los campos visibles.
  String? _filtro;

  // Controla el desplazamiento vertical de las filas.
  final ScrollController _controladorScroll = ScrollController();

  @override
  void dispose() {
    _buscador.dispose(); // Libera el controlador de búsqueda de la tabla.
    // Libera el controlador cuando se elimina la tabla de la pantalla.
    _controladorScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        // La tabla necesita una altura limitada por su contenedor padre.
        // En las páginas se recomienda colocarla dentro de Expanded.
        if (!restricciones.hasBoundedHeight || !restricciones.hasBoundedWidth) {
          return const Center(
            child: Text('La tabla necesita un ancho y alto definidos.'),
          );
        }

        // Verifica que todos los anchos indicados sean válidos.
        if (widget.anchosColumnas.any((ancho) => ancho <= 0)) {
          return const Center(
            child: Text('Los anchos de las columnas deben ser positivos.'),
          );
        }

        // Se reserva un espacio a la derecha para la barra de scroll.
        // Así el desplazamiento no tapa el contenido de la última columna.
        const double espacioScroll = 14;
        final double anchoTabla = (restricciones.maxWidth - espacioScroll)
            .clamp(0.0, double.infinity)
            .toDouble();

        // Suma los anchos solicitados para convertirlos en proporciones.
        final double totalAnchos = widget.anchosColumnas.reduce(
          (anterior, siguiente) => anterior + siguiente,
        );

        // Ajusta TODAS las columnas para ocupar el ancho disponible.
        // No se necesita desplazar la tabla horizontalmente.
        final List<double> anchosCalculados = [];
        double anchoAsignado = 0;

        for (int indice = 0; indice < widget.anchosColumnas.length; indice++) {
          final bool ultimaColumna = indice == widget.anchosColumnas.length - 1;

          final double anchoColumna = ultimaColumna
              ? anchoTabla - anchoAsignado
              : anchoTabla * widget.anchosColumnas[indice] / totalAnchos;

          anchosCalculados.add(anchoColumna);
          anchoAsignado += anchoColumna;
        }

        // Genera una sola opción por campo, excluyendo las columnas de acciones.
        final opciones =
            widget.filtros ??
            [
              for (final campo
                  in widget.camposColumnas
                      .where((campo) => campo.isNotEmpty)
                      .toSet()) // Recorre los campos visibles sin duplicados.
                OpcionFiltroTabla(
                  id: campo,
                  texto: widget
                      .nombresColumnas[widget.camposColumnas.indexOf(campo)],
                ), // Asocia cada opción a su dato real.
            ]; // Finaliza las opciones propias de la tabla.
        final seleccion = opciones.any((opcion) => opcion.id == _filtro)
            ? _filtro
            : null; // Descarta selecciones que ya no pertenecen a las columnas actuales.
        final consulta = _buscador.text
            .trim()
            .toLowerCase(); // Normaliza el texto de búsqueda.
        final camposBusqueda = seleccion == null
            ? widget.camposColumnas.where((campo) => campo.isNotEmpty)
            : [seleccion]; // Selecciona el campo o todos los campos visibles.
        final filasVisibles = !widget.mostrarControles || consulta.isEmpty
            ? widget.filas
            : widget.filas
                  .where(
                    (fila) => camposBusqueda.any(
                      (campo) => (fila[campo]?.toString() ?? '')
                          .toLowerCase()
                          .contains(consulta),
                    ),
                  )
                  .toList(); // Filtra los datos mostrados sin modificar los originales.

        // El encabezado queda fuera del ListView para permanecer fijo.
        return Column(
          children: [
            if (widget.mostrarControles) // Mantiene los controles fuera del espacio de la cabecera y las filas.
              Padding(
                padding: const EdgeInsets.only(
                  right: espacioScroll,
                  bottom: 20,
                ), // Alinea ambos extremos con el ancho visible de la tabla.
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Coloca los filtros a la izquierda y la búsqueda a la derecha.
                  children: [
                    FiltrosTabla(
                      anchoTabla: anchoTabla, // Comparte el ancho visible con el buscador.
                      filtroSeleccionado:
                          seleccion ??
                          '__todos__', // Mantiene una selección única.
                      filtros: [
                        const OpcionFiltroTabla(
                          id: '__todos__',
                          texto: 'TODOS LOS CAMPOS',
                        ),
                        ...opciones,
                      ], // Incluye la búsqueda general y los filtros de la página.
                      alSeleccionar: (id) => setState(
                        () => _filtro = id == '__todos__' ? null : id,
                      ), // Actualiza el campo de búsqueda sin cerrar el menú.
                    ), // Finaliza el selector reutilizable.
                    BuscadorTabla(
                      anchoTabla: anchoTabla,
                      controlador: _buscador,
                      alCambiar: (_) => setState(() {}),
                    ), // Actualiza las filas mientras se escribe.
                  ], // Finaliza los controles superiores.
                ), // Finaliza la distribución horizontal.
              ), // Finaliza la zona independiente de controles.
            // Encabezado de las columnas.
            Padding(
              padding: const EdgeInsets.only(right: espacioScroll),
              child: _construirEncabezado(anchosCalculados),
            ),

            // Las filas utilizan solamente la altura restante.
            Expanded(
              child: filasVisibles.isEmpty
                  ? Center(child: Text(widget.mensajeSinDatos))
                  : Scrollbar(
                      controller: _controladorScroll,
                      thumbVisibility: true,
                      interactive: true,
                      child: ListView.builder(
                        controller: _controladorScroll,
                        itemCount: filasVisibles.length, // Cuenta únicamente los registros que cumplen la búsqueda.
                        itemBuilder: (context, indiceFila) {
                          // Genera solamente las filas que se necesitan mostrar.
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: espacioScroll,
                            ),
                            child: _construirFila(
                              context,
                              filasVisibles[indiceFila], // Conserva las acciones del registro original filtrado.
                              indiceFila,
                              anchosCalculados,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // Construye la fila fija que contiene los nombres de las columnas.
  Widget _construirEncabezado(List<double> anchos) {
    return Row(
      children: List.generate(widget.nombresColumnas.length, (indice) {
        return Container(
          width: anchos[indice],
          height: widget.altoEncabezado,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            // Color propio de la columna o, si no hay, el color general.
            color: widget.coloresEncabezados?[indice] ?? widget.colorEncabezado,
            border: _bordeCelda(indice, esEncabezado: true),
          ),

          // ScaleDown muestra el nombre COMPLETO, reduciendo su fuente
          // solo si no alcanza el espacio horizontal de la columna.
          // Nunca se utiliza ellipsis en los encabezados.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.nombresColumnas[indice],
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: widget.coloresTextoEncabezados?[indice] ?? Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }

  // Construye cada fila con valores de datos o celdas personalizadas.
  Widget _construirFila(
    BuildContext context,
    Map<String, dynamic> fila,
    int indiceFila,
    List<double> anchos,
  ) {
    // Alterna el color gris para diferenciar visualmente las filas.
    final Color? colorFila = indiceFila.isEven
        ? Colors.grey[200]
        : Colors.grey[300];

    return Row(
      children: List.generate(widget.nombresColumnas.length, (indice) {
        // Revisa si esta columna tiene un constructor especial.
        final ConstructorCeldaTabla? construirCelda =
            widget.celdasPersonalizadas[indice];

        // Obtiene el valor de la base de datos mediante el nombre del campo.
        final String campo = widget.camposColumnas[indice];
        final String valor = campo.isEmpty
            ? ''
            : (fila[campo]?.toString() ?? '');

        return Container(
          width: anchos[indice],
          height: widget.altoFila,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: colorFila,
            border: _bordeCelda(indice),
          ),

          // La celda personalizada tiene prioridad sobre el valor normal.
          // Puede contener IconButton, Text, un avatar u otro widget.
          child: construirCelda != null
              ? construirCelda(context, fila)
              : Text(
                  valor,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
        );
      }),
    );
  }

  // Mantiene las líneas negras entre columnas y filas.
  Border _bordeCelda(int indice, {bool esEncabezado = false}) {
    final BorderSide linea = BorderSide(color: widget.colorBorde, width: 1);

    return Border(
      left: linea,
      right: indice == widget.nombresColumnas.length - 1
          ? linea
          : BorderSide.none,
      top: esEncabezado ? linea : BorderSide.none,
      bottom: linea,
    );
  }
}
