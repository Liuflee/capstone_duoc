import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/shared/widgets/panel_filtros.dart';
import 'package:material_ui/material_ui.dart';

typedef ConstructorCeldaTabla = Widget Function(
  BuildContext context,
  Map<String, dynamic> fila,
);

class TablaDatos extends StatefulWidget {
  static Widget desdeCeldas({
    required List<DataColumn> columns,
    required List<DataRow> rows,
    WidgetStateProperty<Color?>? headingRowColor,
    TableBorder? border,
    double? dataRowMaxHeight,
  }) {
    String texto(Widget widget) => widget is Text
        ? widget.data ?? widget.textSpan?.toPlainText() ?? ''
        : '';
    final indices = Iterable<int>.generate(columns.length);
    final titulos = columns.map((columna) => texto(columna.label)).toList();
    final encabezadosAccion = RegExp(
      r'^(VER|REVISAR|EXPANDIR|BORRAR|CAMBIAR|REMOVER|AÑADIR)$',
      caseSensitive: false,
    );
    final campos = [
      for (final i in indices)
        encabezadosAccion.hasMatch(titulos[i]) ? '' : 'columna_$i',
    ];

    return LayoutBuilder(
      builder: (context, espacio) => SizedBox(
        width: espacio.hasBoundedWidth
            ? null
            : MediaQuery.sizeOf(context).width,
        height: espacio.hasBoundedHeight
            ? espacio.maxHeight
            : (170 + rows.length * (dataRowMaxHeight ?? 70))
                  .clamp(280.0, 560.0)
                  .toDouble(),
        child: TablaDatos(
          nombresColumnas: [
            for (final i in indices)
              titulos[i].isEmpty ? 'Columna ${i + 1}' : titulos[i],
          ],
          camposColumnas: campos,
          anchosColumnas: [for (final campo in campos) campo.isEmpty ? 1 : 3],
          filas: [
            for (final fila in rows)
              {
                for (final i in indices)
                  if (campos[i].isNotEmpty)
                    campos[i]: texto(fila.cells[i].child),
                '_celdas': fila.cells,
              },
          ],
          altoFila: dataRowMaxHeight ?? 70,
          colorEncabezado:
              headingRowColor?.resolve({}) ?? const Color(0xFFEF6767),
          colorBorde: border?.top.color ?? Colors.black,
          celdasPersonalizadas: {
            for (final i in indices)
              i: (context, registro) {
                final celda = (registro['_celdas'] as List<DataCell>)[i];
                if (celda.onTap == null) return celda.child;
                return InkWell(onTap: celda.onTap, child: celda.child);
              },
          },
        ),
      ),
    );
  }

  final bool mostrarControles;
  final List<String> nombresColumnas;
  final List<String> camposColumnas;
  final List<double> anchosColumnas;
  final List<Map<String, dynamic>> filas;
  final Map<int, ConstructorCeldaTabla> celdasPersonalizadas;
  final List<Color?>? coloresEncabezados;
  final List<Color?>? coloresTextoEncabezados;
  final double altoEncabezado;
  final double altoFila;
  final Color colorEncabezado;
  final Color colorBorde;
  final String mensajeSinDatos;

  const TablaDatos({
    super.key,
    required this.nombresColumnas,
    required this.camposColumnas,
    required this.anchosColumnas,
    required this.filas,
    this.mostrarControles = true,
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
  final _buscador = TextEditingController();
  final _scroll = ScrollController();

  Iterable<int> get _columnas =>
      Iterable<int>.generate(widget.nombresColumnas.length);

  bool _esAccion(int columna) => widget.camposColumnas[columna].isEmpty;

  @override
  void dispose() {
    _buscador.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filasVisibles(String consulta) {
    if (consulta.isEmpty) return widget.filas;
    final campos = widget.camposColumnas.where((campo) => campo.isNotEmpty);
    return widget.filas.where((fila) {
      return campos.any(
        (campo) =>
            normalizarFiltro(fila[campo]?.toString() ?? '').contains(consulta),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final consulta = widget.mostrarControles
        ? normalizarFiltro(_buscador.text.trim())
        : '';
    final filas = _filasVisibles(consulta);
    return LayoutBuilder(
      builder: (context, espacio) {
        if (!espacio.hasBoundedWidth || !espacio.hasBoundedHeight) {
          return const Center(
            child: Text('La tabla necesita un ancho y alto definidos.'),
          );
        }
        if (widget.anchosColumnas.any((ancho) => ancho <= 0)) {
          return const Center(
            child: Text('Los anchos de las columnas deben ser positivos.'),
          );
        }

        final escala = MediaQuery.textScalerOf(context).scale(14) / 14;
        final minimos = [
          for (final i in _columnas) (_esAccion(i) ? 76.0 : 128.0) * escala,
        ];
        final anchoMinimo = minimos.reduce((a, b) => a + b);
        final anchoTabla = (espacio.maxWidth - margenDesplazamientoTabla)
            .clamp(0.0, double.infinity)
            .toDouble();
        final esMovil = MediaQuery.sizeOf(context).width < 600;
        final usarTarjetas = esMovil || anchoTabla < anchoMinimo;
        final pesos = widget.anchosColumnas;
        final pesoTotal = pesos.reduce((a, b) => a + b);
        final anchos = [
          for (final i in _columnas)
            minimos[i] + (anchoTabla - anchoMinimo) * pesos[i] / pesoTotal,
        ];

        return Column(
          children: [
            if (widget.mostrarControles)
              Padding(
                padding: const EdgeInsets.only(
                  right: margenDesplazamientoTabla,
                  bottom: 12,
                ),
                child: CampoBusqueda(
                  controlador: _buscador,
                  textoAyuda: 'Buscar en la tabla',
                  alCambiar: (_) => setState(() {}),
                ),
              ),
            if (!usarTarjetas) _encabezado(context, anchos),
            Expanded(
              child: filas.isEmpty
                  ? Center(
                      child: Text(
                        consulta.isEmpty
                            ? widget.mensajeSinDatos
                            : 'No se encontraron coincidencias.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Scrollbar(
                      controller: _scroll,
                      child: ListView.builder(
                        controller: _scroll,
                        padding: EdgeInsets.only(
                          right: margenDesplazamientoTabla,
                          bottom: esMovil ? 66 : 16,
                        ),
                        itemCount: filas.length,
                        itemBuilder: (context, i) => usarTarjetas
                            ? _tarjeta(context, filas[i])
                            : _fila(context, filas[i], i, anchos),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _celda(BuildContext context, Map<String, dynamic> fila, int columna) {
    final personalizada = widget.celdasPersonalizadas[columna];
    if (personalizada != null) return personalizada(context, fila);
    final valor = fila[widget.camposColumnas[columna]]?.toString() ?? '';
    return Text(valor.isEmpty ? '—' : valor);
  }

  Widget _tarjeta(BuildContext context, Map<String, dynamic> fila) {
    final paleta = PaletaTaller.de(context);
    final tema = Theme.of(context);
    final datos = _columnas.where((i) => !_esAccion(i)).toList();
    final acciones = _columnas.where((i) => _esAccion(i)).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Color.alphaBlend(
        paleta.acento.withValues(alpha: .035),
        paleta.oscura ? paleta.tarjeta : paleta.fondo,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: paleta.borde.withValues(alpha: paleta.oscura ? .75 : .14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: LayoutBuilder(
          builder: (context, espacio) {
            final escala = MediaQuery.textScalerOf(context).scale(14) / 14;
            final anchoCampo = espacio.maxWidth >= 268 * escala
                ? (espacio.maxWidth - 12) / 2
                : espacio.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (datos.isNotEmpty)
                  DefaultTextStyle.merge(
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    child: _celda(context, fila, datos.first),
                  ),
                if (datos.length > 1) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final i in datos.skip(1))
                        SizedBox(
                          width: anchoCampo,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.nombresColumnas[i],
                                style: tema.textTheme.labelSmall?.copyWith(
                                  color: paleta.texto.withValues(alpha: .72),
                                ),
                              ),
                              _celda(context, fila, i),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                if (acciones.isNotEmpty) ...[
                  if (datos.isNotEmpty)
                    Divider(
                      color: paleta.borde.withValues(alpha: .25),
                      height: 16,
                    ),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (final i in acciones)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _celda(context, fila, i),
                            Text(
                              widget.nombresColumnas[i],
                              style: tema.textTheme.labelSmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _encabezado(BuildContext context, List<double> anchos) {
    final paleta = PaletaTaller.de(context);
    return Padding(
      padding: const EdgeInsets.only(right: margenDesplazamientoTabla),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final i in _columnas)
                Container(
                  width: anchos[i],
                  constraints: BoxConstraints(minHeight: widget.altoEncabezado),
                  color: paleta.oscura
                      ? paleta.tabla
                      : widget.coloresEncabezados?[i] ?? widget.colorEncabezado,
                  alignment: i == 0 ? Alignment.centerLeft : Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.nombresColumnas[i],
                      textAlign: i == 0 ? TextAlign.start : TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: paleta.oscura
                            ? paleta.texto
                            : widget.coloresTextoEncabezados?[i] ??
                                  paleta.texto,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fila(
    BuildContext context,
    Map<String, dynamic> fila,
    int indice,
    List<double> anchos,
  ) {
    final paleta = PaletaTaller.de(context);
    final linea = paleta.oscura ? paleta.borde : widget.colorBorde;
    return Container(
      constraints: BoxConstraints(minHeight: widget.altoFila),
      decoration: BoxDecoration(
        color: indice.isEven
            ? paleta.fondo
            : Color.alphaBlend(
                paleta.acento.withValues(alpha: .055),
                paleta.fondo,
              ),
        border: Border(bottom: BorderSide(color: linea.withValues(alpha: .22))),
      ),
      child: Row(
        children: [
          for (final i in _columnas)
            Container(
              width: anchos[i],
              alignment: i == 0 ? Alignment.centerLeft : Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: DefaultTextStyle.merge(
                textAlign: i == 0 ? TextAlign.start : TextAlign.center,
                child: _celda(context, fila, i),
              ),
            ),
        ],
      ),
    );
  }
}
