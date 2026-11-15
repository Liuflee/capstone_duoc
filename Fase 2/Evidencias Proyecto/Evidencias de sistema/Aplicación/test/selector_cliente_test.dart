import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:frenos_cerna/features/clientes/presentation/selector_cliente.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

void main() {
  testWidgets(
    'Seleccionar cliente confirma, permite cancelar y respeta las paletas',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => PaletaTaller.seleccion.value = PaletaTaller.original);
      final cliente = Cliente.fromJson({
        'rut': 123,
        'nombre': 'Cliente prueba',
        'fono': 123456789,
      });
      for (final paleta in PaletaTaller.values) {
        PaletaTaller.seleccion.value = paleta;
        Cliente? elegido;
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('ABRIR'),
                  onPressed: () async {
                    elegido = await seleccionarClienteExistente(
                      context,
                      cargarClientes: () async => [cliente],
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('ABRIR'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
          paleta.fondo,
        );
        expect(
          tester.widget<TablaDatos>(find.byType(TablaDatos)).nombresColumnas,
          ['NOMBRE', 'RUT'],
        );
        await tester.tap(find.text('Cliente prueba'));
        await tester.pumpAndSettle();
        expect(find.text('¿Seleccionar este cliente?'), findsOneWidget);
        await tester.tap(find.text('CANCELAR'));
        await tester.pumpAndSettle();
        expect(find.byType(TablaDatos), findsOneWidget);
        expect(elegido, isNull);
        await tester.tap(find.text('123'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ACEPTAR'));
        await tester.pumpAndSettle();
        expect(elegido, same(cliente));
        expect(find.byType(Dialog), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
