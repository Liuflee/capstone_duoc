import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/dashboard/data/dashboard_repository.dart';
import 'package:frenos_cerna/features/dashboard/pagina_dashboard.dart';
import 'package:frenos_cerna/features/inicio/pagina_inicio.dart';
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart';

VentaRegistro venta(String id, DateTime? fecha, double total) => VentaRegistro(
  id: id,
  clienteNombre: 'Cliente $id',
  vehiculoNombre: 'ABCD12 · Toyota Yaris',
  productosResumen: 'Pastillas de freno',
  total: total,
  fecha: fecha?.toIso8601String() ?? 'No registrada',
  fechaRegistro: fecha,
  items: [],
);

final ahora = DateTime(2026, 10, 26, 14);
final ejemplo = DatosDashboard(
  ventas: [
    venta('1', DateTime(2026, 10, 26, 10), 125000),
    venta('2', DateTime(2026, 10, 24, 12), 85000),
    venta('3', DateTime(2026, 10, 20, 9), 45000),
    venta('4', DateTime(2026, 10, 1), 30000),
    venta('5', null, 999999),
    venta('6', DateTime(2026, 10, 27), 500000),
  ],
  productos: [
    Producto(
      id: 'P01',
      nombre: 'Pastillas SP0-01223',
      codigoBarra: '',
      categoria: 'PASTILLAS',
      precio: 25000,
      cantidad: 3,
    ),
    Producto(
      id: 'D02',
      nombre: 'Disco delantero',
      codigoBarra: '',
      categoria: 'DISCOS',
      precio: 35000,
      cantidad: 0,
    ),
    Producto(
      id: 'L03',
      nombre: 'Líquido de frenos',
      codigoBarra: '',
      categoria: 'LÍQUIDOS',
      precio: 5000,
      cantidad: 12,
    ),
  ],
  pendientes: [
    VentaPendiente(
      id: 'local-1',
      rutCliente: '12345678',
      nombreCliente: 'Cliente pendiente',
      fonoCliente: '912345678',
      patente: 'ABCD12',
      articulos: const [
        ArticuloVentaPendiente(
          codigo: 'P01',
          nombre: 'Pastillas',
          categoria: 'PASTILLAS',
          precio: 25000,
          cantidad: 2,
          stock: 3,
        ),
      ],
    ),
  ],
);

void main() {
  test(
    'el período respeta los límites, excluye fechas desconocidas y futuras',
    () {
      expect(
        ejemplo.ventasDelPeriodo(PeriodoDashboard.hoy, ahora).map((v) => v.id),
        ['1'],
      );
      expect(
        ejemplo
            .ventasDelPeriodo(PeriodoDashboard.semana, ahora)
            .map((v) => v.id),
        ['1', '2', '3'],
      );
      expect(
        ejemplo.ventasDelPeriodo(PeriodoDashboard.mes, ahora).map((v) => v.id),
        ['1', '2', '3', '4'],
      );
      expect(
        PeriodoDashboard.semana.inicio(DateTime(2026, 1, 2)),
        DateTime(2025, 12, 27),
      );
      expect(ejemplo.stockCritico.map((p) => p.id), ['D02', 'P01']);
    },
  );

  for (final ancho in [390.0, 1440.0]) {
    testWidgets('dashboard adapta contenido y filtros a $ancho', (
      tester,
    ) async {
      tester.view.physicalSize = Size(ancho, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const salida = String.fromEnvironment('DASHBOARD_CAPTURAS');
      if (salida.isNotEmpty) {
        await tester.runAsync(() async {
          for (final fuente in {
            'Courier': 'C:/Windows/Fonts/cour.ttf',
            'MaterialIcons': 'C:/Users/Sumir/fluttersdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          }.entries) {
            final cargador = FontLoader(fuente.key)
              ..addFont(
                File(fuente.value).readAsBytes().then(ByteData.sublistView),
              );
            await cargador.load();
          }
        });
      }
      final limite = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Courier'),
          home: RepaintBoundary(
            key: limite,
            child: PaginaDashboard(
              cargarDatos: () async => ejemplo,
              ahora: () => ahora,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('\$255.000'), findsOneWidget);
      expect(find.text('\$50.000'), findsOneWidget);
      expect(find.text('NUEVA VENTA'), findsNothing);
      expect(tester.takeException(), isNull);

      if (salida.isNotEmpty) {
        await tester.runAsync(() async {
          final area =
              limite.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final imagen = await area.toImage();
          final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
          await File('$salida/dashboard_${ancho.toInt()}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          imagen.dispose();
        });
      }

      await tester.tap(find.text('Hoy'));
      await tester.pumpAndSettle();
      expect(find.text('\$125.000'), findsWidgets);
      expect(find.text('\$255.000'), findsNothing);
      await tester.tap(find.text('Este mes'));
      await tester.pumpAndSettle();
      expect(find.text('\$285.000'), findsOneWidget);
      final grafico = find.byKey(const ValueKey('grafico_ingresos'));
      await tester.ensureVisible(grafico);
      await tester.pumpAndSettle();
      final areaGrafico = tester.getRect(grafico);
      for (var dia = 1; dia <= ahora.day; dia++) {
        final barra = find.byKey(
          ValueKey('ingresos_${DateTime(2026, 10, dia).toIso8601String()}'),
        );
        final areaBarra = tester.getRect(barra);
        expect(areaBarra.left, greaterThanOrEqualTo(areaGrafico.left));
        expect(areaBarra.right, lessThanOrEqualTo(areaGrafico.right));
        expect(areaBarra.width, greaterThan(0));
      }
      expect(
        tester
            .getSize(
              find.byKey(
                ValueKey(
                  'ingresos_${DateTime(2026, 10, 26).toIso8601String()}',
                ),
              ),
            )
            .height,
        130,
      );
      expect(
        find.descendant(of: grafico, matching: find.text('01/10')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: grafico, matching: find.text('26/10')),
        findsOneWidget,
      );
      if (salida.isNotEmpty) {
        await tester.runAsync(() async {
          final area =
              limite.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final imagen = await area.toImage();
          final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
          await File('$salida/dashboard_mensual_${ancho.toInt()}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          imagen.dispose();
        });
      }
      await tester.ensureVisible(find.text('Cliente 4'));
      expect(find.text('Cliente 1'), findsOneWidget);
      expect(find.text('Cliente 4'), findsOneWidget);
      expect(find.text('Cliente 5'), findsNothing);
      expect(find.text('Cliente 6'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('una fuente fallida no oculta las demás y permite reintentar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var consultas = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PaginaDashboard(
          ahora: () => ahora,
          cargarDatos: () async {
            consultas++;
            return consultas == 1
                ? DatosDashboard(productos: ejemplo.productos, pendientes: [])
                : ejemplo;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo cargar: ventas.'), findsOneWidget);
    expect(find.text('SIN STOCK'), findsOneWidget);
    expect(find.text('Ingresos no disponibles.'), findsOneWidget);
    await tester.tap(find.byTooltip('Actualizar dashboard'));
    await tester.pumpAndSettle();
    expect(consultas, 2);
    expect(find.text('\$255.000'), findsOneWidget);
    expect(find.textContaining('No se pudo cargar:'), findsNothing);
  });

  testWidgets('Inicio abre la nueva pantalla del dashboard', (tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: const PaginaInicio(modoPrueba: true),
        routes: {
          '/dashboard': (_) => PaginaDashboard(
            cargarDatos: () async => ejemplo,
            ahora: () => ahora,
          ),
        },
      ),
    );
    await tester.ensureVisible(find.text('DASHBOARD'));
    await tester.tap(find.text('DASHBOARD'));
    await tester.pumpAndSettle();
    expect(find.byType(PaginaDashboard), findsOneWidget);
    expect(find.text('RESUMEN DEL NEGOCIO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
