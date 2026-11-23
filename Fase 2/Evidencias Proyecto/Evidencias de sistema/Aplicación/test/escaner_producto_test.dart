import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/inventario/pagina_crear_producto.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/carrito_venta.dart';

void main() {
  testWidgets('Un código escaneado precarga barras sin activar edición', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaginaCrearProducto(
          codigoBarraInicial: '0012345678905',
          cargarCatalogos: () async => {
            'categorias': [],
            'calidades': [],
            'relaciones': [],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final campos = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(campos.first.controller!.text, '');
    expect(campos[1].controller!.text, '');
    expect(campos.last.controller!.text, '0012345678905');
    expect(campos.first.enabled, isTrue);
    campos.first.controller!.text = 'SP0-01223';
    campos[1].controller!.text = '   ';
    campos[2].controller!.text = '14000';
    final registrar = find.text('REGISTRAR');
    await tester.ensureVisible(registrar);
    await tester.tap(registrar);
    await tester.pumpAndSettle();
    expect(find.text('Ingresa el SKU del producto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('La cantidad escaneada precarga el carrito de la venta', (
    tester,
  ) async {
    final producto = ProductoVenta(
      id: 'SP0-01223',
      nombre: 'SP0-01223',
      categoria: 'Pastillas',
      precio: 1000,
      stock: 5,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PaginaCrearVenta(
          productoEscaneado: producto,
          cantidadEscaneada: 3,
          cargarProductos: () async => [producto],
          cargarClientes: () async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final filas = tester.widget<CarritoVenta>(find.byType(CarritoVenta)).lineas;
    expect(filas.single.cantidad, 3);
    expect(find.text(r'Total $3.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
