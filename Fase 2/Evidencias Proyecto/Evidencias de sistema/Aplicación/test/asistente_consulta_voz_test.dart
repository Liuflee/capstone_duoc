import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/asistente/consulta_voz.dart';

void main() {
  test('extrae la consulta tras cualquiera de las dos activaciones', () {
    expect(
      quitarActivacion('Hey Cerna, dime productos sin stock.'),
      'dime productos sin stock.',
    );
    expect(
      quitarActivacion('¡Oye, Cerna! ¿Qué productos tienen stock bajo?'),
      'Qué productos tienen stock bajo?',
    );
    expect(quitarActivacion('Oye Cerna.'), '');
  });

  test('requiere la activación al comienzo y el nombre completo', () {
    expect(quitarActivacion('Dime productos sin stock'), isNull);
    expect(quitarActivacion('Oye Cernadas, dime productos'), isNull);
    expect(quitarActivacion('Le dije oye Cerna'), isNull);
  });

  test('extrae códigos escritos y dictados sin perder ceros', () {
    expect(
      codigoProductoDesdeFrase('Stock del código SP0-01223.'),
      'SP0-01223',
    );
    expect(codigoProductoDesdeFrase('Stock del ABC-123'), 'ABC-123');
    expect(
      codigoProductoDesdeFrase(
        'Stock del producto con código ABC guion uno dos tres',
      ),
      'ABC-123',
    );
    expect(
      codigoProductoDesdeFrase('Stock del código cero cero uno dos tres'),
      '00123',
    );
    expect(
      codigoProductoDesdeFrase('Stock del código SP0 - 01223'),
      'SP0-01223',
    );
    expect(codigoProductoDesdeFrase('Stock del código A_B-12'), 'A_B-12');
  });

  test('rechaza un código ausente y las consultas con dos códigos', () {
    expect(codigoProductoDesdeFrase('Stock del código'), isNull);
    expect(
      codigoProductoDesdeFrase('Stock del código ABC-123 y código DEF-456'),
      isNull,
    );
    expect(codigoProductoDesdeFrase('Stock del código 00123 y 00456'), isNull);
  });

  test('distingue hoy y este mes de los períodos no disponibles', () {
    expect(PeriodoVentasVoz.desdeFrase('Ventas del día'), PeriodoVentasVoz.hoy);
    expect(
      PeriodoVentasVoz.desdeFrase('Total de ventas de este mes'),
      PeriodoVentasVoz.mes,
    );
    expect(PeriodoVentasVoz.desdeFrase('Ventas del mes'), PeriodoVentasVoz.mes);
    expect(PeriodoVentasVoz.desdeFrase('Cuánto vendimos ayer'), isNull);
    expect(PeriodoVentasVoz.desdeFrase('Ventas del mes pasado'), isNull);
    expect(PeriodoVentasVoz.desdeFrase('Ventas del mes de octubre'), isNull);
    expect(PeriodoVentasVoz.desdeFrase('Ventas de hoy y de este mes'), isNull);
  });

  test('genera fechas de calendario con fin exclusivo al cambiar de año', () {
    final ahora = DateTime(2026, 12, 31, 23);
    expect(PeriodoVentasVoz.hoy.fechas(ahora), (
      desde: '2026-12-31',
      hasta: '2027-01-01',
    ));
    expect(PeriodoVentasVoz.mes.fechas(ahora), (
      desde: '2026-12-01',
      hasta: '2027-01-01',
    ));
  });
}
