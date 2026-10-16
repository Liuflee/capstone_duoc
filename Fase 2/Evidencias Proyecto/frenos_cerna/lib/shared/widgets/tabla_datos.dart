import 'package:flutter/material.dart';

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
    this.celdasPersonalizadas = const {},
    this.coloresEncabezados,
    this.coloresTextoEncabezados,
    this.altoEncabezado = 56,
    this.altoFila = 70,
    this.colorEncabezado = const Color(0xFFEF6767),
    this.colorBorde = Colors.black,
    this.mensajeSinDatos = 'No hay registros para mostrar',
  })  : assert(nombresColumnas.length >= 1),
        assert(camposColumnas.length == nombresColumnas.length),
        assert(anchosColumnas.length == nombresColumnas.length),
        assert(coloresEncabezados == null ||
            coloresEncabezados.length == nombresColumnas.length),
        assert(coloresTextoEncabezados == null ||
            coloresTextoEncabezados.length == nombresColumnas.length);

  @override
  State<TablaDatos> createState() => _TablaDatosState();
}

class _TablaDatosState extends State<TablaDatos> {

  // Controla el desplazamiento vertical de las filas.
  final ScrollController _controladorScroll = ScrollController();

  @override
  void dispose() {
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
        if (!restricciones.hasBoundedHeight ||
            !restricciones.hasBoundedWidth) {
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

        // El encabezado queda fuera del ListView para permanecer fijo.
        return Column(
          children: [

            // Encabezado de las columnas.
            Padding(
              padding: const EdgeInsets.only(right: espacioScroll),
              child: _construirEncabezado(anchosCalculados),
            ),

            // Las filas utilizan solamente la altura restante.
            Expanded(
              child: widget.filas.isEmpty
                  ? Center(child: Text(widget.mensajeSinDatos))
                  : Scrollbar(
                      controller: _controladorScroll,
                      thumbVisibility: true,
                      interactive: true,
                      child: ListView.builder(
                        controller: _controladorScroll,
                        itemCount: widget.filas.length,
                        itemBuilder: (context, indiceFila) {

                          // Genera solamente las filas que se necesitan mostrar.
                          return Padding(
                            padding: const EdgeInsets.only(right: espacioScroll),
                            child: _construirFila(
                              context,
                              widget.filas[indiceFila],
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
                color: widget.coloresTextoEncabezados?[indice] ?? Colors.white,
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
    final Color? colorFila =
        indiceFila.isEven ? Colors.grey[200] : Colors.grey[300];

    return Row(
      children: List.generate(widget.nombresColumnas.length, (indice) {

        // Revisa si esta columna tiene un constructor especial.
        final ConstructorCeldaTabla? construirCelda =
            widget.celdasPersonalizadas[indice];

        // Obtiene el valor de la base de datos mediante el nombre del campo.
        final String campo = widget.camposColumnas[indice];
        final String valor =
            campo.isEmpty ? '' : (fila[campo]?.toString() ?? '');

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

    final BorderSide linea = BorderSide(
      color: widget.colorBorde,
      width: 1,
    );

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