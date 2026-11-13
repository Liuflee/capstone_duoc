enum ConsultaVoz {
  sinStock('Productos sin stock'),
  stockBajo('Productos con stock bajo'),
  stockPorCodigo('Stock por código'),
  ventas('Ventas');

  const ConsultaVoz(this.titulo);

  final String titulo;
}

enum PeriodoVentasVoz {
  hoy('de hoy'),
  mes('de este mes');

  const PeriodoVentasVoz(this.etiqueta);
  final String etiqueta;

  static PeriodoVentasVoz? desdeFrase(String texto) {
    final frase = texto.toLowerCase();
    if (RegExp(
      r'\b(ayer|anteayer|mañana|semana|trimestre|año|pasad[oa]s?|anterior(?:es)?|pr[oó]xim[oa]s?|mensual(?:es)?\s+de|\d+|enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre)\b',
    ).hasMatch(frase)) {
      return null;
    }
    final dia = RegExp(r'\b(hoy|del d[ií]a|este d[ií]a)\b').hasMatch(frase);
    final mes = RegExp(r'\b(este mes|del mes|mes actual)\b').hasMatch(frase);
    if (dia == mes) return null;
    return dia ? hoy : PeriodoVentasVoz.mes;
  }

  ({String desde, String hasta}) fechas(DateTime ahora) {
    final inicio = DateTime(
      ahora.year,
      ahora.month,
      this == hoy ? ahora.day : 1,
    );
    final fin = DateTime(ahora.year, ahora.month, ahora.day + 1);
    String fecha(DateTime dia) => dia.toIso8601String().split('T').first;
    return (desde: fecha(inicio), hasta: fecha(fin));
  }
}

final _activacion = RegExp(
  r'^\s*[¿¡]?\s*(?:hey|ey|oye)\s*[,.:]?\s+cerna\b[\s,.:;!?¿¡—-]*',
  caseSensitive: false,
);

/// Conserva el resto de la pregunta cuando se dice en la misma frase.
String? quitarActivacion(String texto) {
  final coincidencia = _activacion.firstMatch(texto);
  return coincidencia == null ? null : texto.substring(coincidencia.end).trim();
}

final _marcaCodigo = RegExp(
  r'\b(?:c[oó]digo|producto|repuesto|art[ií]culo)(?:\s*[:=]\s*|\s+)',
  caseSensitive: false,
);
final _stockDe = RegExp(r'\bstock\s+(?:del|de|para)\s+', caseSensitive: false);
final _digitosHablados = {
  'cero': '0',
  'uno': '1',
  'dos': '2',
  'tres': '3',
  'cuatro': '4',
  'cinco': '5',
  'seis': '6',
  'siete': '7',
  'ocho': '8',
  'nueve': '9',
  'guion': '-',
  'guión': '-',
};

/// Extrae un único código y conserva los ceros iniciales.
String? codigoProductoDesdeFrase(String texto) {
  final marcas = _marcaCodigo.allMatches(texto).toList();
  final marca = marcas.isEmpty ? _stockDe.firstMatch(texto) : marcas.last;
  if (marca == null || marcas.length > 2) return null;
  final prefijo = texto.substring(0, marca.start);
  if (marcas.length > 1 &&
      !RegExp(
        r'(?:producto|repuesto|art[ií]culo)(?:\s+con)?\s*$',
        caseSensitive: false,
      ).hasMatch(prefijo)) {
    return null;
  }
  final candidato = texto
      .substring(marca.end)
      .trim()
      .replaceFirst(RegExp(r'''[.\s?!»"”']+$'''), '')
      .replaceFirst(RegExp(r',?\s+por favor$', caseSensitive: false), '')
      .trim();
  final partes = candidato
      .replaceAll(RegExp(r'\s*[-–—]\s*'), '-')
      .split(RegExp(r'\s+'));
  final codigo = StringBuffer();
  for (final (indice, parte) in partes.indexed) {
    final dictado = _digitosHablados[parte.toLowerCase()];
    if (dictado != null) {
      codigo.write(dictado);
    } else if (indice == 0 || RegExp(r'^\d+$|^[A-Z]$').hasMatch(parte)) {
      codigo.write(parte);
    } else {
      return null;
    }
  }
  final valor = codigo.toString();
  if (valor.length > 64 ||
      !RegExp(r'^[A-Za-z0-9]+(?:[-_][A-Za-z0-9]+)*$').hasMatch(valor) ||
      !RegExp(r'\d|^[A-Z][A-Z_-]*$').hasMatch(valor)) {
    return null;
  }
  return valor;
}
