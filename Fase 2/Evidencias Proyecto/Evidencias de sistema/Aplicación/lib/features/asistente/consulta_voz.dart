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
