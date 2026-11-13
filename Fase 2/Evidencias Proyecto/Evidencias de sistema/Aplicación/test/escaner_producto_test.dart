import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/inventario/pagina_crear_producto.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

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
    expect(campos.last.controller!.text, '0012345678905');
    expect(campos.first.enabled, isTrue);
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
    final filas = tester.widget<TablaDatos>(find.byType(TablaDatos).last).filas;
    expect(filas.length, 3);
    expect(tester.takeException(), isNull);
  });
}
