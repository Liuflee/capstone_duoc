import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/asistente/consulta_voz.dart';

void main() {
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
