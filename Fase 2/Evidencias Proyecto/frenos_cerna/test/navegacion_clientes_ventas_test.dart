import 'package:flutter/material.dart'; // Construye las vistas que utilizará la persona encargada.
import 'package:flutter_test/flutter_test.dart'; // Verifica rutas y distribución sin escrituras reales.
import 'package:shared_preferences/shared_preferences.dart'; // Aísla las ventas locales de prueba.
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart'; // Consulta la nueva columna de información.
import 'package:frenos_cerna/features/clientes/pagina_ver_cliente.dart'; // Verifica la consulta sin edición.
import 'package:frenos_cerna/features/clientes/pagina_editar_cliente.dart';
import 'package:frenos_cerna/features/inicio/pagina_inicio.dart'; // Verifica las tarjetas de acceso.
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart'; // Conserva fechas y relaciones reales.
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart'; // Conserva las pendientes de distintos días.
import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart'; // Verifica el acceso directo a registrar una venta.
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart'; // Verifica Ver cliente desde ambos historiales.
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas.dart'; // Verifica el alcance diario.
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas_historial.dart'; // Verifica el historial completo.
import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_detalle_vehiculo.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart'; // Inspecciona las filas que recibe la tabla compartida.

void main() {
  // Comprueba los cambios de navegación solicitados.
  TestWidgetsFlutterBinding.ensureInitialized(); // Habilita el entorno de pruebas.
  setUp(
    () => SharedPreferences.setMockInitialValues({}),
  ); // Evita mezclar ventas de distintas pruebas.
  final cliente = Cliente(
    id: '123',
    nombre: 'Cliente consultado',
    numero: '456',
    ultimaVenta: '',
    vehiculo: 'ABCD12',
  ); // Define un perfil identificable por RUT.

  for (final tamano in [const Size(1440, 1000), const Size(390, 844)]) {
    // Comprueba escritorio y Android.
    testWidgets('Ver cliente muestra información sin editar en $tamano', (
      tester,
    ) async {
      // Conserva la disposición de la edición sin sus acciones.
      tester.view.physicalSize = tamano; // Configura la pantalla.
      tester.view.devicePixelRatio = 1; // Usa coordenadas lógicas.
      addTearDown(tester.view.resetPhysicalSize); // Restablece el tamaño.
      addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
      await tester.pumpWidget(
        MaterialApp(
          home: PaginaVerCliente(
            cliente: cliente,
            cargarHistorial: (_) async => [],
          ),
        ),
      ); // Abre el perfil real sin conexión.
      await tester.pumpAndSettle(); // Espera la composición.
      expect(
        find.text('RUT: 123'),
        findsOneWidget,
      ); // Muestra el cliente correcto.
      expect(
        tester
            .widgetList<TextFormField>(find.byType(TextFormField))
            .every((campo) => !campo.enabled),
        isTrue,
      ); // Impide editar la información.
      expect(
        find.text('GUARDAR CAMBIOS'),
        findsNothing,
      ); // No ofrece escrituras desde Ver cliente.
      expect(
        tester.takeException(),
        isNull,
      ); // Exige ausencia de desbordamientos.
    }); // Finaliza la consulta de una pantalla.
  } // Finaliza las dos plataformas.

  testWidgets('Clientes conserva el lápiz y añade la consulta al final', (
    tester,
  ) async {
    // Comprueba la columna y su ruta independiente.
    await tester.pumpWidget(
      const MaterialApp(home: PaginaClientes()),
    ); // Abre la lista real.
    await tester.pumpAndSettle(); // Espera la carga sin Supabase.
    final tabla = tester.widget<TablaDatos>(
      find.byType(TablaDatos),
    ); // Obtiene los constructores de las acciones.
    expect(
      tabla.nombresColumnas.last,
      'VER',
    ); // Coloca la consulta después de editar.
    expect(
      tabla.celdasPersonalizadas.keys,
      containsAll([4, 5]),
    ); // Conserva ambas funciones separadas.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                tabla.celdasPersonalizadas[5]!(context, {'cliente': cliente}),
          ),
        ),
      ),
    ); // Construye la acción real de la última columna.
    await tester.tap(
      find.byTooltip('Ver cliente'),
    ); // Abre el perfil con la lupa.
    await tester.pumpAndSettle(); // Espera la navegación.
    expect(
      find.byType(PaginaVerCliente),
      findsOneWidget,
    ); // No abre la edición.
    expect(
      find.text('GUARDAR CAMBIOS'),
      findsNothing,
    ); // Mantiene la consulta sin cambios.
  }); // Finaliza la verificación de la columna.

  testWidgets('Cliente muestra todos sus vehículos y abre cada detalle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vehiculos = [
      HistorialVehiculo(
        id: 'ABCD12',
        clienteNombre: cliente.nombre,
        vehiculoNombre: 'Toyota Corolla (ABCD12)',
        total: 124000,
        fecha: 'ABCD12',
      ),
      HistorialVehiculo(
        id: 'EFGH34',
        clienteNombre: cliente.nombre,
        vehiculoNombre: 'Kia Rio (EFGH34)',
        total: 87000,
        fecha: 'EFGH34',
      ),
    ];
    final clienteConVehiculos = Cliente.fromJson({
      'rut': '123',
      'nombre': cliente.nombre,
      'fono': cliente.numero,
      'vehiculo_cliente': [
        {
          'patente': 'ABCD12',
          'modelo_vehiculo': {
            'modelo': 'Corolla',
            'marca_vehiculo': {'marca': 'Toyota'},
          },
        },
        {
          'patente': 'EFGH34',
          'modelo_vehiculo': {
            'modelo': 'Rio',
            'marca_vehiculo': {'marca': 'Kia'},
          },
        },
      ],
    });
    expect(clienteConVehiculos.vehiculos, [
      'Toyota Corolla (ABCD12)',
      'Kia Rio (EFGH34)',
    ]);
    expect(clienteConVehiculos.patentesVehiculos, ['ABCD12', 'EFGH34']);

    await tester.pumpWidget(
      MaterialApp(
        home: PaginaVerCliente(
          cliente: clienteConVehiculos,
          cargarHistorial: (_) async => [],
          cargarVehiculos: (_) async => vehiculos,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 vehículos'), findsOneWidget);
    expect(find.text('Toyota Corolla (ABCD12)'), findsOneWidget);
    expect(find.text('Kia Rio (EFGH34)'), findsOneWidget);
    await tester.tap(find.byTooltip('Ver detalle de EFGH34'));
    await tester.pumpAndSettle();
    expect(find.byType(PaginaDetalleVehiculo), findsOneWidget);
    expect(
      tester.widget<PaginaDetalleVehiculo>(
        find.byType(PaginaDetalleVehiculo),
      ).vehiculo.id,
      'EFGH34',
    );
    expect(tester.takeException(), isNull);

  });

  testWidgets('Edición de cliente muestra todos sus vehículos', (tester) async {
    final vehiculos = [
      HistorialVehiculo(
        id: 'ABCD12',
        clienteNombre: cliente.nombre,
        vehiculoNombre: 'Toyota Corolla (ABCD12)',
        total: 124000,
        fecha: 'ABCD12',
      ),
      HistorialVehiculo(
        id: 'EFGH34',
        clienteNombre: cliente.nombre,
        vehiculoNombre: 'Kia Rio (EFGH34)',
        total: 87000,
        fecha: 'EFGH34',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PaginaEditarCliente(
          cliente: cliente,
          cargarHistorial: (_) async => [],
          cargarVehiculos: (_) async => vehiculos,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 vehículos'), findsOneWidget);
    expect(find.text('Toyota Corolla (ABCD12)'), findsOneWidget);
    expect(find.text('Kia Rio (EFGH34)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Venta permite elegir entre las patentes del cliente', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clienteConVehiculos = Cliente(
      id: '123',
      nombre: cliente.nombre,
      numero: cliente.numero,
      ultimaVenta: '',
      vehiculo: 'ABCD12, EFGH34',
      vehiculos: const ['Toyota Corolla (ABCD12)', 'Kia Rio (EFGH34)'],
      patentesVehiculos: const ['ABCD12', 'EFGH34'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PaginaCrearVenta(
          cargarClientes: () async => [clienteConVehiculos],
          cargarProductos: () async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('SELECCIONAR CLIENTE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cliente consultado · RUT: 123'));
    await tester.pumpAndSettle();

    expect(find.byType(ActionChip), findsNWidgets(2));
    await tester.tap(find.widgetWithText(ActionChip, 'EFGH34'));
    await tester.pump();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text,
      'EFGH34',
    );
    expect(tester.takeException(), isNull);
  });

  for (final pendiente in [false, true]) {
    // Comprueba el botón compartido por ambos historiales.
    testWidgets(
      'Ver cliente abre su perfil desde historial pendiente=$pendiente',
      (tester) async {
        // Usa el RUT en lugar de buscar por nombre.
        tester.view.physicalSize = const Size(
          1440,
          1000,
        ); // Conserva el botón visible.
        tester.view.devicePixelRatio = 1; // Usa coordenadas lógicas.
        addTearDown(tester.view.resetPhysicalSize); // Restablece el tamaño.
        addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
        String? rutConsultado; // Conserva la clave solicitada.
        const venta = VentaRegistro(
          id: '99',
          rutCliente: '123',
          clienteNombre: 'Cliente consultado',
          vehiculoNombre: 'ABCD12',
          productosResumen: 'Freno',
          total: 1000,
          fecha: 'No registrada',
          items: [],
        ); // Conserva la relación con el cliente.
        await tester.pumpWidget(
          MaterialApp(
            home: PaginaDetalleVenta(
              idVenta: '99',
              clienteNombre: cliente.nombre,
              vehiculoNombre: 'ABCD12',
              total: 1000,
              desdeHistorial: false,
              ventaInicial: venta,
              esPendiente: pendiente,
              cargarCliente: (rut) async {
                rutConsultado = rut;
                return cliente;
              },
              cargarHistorialCliente: (_) async => [],
            ),
          ),
        ); // Abre la composición real del historial.
        await tester.pumpAndSettle(); // Espera la carga del detalle.
        await tester.tap(
          find.text('VER CLIENTE'),
        ); // Consulta el perfil desde el historial.
        await tester.pumpAndSettle(); // Espera la navegación.
        expect(
          rutConsultado,
          '123',
        ); // Consulta exactamente al cliente de la venta.
        expect(
          find.byType(PaginaVerCliente),
          findsOneWidget,
        ); // Abre la nueva vista de información.
        expect(
          find.text('RUT: 123'),
          findsOneWidget,
        ); // Muestra el perfil solicitado.
        expect(
          find.text('GUARDAR CAMBIOS'),
          findsNothing,
        ); // No permite modificarlo desde esta consulta.
      },
    ); // Finaliza un origen de historial.
  } // Finaliza ambos historiales.

  testWidgets(
    'Ventas muestra el día e Historial conserva otros días y fechas desconocidas',
    (tester) async {
      // Comprueba la separación funcional sin inventar fechas.
      tester.view.physicalSize = const Size(
        1440,
        1000,
      ); // Usa una tabla de escritorio.
      tester.view.devicePixelRatio = 1; // Usa coordenadas lógicas.
      addTearDown(tester.view.resetPhysicalSize); // Restablece el tamaño.
      addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
      final hoy = DateTime(2026, 10, 16, 12); // Controla el día de trabajo.
      final ayer = hoy.subtract(
        const Duration(days: 1),
      ); // Define un día distinto.
      final repositorio = VentasPendientesRepository(
        clave: 'prueba',
      ); // Aísla las ventas locales.
      for (final fecha in [hoy, ayer]) {
        // Prepara dos pendientes de distintos días.
        await repositorio.guardar(
          VentaPendiente(
            id: fecha.toString(),
            rutCliente: '123',
            nombreCliente: 'Pendiente',
            fonoCliente: '456',
            patente: '',
            fechaCreacion: fecha,
            articulos: [
              const ArticuloVentaPendiente(
                codigo: '10',
                nombre: 'Freno',
                categoria: '',
                precio: 1000,
                cantidad: 1,
                stock: 5,
              ),
            ],
          ),
        ); // Conserva la fecha original del borrador.
      } // Finaliza las pendientes.
      final ventas = [
        for (final fecha in <DateTime?>[hoy, ayer, null])
          VentaRegistro(
            id: fecha.toString(),
            rutCliente: '123',
            clienteNombre: 'Cliente cerrado',
            vehiculoNombre: '',
            productosResumen: 'Freno',
            total: 1000,
            fecha: '',
            fechaRegistro: fecha,
            items: [],
          ),
      ]; // Incluye una venta antigua sin fecha conocida.
      await tester.pumpWidget(
        MaterialApp(
          home: PaginaVentas(
            repositorioPendientes: repositorio,
            cargarVentas: () async => ventas,
            ahora: () => hoy,
          ),
        ),
      ); // Abre exclusivamente el día actual.
      await tester.pumpAndSettle(); // Espera ambas fuentes de datos.
      expect(
        tester.widget<TablaDatos>(find.byType(TablaDatos)).filas,
        hasLength(2),
      ); // Muestra una pendiente y una cerrada del día.
      expect(
        find.text('REGISTRAR\nVENTA NUEVA'),
        findsNothing,
      ); // Retira el botón grande de registro.
      expect(find.text('AGREGAR VENTA'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: PaginaVentasHistorial(
            repositorioPendientes: repositorio,
            cargarVentas: () async => ventas,
          ),
        ),
      ); // Abre la página independiente de historial.
      await tester.pumpAndSettle(); // Recupera el catálogo completo.
      expect(
        tester.widget<TablaDatos>(find.byType(TablaDatos)).filas,
        hasLength(5),
      ); // Incluye todos los días y las ventas sin fecha conocida.
      expect(
        find.text('REGISTRAR\nVENTA NUEVA'),
        findsNothing,
      ); // El historial tampoco ofrece registrar una venta nueva.
      expect(find.text('AGREGAR VENTA'), findsNothing);
      expect(tester.takeException(), isNull); // Exige una distribución válida.
    },
  ); // Finaliza la comparación entre día e historial.

  test('VentaRegistro conserva fecha del servidor y nunca asigna una fecha a ventas antiguas', () {
    // Comprueba compatibilidad antes y después de aplicar la columna.
    final reciente = VentaRegistro.fromJson({
      'id': 1,
      'rut_cliente': 123,
      'fecha_registro': '2026-10-16T15:30:00Z',
    }); // Simula una venta con la nueva fecha.
    final antigua = VentaRegistro.fromJson({
      'id': 2,
      'rut_cliente': 123,
    }); // Simula una venta anterior a la modificación.
    expect(
      reciente.fechaRegistro!.toUtc(),
      DateTime.utc(2026, 10, 16, 15, 30),
    ); // Conserva el instante registrado por el servidor.
    expect(
      antigua.fechaRegistro,
      isNull,
    ); // No inventa un día para la venta antigua.
    expect(reciente.rutCliente, '123'); // Conserva el vínculo al perfil.
  }); // Finaliza la compatibilidad de fecha.

  testWidgets(
    'la fecha YYYY-MM-DD de Supabase aparece en ventas del mismo día',
    (tester) async {
      // Verifica el formato utilizado al ingresar fechas manualmente.
      tester.view.physicalSize = const Size(
        1440,
        1000,
      ); // Conserva visible la tabla del día.
      tester.view.devicePixelRatio = 1; // Usa coordenadas lógicas.
      addTearDown(tester.view.resetPhysicalSize); // Restablece el tamaño.
      addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
      final venta = VentaRegistro.fromJson({
        'id': 1,
        'rut_cliente': 123,
        'fecha_registro': '2026-10-16',
        'cliente': {'nombre': 'Venta manual de hoy'},
      }); // Simula la respuesta de una columna DATE.
      expect(
        venta.fechaRegistro,
        DateTime(2026, 10, 16),
      ); // Conserva el día 16 sin convertirlo a la víspera.
      expect(
        venta.fechaRegistro!.isUtc,
        isFalse,
      ); // Trata una fecha sin hora como un día local.
      await tester.pumpWidget(
        MaterialApp(
          home: PaginaVentas(
            repositorioPendientes: VentasPendientesRepository(
              clave: 'fecha-manual',
            ),
            cargarVentas: () async => [venta],
            ahora: () => DateTime(2026, 10, 16, 12),
          ),
        ),
      ); // Abre la vista diaria con el mismo día ingresado en Supabase.
      await tester.pumpAndSettle(); // Espera la carga de ventas.
      expect(
        tester
            .widget<TablaDatos>(find.byType(TablaDatos))
            .filas
            .single['cliente'],
        'Venta manual de hoy',
      ); // Incluye la venta en el día correcto.
      expect(
        tester.takeException(),
        isNull,
      ); // Exige ausencia de errores de presentación.
    },
  ); // Finaliza la regresión del formato de fecha.

  for (final historial in [true, false]) {
    // Comprueba las dos tarjetas modificadas de Inicio.
    testWidgets(
      'Inicio abre ${historial ? 'historial completo' : 'nueva venta'}',
      (tester) async {
        // Verifica los accesos solicitados.
        tester.view.physicalSize = const Size(
          1440,
          1000,
        ); // Conserva las tarjetas visibles.
        tester.view.devicePixelRatio = 1; // Usa coordenadas lógicas.
        addTearDown(tester.view.resetPhysicalSize); // Restablece el tamaño.
        addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
        await tester.pumpWidget(
          const MaterialApp(home: PaginaInicio(modoPrueba: true)),
        ); // Construye la página principal real.
        await tester.pumpAndSettle(); // Espera la distribución.
        await tester.tap(
          find.text(historial ? 'HISTORIAL\nDE VENTAS' : 'NUEVA VENTA'),
        ); // Pulsa la tarjeta correspondiente.
        await tester.pumpAndSettle(); // Espera la navegación.
        expect(
          historial
              ? find.byType(PaginaVentasHistorial)
              : find.byType(PaginaCrearVenta),
          findsOneWidget,
        ); // Abre la página correcta.
        expect(
          tester.takeException(),
          isNull,
        ); // Exige ausencia de fallos visuales.
      },
    ); // Finaliza la comprobación de una tarjeta.
  } // Finaliza las tarjetas de Inicio.

  testWidgets(
    'el desplegable de cliente utiliza gris y elimina el tinte rosado',
    (tester) async {
      // Verifica el estilo del campo y del menú.
      await tester.pumpWidget(
        MaterialApp(
          home: PaginaCrearVenta(
            cargarClientes: () async => [],
            cargarProductos: () async => [],
          ),
        ),
      ); // Abre el registro sin conexión.
      await tester.pumpAndSettle(); // Espera los catálogos.
      final menu = tester
          .widgetList<MenuAnchor>(find.byType(MenuAnchor))
          .first; // Obtiene el selector de cliente.
      expect(
        menu.style!.backgroundColor!.resolve({}),
        const Color(0xFFE0E0E0),
      ); // Conserva el gris del proyecto.
      expect(
        menu.style!.surfaceTintColor!.resolve({}),
        Colors.transparent,
      ); // Elimina el tinte rosado del tema.
    },
  ); // Finaliza el estilo de selección.
} // Finaliza las verificaciones de navegación y presentación.
