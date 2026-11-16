import 'package:frenos_cerna/features/clientes/pagina_ver_cliente.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frenos_cerna/main.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/features/perfil/pagina_perfil.dart';

void main() {
  testWidgets('Más abre Opciones y permite guardar un tema en móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => PaletaTaller.seleccion.value = PaletaTaller.original);
    SharedPreferences.setMockInitialValues({});
    await PaletaTaller.cargar();
    await tester.pumpWidget(const MiAplicacion());
    await tester.pumpAndSettle();
    final entrar = find.text('Entrar en modo de prueba');
    await tester.ensureVisible(entrar);
    await tester.tap(entrar);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Cambiar paleta'), findsNothing);
    expect(find.byTooltip('Abrir menú'), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Ventas del día'), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).last);
    await tester.pumpAndSettle();
    expect(find.text('Vehículos'), findsOneWidget);
    expect(find.text('Historial de ventas'), findsOneWidget);
    await tester.tap(find.text('Opciones'));
    await tester.pumpAndSettle();
    expect(find.text('Tema de color'), findsOneWidget);

    final azul = find.text(PaletaTaller.azul.nombre);
    await tester.ensureVisible(azul);
    await tester.tap(azul);
    await tester.pumpAndSettle();
    expect(PaletaTaller.seleccion.value, PaletaTaller.azul);
    final preferencias = await SharedPreferences.getInstance();
    expect(preferencias.getInt('paleta_taller'), PaletaTaller.azul.index);
    await tester.tap(find.byType(NavigationDestination).first);
    await tester.pumpAndSettle();
    expect(find.text('Página Principal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'El resumen del cliente usa la superficie oscura de cada paleta',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => PaletaTaller.seleccion.value = PaletaTaller.original);
      for (final p in PaletaTaller.values) {
        PaletaTaller.seleccion.value = p;
        await tester.pumpWidget(
          MaterialApp(
            home: PaginaVerCliente(
              key: ValueKey(p),
              cliente: Cliente.fromJson({
                'rut': 123,
                'nombre': 'Cliente de prueba',
                'fono': 987654321,
              }),
              cargarHistorial: (_) async => [],
              cargarVehiculos: (_) async => [],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final resumen = find.byKey(const ValueKey("resumen_cliente"));
        final fondo =
            (tester.widget<Container>(resumen).decoration as BoxDecoration)
                .color;
        expect(fondo, p.oscura ? p.tarjeta : const Color(0xfff7f7f7));
        expect(
          find.descendant(
            of: resumen,
            matching: find.text('Cliente de prueba'),
          ),
          findsOneWidget,
        );
        expect(find.text('RUT: 123'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'El tema guardado pinta la base y el fondo de las páginas al cambiar de paleta',
    (tester) async {
      SharedPreferences.setMockInitialValues({'paleta_taller': 1});
      await PaletaTaller.cargar();
      addTearDown(() => PaletaTaller.seleccion.value = PaletaTaller.original);
      await tester.pumpWidget(const MiAplicacion());
      await tester.pumpAndSettle();
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute(builder: (_) => const PaginaPerfil()));
      await tester.pumpAndSettle();
      for (final p in PaletaTaller.values) {
        await p.activar();
        await tester.pumpAndSettle();
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).color,
          p.fondo,
        );
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
          p.fondo,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
