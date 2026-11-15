import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

void main() {
  for (final ancho in [320.0, 390.0]) {
    testWidgets(
      'Ventas caben sin desplazamiento y permiten pasar filas a $ancho',
      (tester) async {
        tester.view.physicalSize = Size(ancho, 650);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TablaDatos(
                ajustarAlAnchoDisponible: true,
                paginar: true,
                nombresColumnas: const ['CLIENTE', 'VEHÍCULO', 'VER'],
                camposColumnas: const ['cliente', 'vehiculo', ''],
                anchosColumnas: const [220, 180, 88],
                altoFila: 120,
                filas: List.generate(
                  20,
                  (i) => {'cliente': 'Cliente $i', 'vehiculo': 'AA0000'},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final horizontal = tester.widget<SingleChildScrollView>(
          find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          ),
        );
        expect(horizontal.controller!.position.maxScrollExtent, 0);
        expect(find.byType(ListView), findsNothing);
        expect(find.text('Cliente 0'), findsOneWidget);
        await tester.tap(find.byTooltip('Página siguiente'));
        await tester.pumpAndSettle();
        expect(find.text('Cliente 0'), findsNothing);
        await tester.tap(find.byTooltip('Página anterior'));
        await tester.pumpAndSettle();
        expect(find.text('Cliente 0'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
