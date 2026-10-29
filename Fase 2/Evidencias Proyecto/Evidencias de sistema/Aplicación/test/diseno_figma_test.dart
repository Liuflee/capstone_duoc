// Carga las fuentes reales para revisar las capturas locales.

import 'package:frenos_cerna/features/inicio/pagina_inicio.dart'; // Revisa el marco compartido en Inicio.

// Verifica navegación, selección y distribución sin escribir en Supabase.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Intercepta el cierre sin cerrar las pruebas.
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart'; // Verifica el botón real del menú.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:frenos_cerna/features/clientes/pagina_crear_cliente.dart';
import 'package:frenos_cerna/features/clientes/presentation/selector_cliente.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_crear_vehiculo.dart';
import 'package:frenos_cerna/features/inventario/pagina_crear_producto.dart';
import 'package:frenos_cerna/features/perfil/pagina_perfil.dart';
import 'package:frenos_cerna/features/opciones/pagina_opciones.dart';
import 'package:frenos_cerna/features/informacion/pagina_informacion.dart';
import 'package:frenos_cerna/features/datos/pagina_datos.dart';
import 'package:frenos_cerna/features/notificaciones/pagina_reserva_producto.dart';
import 'package:frenos_cerna/features/notificaciones/pagina_productos_reservados.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart';
import 'package:frenos_cerna/shared/widgets/panel_filtros.dart'; // Comprueba el buscador del selector.

void main() {
  testWidgets(
    'calidad depende de categoría y ambos catálogos permiten añadir con confirmación',
    (tester) async {
      tester.view.physicalSize = const Size(
        1440,
        1200,
      ); // Muestra el formulario de producto completo.
      tester.view.devicePixelRatio = 1; // Usa coordenadas lógicas.
      addTearDown(tester.view.resetPhysicalSize); // Restablece el tamaño.
      addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
      await tester.pumpWidget(
        MaterialApp(
          home: PaginaCrearProducto(
            cargarCatalogos: () async => {
              'categorias': [
                {'id': 1, 'nombre_tipo': 'PASTILLAS'},
                {'id': 2, 'nombre_tipo': 'DISCOS'},
              ],
              'calidades': [
                {'id': 10, 'nombre_calidad': 'CERÁMICA'},
                {'id': 20, 'nombre_calidad': 'VENTILADO'},
              ],
              'relaciones': [
                {'id_tipo': 1, 'id_calidad': 10},
                {'id_tipo': 2, 'id_calidad': 20},
              ],
            },
          ),
        ),
      ); // Aísla los datos sin escrituras reales.
      await tester.pumpAndSettle(); // Carga las relaciones.
      final selectores = find.byType(
        DropdownButton<Object>,
      ); // Localiza categoría y calidad.
      expect(
        tester.widget<DropdownButton<Object>>(selectores.at(1)).onChanged,
        isNull,
      ); // Bloquea calidades sin categoría.
      await tester.enterText(
        find.byType(TextFormField).first,
        'SP0-01223',
      ); // Conserva el código mientras se usan los catálogos.
      await tester.ensureVisible(selectores.first); // Muestra categoría.
      await tester.tap(selectores.first);
      await tester.pumpAndSettle(); // Abre sus opciones.
      await tester.tap(find.text('PASTILLAS').last);
      await tester.pumpAndSettle(); // Selecciona una categoría existente.
      var calidad = tester.widget<DropdownButton<Object>>(
        selectores.at(1),
      ); // Examina solo sus calidades.
      expect(calidad.items!.map((item) => item.value), [
        10,
        -1,
      ]); // Excluye las calidades de discos.
      await tester.tap(selectores.at(1));
      await tester.pumpAndSettle(); // Abre las calidades permitidas.
      await tester.tap(find.text('CERÁMICA').last);
      await tester.pumpAndSettle(); // Selecciona una calidad.
      await tester.tap(selectores.first);
      await tester.pumpAndSettle(); // Cambia la categoría.
      await tester.tap(find.text('DISCOS').last);
      await tester.pumpAndSettle(); // Selecciona discos.
      calidad = tester.widget<DropdownButton<Object>>(selectores.at(1));
      expect(
        calidad.value,
        isNull,
      ); // Descarta la selección anterior incompatible.
      expect(calidad.items!.map((item) => item.value), [
        20,
        -1,
      ]); // Muestra solo las calidades vinculadas a discos.
      for (final esCalidad in [false, true]) {
        await tester.ensureVisible(
          selectores.at(esCalidad ? 1 : 0),
        ); // Hace visible el selector.
        await tester.tap(selectores.at(esCalidad ? 1 : 0));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(esCalidad ? 'AÑADIR CALIDAD' : 'AÑADIR CATEGORÍA').last,
        );
        await tester.pumpAndSettle(); // Abre la creación en la misma página.
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          ),
          'Opción de prueba',
        ); // Introduce el nombre.
        await tester.tap(find.text('CONTINUAR'));
        await tester.pumpAndSettle(); // Pide confirmar antes de guardar.
        expect(
          find.text(esCalidad ? 'CONFIRMAR CALIDAD' : 'CONFIRMAR CATEGORÍA'),
          findsOneWidget,
        ); // Verifica el paso obligatorio.
        await tester.tap(find.text('CANCELAR'));
        await tester.pumpAndSettle(); // Cancela sin escribir en Supabase.
      }
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'SP0-01223',
      ); // Conserva los datos del producto.
      expect(
        tester.takeException(),
        isNull,
      ); // Descarta errores de reconstrucción o diálogos.
    },
  );

  testWidgets('venta busca cliente y conserva la venta al crear otro', (
    tester,
  ) async {
    // Verifica búsqueda y retorno sin escrituras reales.
    tester.view.physicalSize = const Size(
      1440,
      1000,
    ); // Usa espacio suficiente para el desplegable.
    tester.view.devicePixelRatio = 1; // Mantiene las dimensiones lógicas.
    addTearDown(tester.view.resetPhysicalSize); // Restablece la pantalla.
    addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
    final existente = Cliente(
      id: '111',
      nombre: 'Ana',
      numero: '222',
      ultimaVenta: '',
      vehiculo: '',
    ); // Define un cliente de prueba.
    await tester.pumpWidget(
      MaterialApp(
        home: PaginaCrearVenta(
          cargarProductos: () async => [],
          cargarClientes: () async => [existente],
        ),
      ),
    ); // Abre una venta con catálogo controlado.
    await tester.pumpAndSettle(); // Espera la carga.
    expect(
      find.text('SELECCIÓN DE PRODUCTOS'),
      findsNothing,
    ); // Retira el texto suelto de la página.
    await tester.enterText(
      find.byType(TextFormField).first,
      'ABCD12',
    ); // Conserva una patente antes de navegar.
    await tester.tap(
      find.text('SELECCIONAR CLIENTE'),
    ); // Abre el campo desplegable.
    await tester.pumpAndSettle(); // Espera el menú.
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Nombre o RUT',
      ),
      '111',
    ); // Busca por RUT.
    await tester.pumpAndSettle(); // Actualiza resultados.
    await tester.tap(
      find.text('Ana · RUT: 111'),
    ); // Selecciona el cliente existente.
    await tester.pumpAndSettle(); // Cierra el menú.
    await tester.tap(
      find.text('Ana · RUT: 111'),
    ); // Vuelve a abrir las opciones.
    await tester.pumpAndSettle(); // Espera las opciones.
    await tester.tap(
      find.text('CREAR CLIENTE'),
    ); // Abre el registro de clientes.
    await tester.pumpAndSettle(); // Espera la navegación.
    expect(
      tester
          .widget<PaginaCrearCliente>(find.byType(PaginaCrearCliente))
          .devolverClienteCreado,
      isTrue,
    ); // Exige devolver el registro creado.
    final nuevo = Cliente(
      id: '333',
      nombre: 'Cliente nuevo',
      numero: '444',
      ultimaVenta: '',
      vehiculo: '',
    ); // Simula el resultado de guardar.
    Navigator.of(tester.element(find.byType(PaginaCrearCliente)))
        .pop(nuevo); // Devuelve el cliente sin escribir en Supabase.
    await tester.pumpAndSettle(); // Regresa a la venta.
    expect(
      find.text('Cliente nuevo · RUT: 333'),
      findsOneWidget,
    ); // Selecciona el resultado automáticamente.
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'ABCD12',
    ); // Conserva la patente.
    expect(tester.takeException(), isNull); // Exige ausencia de errores.
  }); // Finaliza la prueba del cliente de venta.

  testWidgets('modelo exige marca y añadir marca requiere confirmación', (
    tester,
  ) async {
    // Comprueba el orden obligatorio y la cancelación sin guardar.
    await tester.pumpWidget(
      const MaterialApp(home: PaginaCrearVehiculo()),
    ); // Abre el registro real sin conectar la base.
    await tester.pumpAndSettle(); // Espera la consulta inicial.
    final selectores = find.byType(
      DropdownButton<int>,
    ); // Localiza ambos catálogos.
    expect(
      tester.widget<DropdownButton<int>>(selectores.at(1)).onChanged,
      isNull,
    ); // Impide seleccionar modelos sin marca.
    await tester.ensureVisible(selectores.first); // Hace visible la marca.
    await tester.tap(selectores.first); // Abre el menú desplazable.
    await tester.pumpAndSettle(); // Espera las opciones.
    await tester.tap(
      find.text('AÑADIR MARCA').last,
    ); // Abre el formulario encima de la página.
    await tester.pumpAndSettle(); // Espera el diálogo.
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      'Marca de prueba',
    ); // Introduce un nombre sin guardarlo.
    await tester.tap(find.text('CONTINUAR')); // Solicita la confirmación.
    await tester.pumpAndSettle(); // Espera la confirmación explícita.
    expect(
      find.text('CONFIRMAR MARCA'),
      findsOneWidget,
    ); // Exige el paso previo a escribir.
    await tester.tap(
      find.text('CANCELAR'),
    ); // Cancela antes de escribir en Supabase.
    await tester.pumpAndSettle(); // Retorna al vehículo.
    expect(
      tester.widget<DropdownButton<int>>(selectores.first).value,
      isNull,
    ); // No selecciona una marca cancelada.
    expect(
      tester.takeException(),
      isNull,
    ); // Comprueba que los diálogos no dejan errores.
  }); // Finaliza la prueba del catálogo.

  testWidgets('cerrar aplicación solicita el cierre de la actividad Android', (
    tester,
  ) async {
    // Verifica el botón sin finalizar el proceso de pruebas.
    final llamadas = <MethodCall>[]; // Conserva las solicitudes al sistema.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (llamada) async {
        llamadas.add(llamada);
        return null;
      },
    ); // Intercepta la salida nativa.
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    ); // Restablece el canal al terminar.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 200, child: MenuLateral(activo: '')),
        ),
      ),
    ); // Construye el menú real.
    await tester.ensureVisible(
      find.byIcon(Icons.power_settings_new),
    ); // Desplaza hasta el botón inferior.
    await tester.tap(
      find.byIcon(Icons.power_settings_new),
    ); // Solicita cerrar mediante el botón.
    await tester.pump(); // Procesa la llamada nativa.
    expect(
      llamadas.any((llamada) => llamada.method == 'SystemNavigator.pop'),
      isTrue,
    ); // Comprueba la solicitud de cierre Android.
  }); // Finaliza la prueba de cierre.

  for (final tamano in [const Size(1920, 1080), const Size(390, 844)]) {
    for (final pagina in <Widget>[
      const PaginaCrearVehiculo(),
      const PaginaCrearProducto(),
      const PaginaPerfil(),
      const PaginaOpciones(),
      const PaginaInformacion(),
      const PaginaDatos(),
      const PaginaReservaProducto(),
      const PaginaProductosReservados(),
    ]) {
      testWidgets('vista nueva $pagina en $tamano', (tester) async {
        tester.view.physicalSize = tamano;
        tester.view.devicePixelRatio = 1; // Configura escritorio o Android.
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(
          tester.view.resetDevicePixelRatio,
        ); // Restablece el entorno.
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Courier'),
            home: pagina,
          ),
        ); // Construye la página real.
        await tester.pumpAndSettle(); // Espera los estados de consulta.
        expect(
          tester.takeException(),
          isNull,
        ); // Exige ausencia de excepciones y desbordamientos.
      }); // Finaliza la prueba de una página.
    } // Finaliza las páginas nuevas.
  } // Finaliza las dimensiones.

  testWidgets(
    'crear cliente devuelve la vinculación y conserva los datos del vehículo',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PaginaCrearVehiculo()),
      ); // Abre el registro real.
      await tester.pumpAndSettle(); // Espera la carga de catálogos.
      final campos = find.byType(
        TextFormField,
      ); // Localiza los campos del vehículo.
      await tester.enterText(campos.at(0), 'ABCD12'); // Ingresa una patente.
      await tester.enterText(campos.at(1), '12345'); // Ingresa el kilometraje.
      await tester.ensureVisible(
        find.text('VINCULAR CON CLIENTE'),
      ); // Desplaza hasta la acción.
      await tester.tap(
        find.text('VINCULAR CON CLIENTE'),
      ); // Abre el menú de vinculación.
      await tester.pumpAndSettle(); // Espera la apertura.
      await tester.tap(
        find.text('NUEVO CLIENTE'),
      ); // Abre Crear cliente sobre el registro de vehículo.
      await tester.pumpAndSettle(); // Espera el cambio de ruta.
      expect(
        tester
            .widget<PaginaCrearCliente>(find.byType(PaginaCrearCliente))
            .devolverClienteCreado,
        isTrue,
      ); // Comprueba el contrato de devolución.
      final cliente = Cliente(
        id: '123',
        nombre: 'Cliente creado',
        numero: '456',
        ultimaVenta: '',
        vehiculo: '',
      ); // Simula el resultado de un registro completado.
      Navigator.of(tester.element(find.byType(PaginaCrearCliente)))
          .pop(cliente); // Devuelve el resultado sin escribir datos reales.
      await tester.pumpAndSettle(); // Espera el regreso a la misma instancia del formulario.
      final controladores = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .map((campo) => campo.controller?.text)
          .toList(); // Recupera los datos conservados.
      expect(
        controladores,
        containsAll(['ABCD12', '12345']),
      ); // Exige conservar patente y kilometraje.
      expect(
        find.text('Cliente creado · RUT: 123'),
        findsOneWidget,
      ); // Exige que el cliente devuelto quede vinculado.
      expect(tester.takeException(), isNull); // Exige un regreso sin errores.
    },
  ); // Finaliza la prueba del flujo de cliente nuevo.

  for (final busqueda in ['ana', '222']) {
    testWidgets('selecciona un cliente existente por $busqueda', (
      tester,
    ) async {
      Cliente? elegido; // Conserva el resultado del buscador.
      final clientes = [
        Cliente(
          id: '111',
          nombre: 'Ana',
          numero: '123',
          ultimaVenta: '',
          vehiculo: '',
        ),
        Cliente(
          id: '222',
          nombre: 'Beatriz',
          numero: '456',
          ultimaVenta: '',
          vehiculo: '',
        ),
      ]; // Define clientes locales de prueba.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  elegido = await seleccionarClienteExistente(
                    context,
                    cargarClientes: () async => clientes,
                  );
                },
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
      ); // Abre el selector real con una fuente controlada.
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle(); // Espera el buscador de clientes.
      await tester.enterText(
        find.descendant(
          of: find.byType(CampoBusqueda),
          matching: find.byType(TextField),
        ),
        busqueda,
      ); // Busca por nombre o RUT.
      await tester.pumpAndSettle(); // Actualiza las filas.
      await tester.tap(
        find.byTooltip('Vincular este cliente'),
      ); // Elige el único cliente que coincide.
      await tester.pumpAndSettle(); // Espera el cierre del selector.
      expect(
        elegido?.id,
        busqueda == 'ana' ? '111' : '222',
      ); // Comprueba la identidad del resultado.
      expect(
        tester.takeException(),
        isNull,
      ); // Exige una selección sin errores.
    }); // Finaliza la prueba por criterio de búsqueda.
  } // Finaliza los criterios requeridos.

  testWidgets('selección de productos se superpone y conserva el carrito', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaginaCrearVenta(
          cargarProductos: () async => [
            ProductoVenta(
              id: '1',
              nombre: 'Producto de prueba',
              categoria: 'Pieza',
              precio: 1000,
              stock: 3,
            ),
          ],
        ),
      ),
    ); // Carga un producto sin consultar Supabase.
    await tester.pumpAndSettle(); // Espera la interfaz de venta.
    await tester.ensureVisible(
      find.text('AÑADIR NUEVO PRODUCTO'),
    ); // Desplaza hasta la acción.
    await tester.tap(find.text('AÑADIR NUEVO PRODUCTO'));
    await tester.pumpAndSettle(); // Abre el menú superpuesto.
    expect(
      find.byType(Dialog),
      findsOneWidget,
    ); // Comprueba que no se sustituyó la página.
    await tester.tap(find.byTooltip('Añadir al carrito'));
    await tester.pumpAndSettle(); // Añade una unidad.
    expect(
      find.byType(Dialog),
      findsOneWidget,
    ); // Mantiene la selección abierta.
    await tester.tap(find.byTooltip('Cerrar selección'));
    await tester.pumpAndSettle(); // Regresa al carrito.
    expect(find.byType(Dialog), findsNothing); // Comprueba el cierre del menú.
    expect(
      find.text('Producto de prueba'),
      findsOneWidget,
    ); // Conserva el producto seleccionado.
    expect(tester.takeException(), isNull); // Exige ausencia de errores.
  }); // Finaliza la comprobación del menú de venta.

  testWidgets('renderiza las composiciones principales para revisión visual', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Carga fuentes reales únicamente para la revisión visual local.
      for (final fuente in <String, String>{
        'Courier': 'C:/Windows/Fonts/cour.ttf',
        'MaterialIcons': 'D:/Flutter/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        // Evita los bloques de texto e iconos de la fuente de pruebas.
        final archivo = File(
          fuente.value,
        ); // Consulta una fuente instalada en este entorno.
        if (await archivo.exists()) {
          // Conserva la ejecución de pruebas cuando la fuente no está instalada.
          final cargador = FontLoader(fuente.key)
            ..addFont(
              archivo.readAsBytes().then(
                (bytes) => ByteData.sublistView(bytes),
              ),
            ); // Conserva el nombre que utiliza la aplicación.
          await cargador
              .load(); // Espera la carga antes de capturar las vistas.
        } // Finaliza la carga opcional.
      } // Finaliza las fuentes de revisión.
    }); // Finaliza la preparación visual fuera del reloj simulado.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1; // Usa el tamaño de los marcos de Figma.
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio); // Restablece la pantalla.
    final vistas = <String, Widget>{
      'crear_cliente': const PaginaCrearCliente(),
      'crear_vehiculo': const PaginaCrearVehiculo(),
      'perfil': const PaginaPerfil(),
      'inicio': const PaginaInicio(modoPrueba: true),
      'venta': PaginaCrearVenta(cargarProductos: () async => []),
    }; // Selecciona las composiciones a revisar.
    for (final vista in vistas.entries) {
      final clave = GlobalKey(); // Identifica el área a renderizar.
      await tester.pumpWidget(
        RepaintBoundary(
          key: clave,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Courier'),
            home: vista.value,
          ),
        ),
      ); // Construye la página con su tipografía.
      await tester.pumpAndSettle(); // Espera el diseño final.
      final borde =
          clave.currentContext!.findRenderObject()
              as RenderRepaintBoundary; // Obtiene la superficie visible.
      await tester.runAsync(() async {
        final imagen = await borde
            .toImage(); // Renderiza fuera del reloj simulado de pruebas.
        final datos = await imagen.toByteData(
          format: ui.ImageByteFormat.png,
        ); // Codifica la captura.
        await File(
          'C:/Users/beig1/.codex/visualizations/2026/10/16/01a144e6-d337-74b1-9eac-7e636082bec7/figma_${vista.key}.png',
        ).writeAsBytes(
          datos!.buffer.asUint8List(),
        ); // Conserva la captura fuera del repositorio.
        imagen.dispose(); // Libera la captura.
      }); // Finaliza la captura nativa.

      expect(tester.takeException(), isNull); // Exige una composición válida.
    } // Finaliza las capturas.
  }); // Finaliza la revisión renderizada.
} // Finaliza las pruebas del flujo.
