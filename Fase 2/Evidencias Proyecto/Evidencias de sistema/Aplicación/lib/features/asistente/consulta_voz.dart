enum TipoConsultaVoz { stockBajo, stockProducto, ventas }

class ConsultaVoz {
  final TipoConsultaVoz tipo;
  final String? codigo;
  final DateTime? inicio;
  final DateTime? fin;
  final String descripcion;

  const ConsultaVoz(
    this.tipo,
    this.descripcion, {
    this.codigo,
    this.inicio,
    this.fin,
  });

  /// La categoría semántica nunca se convierte en SQL. Extrae parámetros del
  /// texto original y exige aclaración si faltan o no son compatibles.
  static ConsultaVoz desdeCategoria(
    String texto,
    String categoria, {
    DateTime? ahora,
  }) {
    if (categoria == 'no_admitida') {
      throw const FormatException(
        'Esta consulta no está disponible. Puedes consultar stock y totales de ventas.',
      );
    }
    if (categoria == 'requiere_aclaracion') {
      throw const FormatException(
        'No pude distinguir qué necesitas. Indica si buscas stock bajo, un producto por código o ventas de un período.',
      );
    }
    final frase = texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    if (RegExp(r'\b(no|excepto|ignora|olvida)\b').hasMatch(frase)) {
      throw const FormatException(
        'Formula una sola consulta afirmativa para evitar confusiones.',
      );
    }
    if (RegExp(r'\b(venta\w*|vend\w*|ingres\w*)\b').hasMatch(frase) &&
        RegExp(r'\b(stock|inventario|repuesto\w*)\b').hasMatch(frase)) {
      throw const FormatException('Consulta inventario y ventas por separado.');
    }
    if (categoria == 'stock_bajo') {
      if (RegExp(
            r'\b(sin stock|agotados|cero|uno|dos|tres|cuatro|seis|siete|ocho|nueve|diez)\b',
          ).hasMatch(frase) ||
          RegExp(r'\d+')
              .allMatches(frase)
              .any((numero) => numero.group(0) != '5')) {
        throw const FormatException(
          'La consulta de stock bajo muestra productos con 5 unidades o menos. Usa esa consulta o indica el código de un producto.',
        );
      }
      return const ConsultaVoz(
        TipoConsultaVoz.stockBajo,
        'Productos con 5 unidades o menos',
      );
    }
    if (categoria == 'stock_producto') {
      final codigos =
          RegExp(
                r'\b(?:c[oó]digo|producto|repuesto|art[ií]culo)\s+([A-Za-z0-9_-]{1,64})\b',
                caseSensitive: false,
              )
              .allMatches(texto)
              .map((coincidencia) => coincidencia.group(1)!)
              .where(
                (codigo) =>
                    RegExp(r'\d').hasMatch(codigo) ||
                    RegExp(r'^[A-Z][A-Z_-]+$').hasMatch(codigo),
              )
              .toSet();
      if (codigos.length != 1) {
        // Conserva el catálogo exacto para códigos que solo tienen minúsculas.
        try {
          final exacta = interpretar(texto);
          if (exacta.tipo == TipoConsultaVoz.stockProducto) return exacta;
        } on FormatException {
          /* Solicita el dato faltante abajo. */
        }
        throw const FormatException(
          'Indica un único código exacto, por ejemplo: “Stock del producto ABC-123”. Puedes corregirlo por escrito.',
        );
      }
      final codigo = codigos.single;
      return ConsultaVoz(
        TipoConsultaVoz.stockProducto,
        'Stock del producto $codigo',
        codigo: codigo,
      );
    }
    if (categoria == 'ventas') {
      final periodos = <String>{};
      if (RegExp(r'\bhoy\b').hasMatch(frase)) periodos.add('hoy');
      if (RegExp(r'\b(ayer|dia anterior)\b').hasMatch(frase)) {
        periodos.add('ayer');
      }
      if (RegExp(r'\b(esta semana|semana actual)\b').hasMatch(frase)) {
        periodos.add('esta semana');
      }
      if (RegExp(r'\b(este mes|mes actual|durante el mes|del mes)\b')
          .hasMatch(frase)) {
        periodos.add('este mes');
      }
      if (RegExp(
            r'\b(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre)\b',
          ).hasMatch(frase) ||
          periodos.length != 1 ||
          RegExp(r'\b(pasad[oa]|anterior|manana|ano|\d+)\b')
              .hasMatch(frase.replaceAll('dia anterior', 'ayer'))) {
        throw const FormatException(
          'Indica un solo período: hoy, ayer, esta semana o este mes.',
        );
      }
      return interpretar('Ventas de ${periodos.single}', ahora: ahora);
    }
    throw const FormatException(
      'La categoría recibida no corresponde a una consulta disponible.',
    );
  }

  /// Catálogo cerrado. Una frase fuera del catálogo nunca ejecuta una consulta.
  static ConsultaVoz interpretar(String texto, {DateTime? ahora}) {
    var frase = texto.trim().toLowerCase();
    const originales = 'áéíóúü';
    const simples = 'aeiouu';
    for (var i = 0; i < originales.length; i++) {
      frase = frase.replaceAll(originales[i], simples[i]);
    }
    frase = frase
        .replaceAll(RegExp(r'[¿?¡!.,]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (RegExp(
      r'^(que productos tienen (poco stock|stock bajo)|productos con (poco stock|stock bajo)|(?:consultar |mostrar |ver )?stock (bajo|critico))$',
    ).hasMatch(frase)) {
      return const ConsultaVoz(
        TipoConsultaVoz.stockBajo,
        'Productos con 5 unidades o menos',
      );
    }
    // El código se conserva tal como se escribió; no se adivinan letras o números.
    final producto = RegExp(
      r'^[¿]?(?:consultar |mostrar |ver )?(?:stock (?:del? |para el )?(?:producto |codigo |código )?|cu[aá]ntas unidades (?:hay|quedan) (?:del? )?(?:producto |codigo |código )?)([a-zA-Z0-9_-]{1,64})[?.]?$',
      caseSensitive: false,
    ).firstMatch(texto.trim());
    if (producto != null) {
      final codigo = producto.group(1)!;
      return ConsultaVoz(
        TipoConsultaVoz.stockProducto,
        'Stock del producto $codigo',
        codigo: codigo,
      );
    }
    final ventas = RegExp(
      r'^(?:consultar |mostrar |ver )?(?:ventas|total de ventas|cuanto (?:se vendio|vendimos)) (?:de |del |en )?(hoy|ayer|esta semana|este mes)$',
    ).firstMatch(frase);
    if (ventas != null) {
      final fecha = ahora ?? DateTime.now();
      final hoy = DateTime(fecha.year, fecha.month, fecha.day);
      final periodo = ventas.group(1)!;
      final inicio = switch (periodo) {
        'ayer' => DateTime(hoy.year, hoy.month, hoy.day - 1),
        'esta semana' => DateTime(
          hoy.year,
          hoy.month,
          hoy.day - hoy.weekday + 1,
        ),
        'este mes' => DateTime(hoy.year, hoy.month),
        _ => hoy,
      };
      final fin = periodo == 'ayer'
          ? hoy
          : DateTime(hoy.year, hoy.month, hoy.day + 1);
      return ConsultaVoz(
        TipoConsultaVoz.ventas,
        'Ventas de $periodo',
        inicio: inicio,
        fin: fin,
      );
    }
    throw const FormatException(
      'Prueba: “Productos con stock bajo”, “Stock del producto ABC-123” o “Ventas de hoy”.',
    );
  }
}
