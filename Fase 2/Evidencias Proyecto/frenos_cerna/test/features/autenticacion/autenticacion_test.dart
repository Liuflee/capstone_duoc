import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart'; // Aísla el almacenamiento de cada vista de prueba.
import 'package:shared_preferences/shared_preferences.dart'; // Simula las pendientes locales en las pruebas de distribución.
// Importa la barra y el menú para comprobar sus dimensiones comunes.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
// Importa un widget compartido para verificar su comportamiento.
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';
// Importa un widget compartido para verificar su comportamiento.
import 'package:frenos_cerna/shared/widgets/filtros_tabla.dart';
// Importa un widget compartido para verificar su comportamiento.
import 'package:frenos_cerna/shared/widgets/buscador_tabla.dart';
// Importa un widget compartido para verificar su comportamiento.
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/inicio/pagina_inicio.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/clientes/pagina_crear_cliente.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/clientes/pagina_editar_cliente.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/inventario/pagina_edicion_producto.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/vehiculos/pagina_detalle_vehiculo.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/ventas/presentation/pagina_historial_ventas.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart';
// Importa una página para verificar su distribución en ambas plataformas.
import 'package:frenos_cerna/features/notificaciones/pagina_notificaciones.dart';
// Importa las cartas para comprobar el estado de las acciones.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/autenticacion/data/autenticacion_repository.dart';
import 'package:frenos_cerna/features/autenticacion/presentation/pagina_autenticacion.dart';

void main() {
  for (final plataforma in [TargetPlatform.android, TargetPlatform.windows]) {
    // Comprueba el diseño original en ambas plataformas.
    testWidgets('login conserva botones originales en $plataforma', (
      tester,
    ) async {
      // Protege la restauración frente a futuros ajustes generales.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: plataforma),
          home: PaginaAutenticacion(onEntrarModoPrueba: () {}),
        ),
      ); // Abre el acceso real con todas sus acciones.
      await tester.pumpAndSettle(); // Espera la composición del formulario.
      for (final registro in [false, true]) {
        // Verifica inicio de sesión y creación de cuenta.
        if (registro) {
          // Cambia al registro mediante el enlace original.
          await tester.ensureVisible(
            find.text('¿No tienes cuenta? Regístrate'),
          ); // Hace visible el enlace.
          await tester.tap(
            find.text('¿No tienes cuenta? Regístrate'),
          ); // Abre el formulario de registro.
          await tester.pumpAndSettle(); // Espera la actualización.
        } // Finaliza el cambio de modo.
        final boton = tester.getSize(
          find.byType(FilledButton),
        ); // Mide el botón principal restaurado.
        final campo = tester.getSize(
          find.byType(TextFormField).first,
        ); // Usa el ancho original del formulario como referencia.
        expect(
          boton.width,
          closeTo(campo.width, 0.01),
        ); // Mantiene el botón del ancho completo del formulario.
        expect(boton.height, 48); // Conserva el alto original del acceso.
        expect(
          tester
              .widget<TextButton>(find.byType(TextButton))
              .style
              ?.backgroundColor,
          isNull,
        ); // Conserva el enlace sin fondo gris.
        expect(
          tester
              .widget<OutlinedButton>(find.byType(OutlinedButton))
              .style
              ?.backgroundColor,
          isNull,
        ); // Conserva el acceso de prueba sin relleno gris.
        expect(
          tester
              .widgetList<CartaNavegacion>(find.byType(CartaNavegacion))
              .every((carta) => carta.conservarEstiloOriginal),
          isTrue,
        ); // Mantiene las tres acciones fuera del ajuste de botones medianos.
        expect(
          tester.takeException(),
          isNull,
        ); // Exige ausencia de errores visuales.
      } // Finaliza los modos de acceso.
    }); // Finaliza una plataforma.
  } // Finaliza la protección del diseño original.

  setUp(
    () => SharedPreferences.setMockInitialValues({}),
  ); // Evita depender del almacenamiento nativo en pruebas.
  group('RolUsuario', () {
    test('reconoce los perfiles definidos para la aplicación', () {
      expect(
        RolUsuario.desdeBaseDeDatos('administrador'),
        RolUsuario.administrador,
      );
      expect(RolUsuario.desdeBaseDeDatos('empleado'), RolUsuario.empleado);
    });

    test('rechaza roles no contemplados', () {
      expect(
        () => RolUsuario.desdeBaseDeDatos('superusuario'),
        throwsFormatException,
      );
    });
  });

  testWidgets('muestra el acceso y deshabilita acciones sin Supabase', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: PaginaAutenticacion(onEntrarModoPrueba: () {})),
    );

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿No tienes cuenta? Regístrate'), findsOneWidget);
    expect(find.text('Entrar en modo de prueba'), findsOneWidget);
    expect(
      tester
          .widget<CartaNavegacion>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is CartaNavegacion && widget.tipoBoton == 'filled',
            ),
          )
          .alPresionar,
      isNull,
    );
  });

  testWidgets('permite activar el acceso local de prueba', (tester) async {
    var modoPruebaActivado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PaginaAutenticacion(
          onEntrarModoPrueba: () => modoPruebaActivado = true,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Entrar en modo de prueba'));
    await tester.tap(find.text('Entrar en modo de prueba'));
    expect(modoPruebaActivado, isTrue);
  });

  // Comprueba todas las páginas en escritorio y Android sin modificar datos reales.
  for (final tamano in [const Size(1440, 1000), const Size(390, 844)]) {
    final cliente = Cliente(
      id: '1',
      nombre: 'Cliente',
      numero: '123',
      ultimaVenta: '',
      vehiculo: 'Vehículo',
    ); // Define un cliente local.
    final producto = Producto(
      id: '1',
      nombre: 'Producto',
      codigoBarra: 'ABC',
      categoria: 'Frenos',
      precio: 1000,
      cantidad: 2,
    ); // Define un producto local.
    final vehiculo = HistorialVehiculo(
      id: 'AB1234',
      clienteNombre: 'Cliente',
      vehiculoNombre: 'Vehículo',
      total: 1000,
      fecha: '',
    ); // Define un vehículo local.
    for (final pagina in <Widget>[
      const PaginaInicio(), // Comprueba las tarjetas de Inicio.
      const PaginaClientes(), // Comprueba el listado de clientes.
      const PaginaCrearCliente(), // Comprueba el registro.
      PaginaEditarCliente(cliente: cliente), // Comprueba la edición.
      const PaginaInventario(), // Comprueba el inventario.
      PaginaEdicionProducto(
        producto: producto,
      ), // Comprueba la edición del producto.
      const PaginaVehiculos(), // Comprueba los vehículos.
      PaginaDetalleVehiculo(vehiculo: vehiculo), // Comprueba el detalle.
      PaginaVentas(
        repositorioPendientes: VentasPendientesRepository(
          clave: 'distribucion',
        ),
        cargarVentas: () async => [],
      ), // Comprueba ventas sin conexión ni almacenamiento de otras pruebas.
      const PaginaCrearVenta(), // Comprueba el formulario y el carrito.
      const PaginaHistorialVentas(), // Comprueba el historial.
      const PaginaDetalleVenta(
        idVenta: '1',
        clienteNombre: 'Cliente',
        vehiculoNombre: 'Vehículo',
        total: 1000,
        desdeHistorial: false,
      ), // Comprueba el detalle de venta.
      const PaginaNotificaciones(), // Comprueba las reservas.
    ]) {
      testWidgets('distribución ${pagina.runtimeType} ${tamano.width}', (
        tester,
      ) async {
        // Detecta fallos visuales de cada página.
        tester.view.physicalSize =
            tamano; // Configura las dimensiones de la pantalla.
        tester.view.devicePixelRatio =
            1; // Mantiene una escala lógica uniforme.
        addTearDown(
          tester.view.resetPhysicalSize,
        ); // Restablece el tamaño después de la prueba.
        addTearDown(
          tester.view.resetDevicePixelRatio,
        ); // Restablece la escala después de la prueba.
        await tester.pumpWidget(
          MaterialApp(home: pagina),
        ); // Construye la página completa.
        await tester
            .pumpAndSettle(); // Espera los cambios de carga y las animaciones.
        expect(
          tester.getSize(find.byType(BarraSuperior)).height,
          closeTo(tamano.height * 0.10, 0.01),
        ); // Comprueba la altura común de la barra.
        if (tamano.width >= 700) {
          expect(
            tester.getSize(find.byType(MenuLateral)).width,
            closeTo(tamano.width * 0.12, 0.01),
          );
        } // Comprueba el ancho común del menú.
        expect(
          tester.takeException(),
          isNull,
        ); // Exige ausencia de excepciones y desbordamientos.
      }); // Finaliza la prueba de esta página.
    } // Finaliza el recorrido de páginas.
  } // Finaliza las dimensiones comprobadas.

  // Comprueba que la búsqueda respete el campo seleccionado y mantenga abierto el menú.
  testWidgets('tabla combina búsqueda y filtro sin cerrar el menú', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TablaDatos(
            nombresColumnas: const [
              'NOMBRE',
              'RUT',
            ], // Define las columnas visibles.
            camposColumnas: const [
              'nombre',
              'rut',
            ], // Asocia filtros a los datos reales.
            anchosColumnas: const [
              2,
              1,
            ], // Conserva las proporciones de prueba.
            filas: const [
              {'nombre': 'Ana', 'rut': '11'},
              {'nombre': 'Luis', 'rut': '22'},
            ], // Utiliza registros locales.
          ),
        ),
      ),
    ); // Construye la tabla con sus controles.
    final anchoTabla =
        tester.getSize(find.byType(TablaDatos)).width -
        14; // Obtiene el ancho visible sin el desplazamiento.
    expect(
      tester.getSize(find.byType(BuscadorTabla)).width,
      closeTo(anchoTabla * 0.33, 0.01),
    ); // Comprueba el ancho del buscador.
    expect(
      tester.getSize(find.byType(FiltrosTabla)).width,
      closeTo(anchoTabla * 0.33, 0.01),
    ); // Comprueba el ancho del filtro.
    await tester.enterText(
      find.descendant(
        of: find.byType(BuscadorTabla),
        matching: find.byType(TextField),
      ),
      'Ana',
    ); // Busca por el nombre.
    await tester.pumpAndSettle(); // Actualiza los registros visibles.
    expect(
      find
          .text('Ana', findRichText: false)
          .evaluate()
          .where((elemento) => elemento.widget is Text)
          .length,
      1,
    ); // Conserva la coincidencia.
    expect(
      find.text('Luis'),
      findsNothing,
    ); // Oculta los registros que no coinciden.
    await tester.tap(
      find.byType(FiltrosTabla),
    ); // Abre las opciones del filtro.
    await tester.pumpAndSettle(); // Espera la apertura del menú superpuesto.
    await tester.tap(find.text('FILTRO : RUT')); // Limita la búsqueda al RUT.
    await tester
        .pumpAndSettle(); // Actualiza los resultados sin cerrar el menú.
    expect(
      find.text('No hay registros para mostrar'),
      findsOneWidget,
    ); // Exige que se aplique el campo seleccionado.
    expect(
      find.text('FILTRO : NOMBRE'),
      findsOneWidget,
    ); // Comprueba que el menú siga abierto.
    await tester.tap(
      find.text('FILTRO : NOMBRE'),
    ); // Cambia al campo de nombre.
    await tester.pumpAndSettle(); // Actualiza la selección y las filas.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Ana',
      ),
      findsOneWidget,
    ); // Recupera el registro que coincide.
    await tester.tapAt(const Offset(780, 580)); // Pulsa fuera del menú.
    await tester.pumpAndSettle(); // Espera el cierre.
    expect(
      find.text('FILTRO : RUT'),
      findsNothing,
    ); // Comprueba que se cerraron las opciones.
    expect(
      tester.takeException(),
      isNull,
    ); // Exige ausencia de errores de interacción.
  }); // Finaliza la prueba conjunta de búsqueda y filtros.

  // Comprueba distribuciones rectangulares y cuadradas con campos uniformes.
  for (final distribucion in [(2, 2), (3, 3), (2, 3), (3, 2), (5, 5)]) {
    testWidgets('formulario uniforme $distribucion', (tester) async {
      final controladores = List.generate(
        distribucion.$1 * distribucion.$2,
        (_) => TextEditingController(),
      ); // Crea los datos de prueba.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormularioDatos(
                filas: distribucion.$1,
                columnas:
                    distribucion.$2, // Aplica las filas y columnas solicitadas.
                campos: List.generate(
                  controladores.length,
                  (indice) => CampoFormularioDatos(
                    controlador: controladores[indice], // Conserva un controlador independiente.
                    etiqueta: indice == 0
                        ? 'ETIQUETA MÁS LARGA DEL FORMULARIO'
                        : 'DATO', // Incluye una etiqueta de mayor tamaño.
                    textoAyuda:
                        'Escribe un dato', // Configura el texto interior.
                  ),
                ), // Finaliza los campos de prueba.
              ),
            ),
          ),
        ),
      ); // Construye el formulario en un área desplazable.
      final campos = find.byType(
        TextFormField,
      ); // Localiza los campos generados.
      expect(
        campos,
        findsNWidgets(controladores.length),
      ); // Exige que todos los campos estén presentes.
      final medida = tester.getSize(
        campos.first,
      ); // Obtiene el tamaño del primer campo.
      for (int indice = 1; indice < controladores.length; indice++) {
        expect(
          tester.getSize(campos.at(indice)),
          medida,
        ); // Comprueba la igualdad de todos los campos.
      } // Finaliza la comparación de tamaños.
      expect(
        tester.takeException(),
        isNull,
      ); // Comprueba que la cuadrícula no desborde.
      await tester.pumpWidget(
        const SizedBox.shrink(),
      ); // Retira el formulario antes de liberar sus recursos.
      for (final controlador in controladores) {
        controlador.dispose(); // Libera los controladores de prueba.
      } // Finaliza la liberación de recursos.
    }); // Finaliza la prueba de esta distribución.
  } // Finaliza las distribuciones solicitadas.

  // Compara las dimensiones de los botones originales con sus cartas equivalentes.
  for (final plataforma in [TargetPlatform.android, TargetPlatform.windows]) {
    testWidgets('cartas usan dimensiones medianas en ${plataforma.name}', (
      tester,
    ) async {
      final estilo = ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ); // Define el espaciado utilizado por las páginas.
      final pares = <(Widget, Widget)>[
        (
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save),
            label: const Text('GUARDAR'),
            style: estilo,
          ),
          CartaNavegacion.accion(
            onPressed: () {},
            icon: const Icon(Icons.save),
            label: const Text('GUARDAR'),
            style: estilo,
          ),
        ), // Compara una acción con icono.
        (
          TextButton(onPressed: () {}, child: const Text('Cancelar')),
          CartaNavegacion.accion(
            tipoBoton: 'text',
            onPressed: () {},
            child: const Text('Cancelar'),
          ),
        ), // Compara una acción de diálogo.
        (
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, size: 30),
          ),
          CartaNavegacion.accion(
            tipoBoton: 'icon',
            onPressed: () {},
            child: const Icon(Icons.search, size: 30),
          ),
        ), // Compara una acción de tabla.
      ]; // Finaliza las acciones de referencia.
      for (final par in pares) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: plataforma),
            home: Scaffold(
              body: Row(
                children: [
                  SizedBox(
                    key: const ValueKey('original'),
                    child: par.$1,
                  ), // Mide el botón anterior.
                  SizedBox(
                    key: const ValueKey('carta'),
                    child: par.$2,
                  ), // Mide su carta equivalente.
                ], // Finaliza los controles de comparación.
              ),
            ),
          ),
        ); // Construye ambas versiones bajo el mismo tema.
        final medida = tester.getSize(
          find.byKey(const ValueKey('carta')),
        ); // Mide el nuevo tamaño accesible.
        expect(
          medida.height,
          greaterThanOrEqualTo(48),
        ); // Exige un área cómoda para pulsar.
        expect(
          medida.width,
          lessThanOrEqualTo(320),
        ); // Evita botones que ocupen toda la página.
        expect(tester.takeException(), isNull); // Comprueba ambas plataformas.
      } // Finaliza las acciones de esta plataforma.
    }); // Finaliza la comprobación de dimensiones.
  } // Finaliza las plataformas comprobadas.

  // Verifica el ancho de las tablas que antes calculaban su tamaño por contenido.
  testWidgets('tabla de detalle conserva su ancho natural', (tester) async {
    const columnas = [
      DataColumn(label: Text('PRODUCTO')),
      DataColumn(label: Text('TOTAL')),
    ]; // Define los encabezados de referencia.
    const filas = [
      DataRow(
        cells: [DataCell(Text('Pastillas de freno')), DataCell(Text('1000'))],
      ),
    ]; // Define los datos de referencia.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 200,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(columns: columnas, rows: filas),
                ),
              ), // Construye la tabla original.
              SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: TablaDatos.desdeCeldas(columns: columnas, rows: filas),
                ),
              ), // Construye su reemplazo compartido.
            ],
          ),
        ),
      ),
    ); // Aplica las mismas restricciones de ancho.
    expect(
      tester.getSize(find.byType(TablaDatos)).width,
      closeTo(tester.getSize(find.byType(DataTable)).width, 0.01),
    ); // Exige conservar el ancho anterior.
    expect(
      tester.takeException(),
      isNull,
    ); // Comprueba que ambas distribuciones sean válidas.
  }); // Finaliza la comparación del ancho de tablas.
}
