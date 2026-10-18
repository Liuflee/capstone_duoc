import 'package:flutter/material.dart'; // Construye los widgets tal como los usa la aplicación.
import 'package:flutter_test/flutter_test.dart'; // Protege las correcciones visuales solicitadas.
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart'; // Comprueba el botón que tenía texto blanco.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart'; // Comprueba el área completa de la marca.
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart'; // Comprueba el borde continuo del menú.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart'; // Compara acciones e iconos de tabla.

void main() {
  // Verifica los criterios de estilo compartidos.
  testWidgets(
    'la marca comparte el gris de la barra y el menú conserva un borde definido',
    (tester) async {
      // Reproduce el área que el usuario señaló en azul.
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1; // Define una ventana de escritorio.
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio); // Restablece el entorno.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: 100,
                  child: BarraSuperior(tituloPagina: 'Página Principal'),
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 172.8,
                        child: MenuLateral(activo: 'Página Principal'),
                      ),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ); // Conserva las proporciones comunes del marco.
      final marca = find.byKey(
        const ValueKey('identidad_empresa'),
      ); // Localiza el bloque blanco completo.
      final limitesMarca = tester.getRect(
        marca,
      ); // Obtiene el área blanca antes de la línea inferior de la barra.
      expect(
        limitesMarca.topLeft,
        Offset.zero,
      ); // Extiende el blanco hasta el extremo superior izquierdo.
      expect(
        limitesMarca.width,
        closeTo(172.8, 0.01),
      ); // Cubre todo el ancho de la zona del menú.
      expect(
        limitesMarca.height,
        closeTo(100, 1.01),
      ); // Cubre el alto completo salvo la línea divisoria inferior.
      expect(
        tester.widget<Container>(marca).color,
        const Color(0xFFE0E0E0),
      ); // Conserva el mismo fondo gris que la barra superior.
      final decoracion =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(MenuLateral),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration; // Obtiene la superficie compartida.
      expect(
        decoracion.color,
        const Color(0xFFD6D6D6),
      ); // Conserva el fondo gris original del menú.
      expect(
        (decoracion.border as Border).right.width,
        1,
      ); // Mantiene un borde fino de un píxel.
      expect(
        (decoracion.border as Border).right.color,
        Colors.black,
      ); // Distingue el menú mediante el borde negro solicitado.
      expect(
        tester.getRect(find.byKey(const ValueKey('cerrar_aplicacion'))).bottom,
        lessThanOrEqualTo(1000),
      ); // Mantiene visible todo el cierre.
      expect(
        tester.takeException(),
        isNull,
      ); // Comprueba que no haya desbordamientos.
    },
  ); // Finaliza el marco visual.

  testWidgets(
    'las acciones igualan Añadir cliente y los iconos de tabla mantienen su tamaño',
    (tester) async {
      // Verifica que la normalización no afecte a las celdas.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CartaNavegacion(
                  key: const ValueKey('referencia'),
                  ancho: 240,
                  alto: 70,
                  texto: 'AÑADIR CLIENTE',
                  icono: Icons.person_add_alt_1,
                  alPresionar: () {},
                ),
                CartaNavegacion.accion(
                  key: const ValueKey('accion'),
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('AÑADIR PRODUCTO'),
                ),
                CartaNavegacion.accion(
                  key: const ValueKey('tabla'),
                  tipoBoton: 'icon',
                  onPressed: () {},
                  child: const Icon(Icons.search, size: 30),
                ),
              ],
            ),
          ),
        ),
      ); // Compara las tres variantes bajo las mismas restricciones.
      expect(
        tester.getSize(find.byKey(const ValueKey('accion'))),
        tester.getSize(find.byKey(const ValueKey('referencia'))),
      ); // Iguala ancho y alto de las acciones.
      expect(
        tester.getSize(find.byKey(const ValueKey('tabla'))),
        const Size(48, 48),
      ); // Conserva las dimensiones anteriores de los iconos.
      final boton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      ); // Obtiene el estilo efectivo de la acción.
      expect(
        boton.style!.foregroundColor!.resolve({}),
        Colors.black,
      ); // Mantiene el texto negro.
      expect(
        boton.style!.side!.resolve({}),
        BorderSide.none,
      ); // Conserva la misma superficie plana de la referencia.
      expect(
        tester.takeException(),
        isNull,
      ); // Exige ausencia de errores de distribución.
    },
  ); // Finaliza la comparación de acciones.

  testWidgets(
    'Añadir producto usa texto negro y el tamaño de Añadir cliente',
    (tester) async {
      // Protege la discrepancia señalada por el usuario.
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio =
          1; // Mantiene visibles las acciones del inventario.
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio); // Restablece la ventana.
      await tester.pumpWidget(const MaterialApp(home: PaginaInventario()));
      await tester.pumpAndSettle(); // Abre el inventario real sin escrituras.
      final texto = find.text(
        'AÑADIR PRODUCTO',
      ); // Obtiene la etiqueta corregida.
      expect(
        tester.widget<Text>(texto).style!.color,
        Colors.black,
      ); // Conserva el texto negro de la referencia.
      expect(
        tester.getSize(
          find.ancestor(of: texto, matching: find.byType(ElevatedButton)),
        ),
        const Size(240, 70),
      ); // Conserva la referencia de tamaño solicitada.
      expect(
        tester.takeException(),
        isNull,
      ); // Exige ausencia de errores visuales.
    },
  ); // Finaliza la revisión del inventario.
} // Finaliza las pruebas de estilo.
