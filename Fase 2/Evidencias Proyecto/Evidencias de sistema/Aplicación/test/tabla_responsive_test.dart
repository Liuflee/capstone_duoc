import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

void main() {
  for (final ancho in [320.0, 390.0, 800.0, 1440.0]) {
    testWidgets('tabla permite consultar y accionar registros a $ancho', (
      tester,
    ) async {
      tester.view.physicalSize = Size(ancho, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var pulsaciones = 0;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: TablaDatos(
            nombresColumnas: const ['NOMBRE', 'TELÉFONO', 'RUT', 'VER'],
            camposColumnas: const ['nombre', 'telefono', 'rut', ''],
            anchosColumnas: const [300, 150, 150, 100],
            filas: const [
              {'nombre': 'Ana', 'telefono': '123456789', 'rut': '123-4'},
              {'nombre': 'Pedro', 'telefono': '987654321', 'rut': '567-8'},
            ],
            celdasPersonalizadas: {
              3: (_, fila) => IconButton(
                    tooltip: 'Ver ${fila['nombre']}',
                    onPressed: () => pulsaciones++,
                    icon: const Icon(Icons.search),
                  ),
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final buscador = tester.getRect(find.byType(TextField));
      final horizontal = find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      final desplazamiento = tester.widget<SingleChildScrollView>(horizontal);
      if (ancho < 800) {
        expect(desplazamiento.controller!.position.maxScrollExtent,
            greaterThan(0));
        await tester.drag(horizontal, const Offset(-1500, 0));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(TextField)), buscador);
      } else {
        expect(desplazamiento.controller!.position.maxScrollExtent, 0);
      }
      await tester.tap(find.byTooltip('Ver Ana'));
      expect(pulsaciones, 1);
      await tester.enterText(find.byType(TextField), 'Pedro');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ver Ana'), findsNothing);
      expect(find.byTooltip('Ver Pedro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
