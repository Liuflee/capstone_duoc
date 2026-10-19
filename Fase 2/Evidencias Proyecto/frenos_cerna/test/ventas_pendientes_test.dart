import 'package:frenos_cerna/shared/widgets/panel_filtros.dart'; // Compara el título con el centro del buscador alineado a la tabla.
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart'; // Proporciona clientes al registro real de ventas.

import 'dart:async'; // Controla las confirmaciones simultáneas de prueba.
import 'dart:convert'; // Comprueba la persistencia del estado de envío.

import 'package:flutter/material.dart'; // Construye las vistas reales.
import 'package:flutter_test/flutter_test.dart'; // Verifica el flujo sin escribir en Supabase.
import 'package:shared_preferences/shared_preferences.dart'; // Simula el almacenamiento del dispositivo.
import 'package:supabase_flutter/supabase_flutter.dart'; // Simula rechazos explícitos del servidor.
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart'; // Verifica borradores y confirmaciones.
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart'; // Proporciona ventas cerradas controladas.
import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart'; // Comprueba registro y edición locales.
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta.dart'; // Distingue el historial cerrado.
import 'package:frenos_cerna/features/ventas/presentation/pagina_detalle_venta_pendiente.dart'; // Distingue el historial pendiente.
import 'package:frenos_cerna/features/ventas/presentation/pagina_ventas.dart'; // Verifica estados y rutas de la lupa.
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart'; // Comprueba las filas visibles.

VentaPendiente borrador({
  String id = 'local-1',
  int revision = 0,
  int cantidad = 2,
}) => VentaPendiente(
  id: id,
  rutCliente: '123',
  nombreCliente: 'Cliente pendiente',
  fonoCliente: '456',
  patente: 'ABCD12',
  revision: revision,
  articulos: [
    ArticuloVentaPendiente(
      codigo: '10',
      nombre: 'Freno',
      categoria: 'Frenos',
      precio: 1000,
      cantidad: cantidad,
      stock: 5,
    ),
  ],
); // Conserva un borrador repetible.

void main() {
  // Inicia la verificación del ciclo de venta.
  TestWidgetsFlutterBinding.ensureInitialized(); // Habilita el almacenamiento simulado.
  setUp(
    () => SharedPreferences.setMockInitialValues({}),
  ); // Aísla el catálogo de cada prueba.

  test('recuperar tras revisión conserva la venta y permite un nuevo intento explícito', () async {
    var fallar = true; // Simula una respuesta incierta inicial.
    final repositorio = VentasPendientesRepository(
      clave: 'recuperar',
      registrar: (_) async {
        if (fallar) throw TimeoutException('Respuesta perdida');
        return '99';
      },
    );
    await repositorio.guardar(borrador()); // Conserva el borrador.
    await expectLater(
      repositorio.confirmarPago('local-1'),
      throwsStateError,
    ); // Bloquea el resultado desconocido.
    await repositorio.recuperarTrasRevision(
      'local-1',
    ); // Representa la revisión manual explícita.
    expect(
      await repositorio.requiereRevision('local-1'),
      isFalse,
    ); // Habilita el reintento.
    expect(
      (await repositorio.obtenerTodas()).single.total,
      2000,
    ); // No pierde artículos.
    fallar = false; // Simula haber corregido la configuración.
    expect(
      await repositorio.confirmarPago('local-1'),
      '99',
    ); // Confirma una sola vez.
    await expectLater(
      repositorio.recuperarTrasRevision('local-1'),
      throwsStateError,
    ); // Nunca reabre un pago confirmado.
  });
  for (final codigo in ['PGRST202', 'PGRST203', '42804', '23505']) {
    test(
      'un rechazo $codigo conserva el motivo y permite corregir sin bloqueo incierto',
      () async {
        final repositorio = VentasPendientesRepository(
          clave: 'rechazo',
          registrar: (_) async => throw PostgrestException(
            message: 'Configuración SQL incorrecta',
            code: codigo,
          ),
        ); // Simula un rechazo previo o una transacción revertida.
        await repositorio.guardar(borrador()); // Conserva la venta local.
        await expectLater(
          repositorio.confirmarPago('local-1'),
          throwsA(isA<PostgrestException>()),
        ); // Presenta el error original.
        expect(
          await repositorio.requiereRevision('local-1'),
          isFalse,
        ); // No bloquea cuando se sabe que no se guardó.
        expect(
          await repositorio.errorConfirmacion('local-1'),
          contains(codigo),
        ); // Conserva el código para el diagnóstico.
      },
    );
  }
  test('un error del intermediario no habilita un segundo envío', () async {
    // Distingue un rechazo de stock de una respuesta incierta.
    var envios = 0; // Cuenta solicitudes.
    final repositorio = VentasPendientesRepository(
      clave: 'prueba',
      registrar: (_) async {
        envios++;
        throw const PostgrestException(
          message: 'Respuesta del servidor no disponible',
          code: '502',
        );
      },
    ); // Simula un fallo de intermediario.
    await repositorio.guardar(borrador()); // Guarda antes de confirmar.
    await expectLater(
      repositorio.confirmarPago('local-1'),
      throwsStateError,
    ); // No presupone que la transacción fue rechazada.
    await expectLater(
      repositorio.confirmarPago('local-1'),
      throwsStateError,
    ); // Bloquea el reenvío incierto.
    expect(envios, 1); // Evita crear la misma venta dos veces.
  }); // Finaliza la protección del intermediario.

  test('si falla la persistencia posterior al pago conserva el comprobante y no repite la transacción', () async {
    // Protege la confirmación remota ante errores locales.
    var accesos = 0; // Identifica la escritura posterior al pago.
    var envios = 0; // Cuenta transacciones remotas.
    final almacen = await SharedPreferences.getInstance(); // Conserva un almacenamiento controlado.
    final repositorio = VentasPendientesRepository(
      clave: 'prueba',
      preferencias: () async {
        accesos++;
        if (accesos == 6) {
          throw StateError('No se pudo escribir el comprobante');
        }
        return almacen;
      },
      registrar: (_) async {
        envios++;
        return '99';
      },
    ); // Simula un fallo local después del éxito remoto.
    await repositorio.guardar(borrador()); // Persiste el borrador.
    await expectLater(
      repositorio.confirmarPago('local-1'),
      throwsStateError,
    ); // Propaga la escritura fallida.
    expect(
      await repositorio.confirmarPago('local-1'),
      '99',
    ); // Reutiliza el comprobante recibido.
    expect(envios, 1); // No vuelve a descontar stock.
    expect(
      await repositorio.obtenerTodas(),
      isEmpty,
    ); // Finaliza la transición local.
  }); // Finaliza la recuperación de comprobantes.

  testWidgets('registrar una nueva venta solo crea una pendiente local', (
    tester,
  ) async {
    // Comprueba el botón solicitado por el usuario.
    tester.view.physicalSize = const Size(
      1440,
      1000,
    ); // Usa una distribución de escritorio.
    tester.view.devicePixelRatio = 1; // Conserva las coordenadas lógicas.
    addTearDown(tester.view.resetPhysicalSize); // Restablece la pantalla.
    addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
    var envios = 0; // Detecta escrituras remotas indebidas.
    final repositorio = VentasPendientesRepository(
      clave: 'prueba',
      registrar: (_) async {
        envios++;
        return '99';
      },
    ); // Intercepta la confirmación remota.
    final cliente = Cliente(
      id: '123',
      nombre: 'Cliente pendiente',
      numero: '456',
      ultimaVenta: '',
      vehiculo: '',
    ); // Proporciona un cliente existente.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaginaCrearVenta(
                    repositorioPendientes: repositorio,
                    cargarClientes: () async => [cliente],
                    cargarProductos: () async => [
                      ProductoVenta(
                        id: '10',
                        nombre: 'Freno',
                        categoria: 'Frenos',
                        precio: 1000,
                        stock: 5,
                      ),
                    ],
                  ),
                ),
              ),
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
    ); // Abre el formulario real con datos controlados.
    await tester.tap(find.text('ABRIR')); // Inicia la venta.
    await tester.pumpAndSettle(); // Espera los catálogos.
    await tester.tap(find.text('SELECCIONAR CLIENTE')); // Abre el desplegable.
    await tester.pumpAndSettle(); // Espera los resultados.
    await tester.tap(
      find.text('Cliente pendiente · RUT: 123'),
    ); // Selecciona el cliente real del catálogo.
    await tester.pumpAndSettle(); // Cierra el menú.
    final botonAgregar = find
        .ancestor(
          of: find.text('AÑADIR NUEVO PRODUCTO'),
          matching: find.byType(ElevatedButton),
        )
        .first; // Localiza el borde real del botón.
    final ultimaCabecera = find
        .ancestor(of: find.text('REMOVER'), matching: find.byType(Container))
        .first; // Localiza el borde derecho de la tabla.
    expect(
      tester.getRect(botonAgregar).right,
      closeTo(tester.getRect(ultimaCabecera).right, 0.01),
    ); // Comprueba la alineación antes de abrir el selector.
    final botonVolver = find
        .ancestor(
          of: find.text('VOLVER A VENTAS'),
          matching: find.byType(ElevatedButton),
        )
        .first; // Compara las acciones superiores de ambas columnas.
    expect(
      tester.getRect(botonAgregar).top,
      closeTo(tester.getRect(botonVolver).top, 0.01),
    ); // Mantiene los botones a la misma altura.
    final campoCliente = find
        .ancestor(
          of: find.text('CLIENTE'),
          matching: find.byType(InputDecorator),
        )
        .first; // Obtiene el selector de cliente.
    expect(
      tester.getRect(campoCliente).top,
      closeTo(tester.getRect(find.byType(CampoBusqueda)).top, 0.01),
    ); // Alinea el cliente con la búsqueda de productos.
    await tester.tap(find.text('AÑADIR NUEVO PRODUCTO')); // Abre el inventario.
    await tester.pumpAndSettle(); // Espera la tabla superpuesta.
    await tester.tap(
      find.byTooltip('Añadir al carrito'),
    ); // Selecciona una unidad.
    await tester.pumpAndSettle(); // Actualiza el carrito.
    await tester.tap(find.byTooltip('Cerrar selección')); // Regresa a la venta.
    await tester.pumpAndSettle(); // Espera el cierre.
    await tester.tap(
      find.text('REGISTRAR VENTA'),
    ); // Guarda el borrador con el botón existente.
    await tester.pumpAndSettle(); // Espera la persistencia y el regreso.
    final venta =
        (await repositorio.obtenerTodas()).single; // Recupera la venta local.
    expect(venta.articulos.single.cantidad, 1); // Conserva los artículos.
    expect(venta.rutCliente, '123'); // Conserva el cliente.
    expect(envios, 0); // No crea venta ni descuenta stock en Supabase.
    expect(find.text('ABRIR'), findsOneWidget); // Regresa a la vista anterior.
    expect(tester.takeException(), isNull); // Exige ausencia de errores.
  }); // Finaliza el registro de pendientes.

  testWidgets(
    'confirmar pago pide confirmación y abre el historial cerrado sin acciones de edición',
    (tester) async {
      // Verifica el paso definitivo del flujo.
      tester.view.physicalSize = const Size(
        1440,
        1000,
      ); // Conserva las acciones visibles.
      tester.view.devicePixelRatio = 1; // Usa coordenadas lógicas.
      addTearDown(tester.view.resetPhysicalSize); // Restablece la pantalla.
      addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
      var envios = 0; // Cuenta escrituras remotas.
      final repositorio = VentasPendientesRepository(
        clave: 'prueba',
        registrar: (_) async {
          envios++;
          return '99';
        },
      ); // Simula el cierre sin usar la base real.
      await repositorio.guardar(borrador()); // Prepara una venta local.
      await tester.pumpWidget(
        MaterialApp(
          home: PaginaDetalleVentaPendiente(
            venta: (await repositorio.obtenerTodas()).single,
            repositorio: repositorio,
          ),
        ),
      ); // Abre el historial pendiente.
      await tester.pumpAndSettle(); // Comprueba el estado persistido.
      await tester.ensureVisible(
        find.text('CONFIRMAR PAGO'),
      ); // Hace visible la acción.
      await tester.tap(find.text('CONFIRMAR PAGO')); // Solicita concretar.
      await tester.pumpAndSettle(); // Espera la confirmación.
      await tester.tap(find.text('CANCELAR')); // Cancela el cierre.
      await tester.pumpAndSettle(); // Vuelve al detalle local.
      expect(envios, 0); // No envía la venta al cancelar.
      expect(
        await repositorio.obtenerTodas(),
        hasLength(1),
      ); // Mantiene la pendiente.
      await tester.tap(
        find.text('CONFIRMAR PAGO'),
      ); // Solicita concretar de nuevo.
      await tester.pumpAndSettle(); // Espera el diálogo.
      await tester.tap(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.text('CONFIRMAR PAGO'),
            )
            .last,
      ); // Confirma explícitamente el pago.
      await tester.pumpAndSettle(); // Espera el cierre y la navegación.
      expect(envios, 1); // Envía exactamente una transacción.
      expect(
        await repositorio.obtenerTodas(),
        isEmpty,
      ); // Retira el borrador del catálogo pendiente.
      expect(
        find.byType(PaginaDetalleVentaPendiente),
        findsNothing,
      ); // Cierra el historial pendiente.
      expect(
        tester
            .widget<PaginaDetalleVenta>(find.byType(PaginaDetalleVenta))
            .idVenta,
        '99',
      ); // Abre el registro real devuelto por el servidor.
      expect(
        find.text('EDITAR VENTA'),
        findsNothing,
      ); // Impide editar la venta ya concretada.
      expect(
        find.text('CONFIRMAR PAGO'),
        findsNothing,
      ); // Impide repetir el pago desde el historial.
      expect(tester.takeException(), isNull); // Comprueba la transición visual.
    },
  ); // Finaliza la confirmación de pago.

  test(
    'guardar persiste localmente y editar conserva la identidad sin enviar',
    () async {
      // Comprueba la separación entre preparar y concretar.
      var envios = 0; // Cuenta las escrituras remotas simuladas.
      final repositorio = VentasPendientesRepository(
        clave: 'prueba',
        registrar: (_) async {
          envios++;
          return '99';
        },
      ); // Intercepta cualquier envío accidental.
      await repositorio.guardar(borrador()); // Guarda el registro inicial.
      expect(envios, 0); // Impide enviar la venta antes de pagar.
      final reiniciado = VentasPendientesRepository(
        clave: 'prueba',
      ); // Simula volver a abrir la aplicación.
      final restaurada = (await reiniciado.obtenerTodas())
          .single; // Recupera cliente, patente y cantidades.
      expect(restaurada.total, 2000); // Conserva el total local.
      expect(restaurada.patente, 'ABCD12'); // Conserva el vehículo.
      expect(restaurada.rutCliente, '123'); // Conserva el cliente.
      await repositorio.guardar(
        borrador(revision: restaurada.revision, cantidad: 1),
      ); // Modifica el mismo registro.
      expect(
        (await reiniciado.obtenerTodas()).single.total,
        1000,
      ); // Persiste la edición sin duplicar la venta.
      await expectLater(
        repositorio.guardar(borrador(revision: restaurada.revision)),
        throwsStateError,
      ); // Impide sobrescribir una edición reciente.
      expect(envios, 0); // Editar tampoco ejecuta la transacción remota.
    },
  ); // Finaliza la comprobación de persistencia.

  test(
    'confirmar dos veces envía una vez y conserva el comprobante al reiniciar',
    () async {
      // Evita duplicados por clic repetido.
      var envios = 0; // Cuenta solicitudes remotas.
      final respuesta =
          Completer<String>(); // Mantiene una confirmación en curso.
      final repositorio = VentasPendientesRepository(
        clave: 'prueba',
        registrar: (_) {
          envios++;
          return respuesta.future;
        },
      ); // Simula una conexión lenta.
      await repositorio.guardar(borrador()); // Prepara la venta local.
      final primera = repositorio.confirmarPago('local-1'); // Solicita el pago.
      final repetida = repositorio.confirmarPago(
        'local-1',
      ); // Simula un segundo clic.
      respuesta.complete('99'); // Confirma el registro remoto.
      expect(await primera, '99'); // Devuelve el identificador real.
      expect(await repetida, '99'); // Comparte el resultado en curso.
      expect(envios, 1); // Exige una única transacción de stock.
      expect(
        await repositorio.obtenerTodas(),
        isEmpty,
      ); // Retira la venta de pendientes.
      final reiniciado = VentasPendientesRepository(
        clave: 'prueba',
        registrar: (_) async {
          envios++;
          return '100';
        },
      ); // Simula reiniciar después del pago.
      expect(
        await reiniciado.confirmarPago('local-1'),
        '99',
      ); // Recupera el comprobante guardado.
      expect(envios, 1); // No vuelve a crear la venta.
      await expectLater(
        reiniciado.guardar(borrador(revision: 1)),
        throwsStateError,
      ); // Impide editar una venta cerrada.
    },
  ); // Finaliza la protección de pago.

  test(
    'un rechazo de stock conserva el borrador y permite corregirlo',
    () async {
      // Conserva la venta ante errores de negocio.
      var rechazar = true; // Simula un cambio de disponibilidad.
      final repositorio = VentasPendientesRepository(
        clave: 'prueba',
        registrar: (_) async {
          if (rechazar) {
            throw const PostgrestException(
              message: 'Stock insuficiente',
              code: 'P0001',
            );
          }
          return '99';
        },
      ); // Simula la transacción existente.
      await repositorio.guardar(
        borrador(),
      ); // Guarda la venta sin reservar stock.
      await expectLater(
        repositorio.confirmarPago('local-1'),
        throwsA(isA<PostgrestException>()),
      ); // Conserva el rechazo explícito del servidor.
      expect(
        (await repositorio.obtenerTodas()).single.total,
        2000,
      ); // Conserva artículos y precio local.
      expect(
        await repositorio.requiereRevision('local-1'),
        isFalse,
      ); // Un rechazo explícito permite corregir.
      rechazar = false; // Simula corregir la disponibilidad.
      expect(
        await repositorio.confirmarPago('local-1'),
        '99',
      ); // Permite concretar después de corregir.
    },
  ); // Finaliza la recuperación de errores.

  test('una desconexión conserva el envío y bloquea duplicados incluso al reiniciar', () async {
    // Protege ventas cuyo resultado remoto se desconoce.
    var envios = 0; // Cuenta intentos de confirmación.
    final repositorio = VentasPendientesRepository(
      clave: 'prueba',
      registrar: (_) async {
        envios++;
        throw TimeoutException('Respuesta perdida');
      },
    ); // Simula perder la respuesta después del envío.
    await repositorio.guardar(borrador()); // Conserva el registro inicial.
    await expectLater(
      repositorio.confirmarPago('local-1'),
      throwsStateError,
    ); // Informa que debe revisarse el historial.
    final reiniciado = VentasPendientesRepository(
      clave: 'prueba',
      registrar: (_) async {
        envios++;
        return '100';
      },
    ); // Simula volver a abrir la aplicación.
    expect(
      await reiniciado.requiereRevision('local-1'),
      isTrue,
    ); // Recupera el bloqueo persistente.
    expect(
      (await reiniciado.obtenerTodas()).single.articulos.single.cantidad,
      2,
    ); // Conserva todos los datos de la venta.
    await expectLater(
      reiniciado.confirmarPago('local-1'),
      throwsStateError,
    ); // No reenvía automáticamente una venta incierta.
    expect(envios, 1); // Impide el descuento de stock duplicado.
  }); // Finaliza la protección de desconexión.

  test(
    'guardar simultáneamente no pierde otras ventas ni mezcla usuarios',
    () async {
      // Comprueba escrituras locales y separación de cuentas.
      final repositorio = VentasPendientesRepository(
        clave: 'usuario-a',
      ); // Representa la primera cuenta.
      await Future.wait([
        repositorio.guardar(borrador(id: 'primera')),
        repositorio.guardar(borrador(id: 'segunda')),
      ]); // Guarda dos ventas en la misma cola.
      expect(
        await repositorio.obtenerTodas(),
        hasLength(2),
      ); // Conserva ambos registros.
      expect(
        await VentasPendientesRepository(clave: 'usuario-b').obtenerTodas(),
        isEmpty,
      ); // No muestra borradores de otra cuenta.
      final almacen = await SharedPreferences.getInstance(); // Inspecciona la persistencia sin credenciales.
      expect(
        (jsonDecode(almacen.getString('usuario-a')!) as List).every(
          (fila) => fila['estado'] == 'pendiente',
        ),
        isTrue,
      ); // No confunde borradores con ventas cerradas.
    },
  ); // Finaliza la verificación del almacenamiento.

  for (final tamano in [const Size(1440, 1000), const Size(390, 844)]) {
    // Verifica las dos plataformas objetivo.
    testWidgets(
      'Ventas filtra estados y la lupa distingue pendiente de cerrada en $tamano',
      (tester) async {
        // Comprueba filtro y navegación reales.
        tester.view.physicalSize = tamano; // Define el tamaño de pantalla.
        tester.view.devicePixelRatio = 1; // Conserva coordenadas lógicas.
        addTearDown(tester.view.resetPhysicalSize); // Restablece el entorno.
        addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
        final repositorio = VentasPendientesRepository(
          clave: 'prueba',
        ); // Conserva un catálogo aislado.
        await repositorio.guardar(borrador()); // Prepara la venta sin pago.
        final cerrada = VentaRegistro(
          id: '99',
          clienteNombre: 'Cliente cerrado',
          fechaRegistro: DateTime.now(), // Sitúa la venta controlada en el día de la prueba.
          vehiculoNombre: 'Sin vehículo',
          productosResumen: 'Otro producto',
          total: 3000,
          fecha: 'No registrada',
          items: [],
        ); // Simula únicamente el historial concretado.
        await tester.pumpWidget(
          MaterialApp(
            home: PaginaVentas(
              repositorioPendientes: repositorio,
              cargarVentas: () async => [cerrada],
            ),
          ),
        ); // Abre la lista real con ambos estados.
        await tester.pumpAndSettle(); // Espera el catálogo combinado.
        expect(
          tester.widget<TablaDatos>(find.byType(TablaDatos)).filas,
          hasLength(2),
        ); // Muestra ambos estados sin un filtro inicial.
        expect(
          find.text('AGREGAR VENTA'),
          findsNothing,
        ); // Retira la acción de la pestaña diaria.
        expect(
          tester.getCenter(find.text('VENTAS')).dx,
          closeTo(tester.getCenter(find.byType(CampoBusqueda)).dx, 0.01),
        ); // Verifica el centro respecto al ancho visible de la tabla en móvil y escritorio.
        await tester.tap(
          find.byTooltip('ESTADO'),
        ); // Abre el chip de estado del panel.
        await tester.pumpAndSettle(); // Espera el menú.
        await tester.tap(
          find.text('VENTAS PENDIENTES'),
        ); // Filtra las ventas locales.
        await tester.pumpAndSettle(); // Aplica el filtro.
        expect(
          tester
              .widget<TablaDatos>(find.byType(TablaDatos))
              .filas
              .single['cliente'],
          'Cliente pendiente',
        ); // Excluye ventas cerradas.
        await tester.tapAt(
          Offset(tamano.width - 5, tamano.height - 5),
        ); // Cierra fuera del menú sin cambiar el filtro.
        await tester.pumpAndSettle(); // Espera el cierre.
        await tester.tap(
          find.byTooltip('Ver venta'),
        ); // Abre el detalle mediante la lupa.
        await tester.pumpAndSettle(); // Recupera el borrador local.
        expect(
          find.byType(PaginaDetalleVentaPendiente),
          findsOneWidget,
        ); // Usa el historial pendiente.
        expect(
          find.text('EDITAR VENTA'),
          findsOneWidget,
        ); // Ofrece edición local.
        expect(
          find.text('CONFIRMAR PAGO'),
          findsOneWidget,
        ); // Ofrece concretar la venta.
        expect(
          tester.takeException(),
          isNull,
        ); // Exige ausencia de desbordamientos.
        Navigator.of(tester.element(find.byType(PaginaDetalleVentaPendiente)))
            .pop(); // Regresa a Ventas.
        await tester.pumpAndSettle(); // Refresca los datos.
        await tester.tap(find.byTooltip('ESTADO')); // Abre el filtro de nuevo.
        await tester.pumpAndSettle(); // Espera el menú.
        await tester.tap(
          find.text('VENTAS PENDIENTES'),
        ); // Mantiene la única selección al pulsarla otra vez.
        await tester.pumpAndSettle(); // Vuelve a mostrar ambas ventas.
        await tester.tap(
          find.text('VENTAS CERRADAS'),
        ); // Filtra el historial remoto.
        await tester.pumpAndSettle(); // Aplica el estado.
        expect(
          tester
              .widget<TablaDatos>(find.byType(TablaDatos))
              .filas
              .single['cliente'],
          'Cliente cerrado',
        ); // Excluye las pendientes.
        await tester.tapAt(
          Offset(tamano.width - 5, tamano.height - 5),
        ); // Cierra el filtro pulsando fuera.
        await tester.pumpAndSettle(); // Espera el cierre.
        await tester.tap(find.byTooltip('Ver venta')); // Abre la venta cerrada.
        await tester.pumpAndSettle(); // Espera el detalle del historial.
        expect(
          find.byType(PaginaDetalleVentaPendiente),
          findsNothing,
        ); // No permite editar una venta concretada.
        expect(
          find.byType(PaginaDetalleVenta),
          findsOneWidget,
        ); // Usa el historial existente.
        expect(
          find.text('EDITAR VENTA'),
          findsNothing,
        ); // Conserva la venta cerrada sin edición.
        expect(
          find.text('CONFIRMAR PAGO'),
          findsNothing,
        ); // No permite confirmar dos veces desde el historial.
        expect(
          tester.takeException(),
          isNull,
        ); // Comprueba la distribución móvil y de escritorio.
      },
    ); // Finaliza la comprobación de navegación por estado.
  } // Finaliza los tamaños de pantalla.

  testWidgets(
    'editar una pendiente restaura datos y quitar una unidad solo modifica el borrador',
    (tester) async {
      // Verifica edición y conservación del identificador.
      tester.view.physicalSize = const Size(
        1440,
        1000,
      ); // Conserva visible el formulario completo.
      tester.view.devicePixelRatio = 1; // Usa coordenadas lógicas.
      addTearDown(tester.view.resetPhysicalSize); // Restablece la pantalla.
      addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
      var envios = 0; // Detecta cualquier escritura remota inesperada.
      final repositorio = VentasPendientesRepository(
        clave: 'prueba',
        registrar: (_) async {
          envios++;
          return '99';
        },
      ); // Intercepta el cierre de venta.
      await repositorio.guardar(
        borrador(),
      ); // Prepara una venta de dos unidades.
      final venta = (await repositorio.obtenerTodas())
          .single; // Obtiene su versión persistida.
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaginaCrearVenta(
                      pendiente: venta,
                      repositorioPendientes: repositorio,
                      cargarProductos: () async => [],
                      cargarClientes: () async => [],
                    ),
                  ),
                ),
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
      ); // Mantiene una ruta de regreso tras guardar.
      await tester.tap(find.text('ABRIR')); // Abre la edición real.
      await tester.pumpAndSettle(); // Restaura el borrador.
      expect(
        find.text('Cliente pendiente · RUT: 123'),
        findsOneWidget,
      ); // Conserva el cliente seleccionado.
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'ABCD12',
      ); // Conserva la patente.
      await tester.tap(
        find.byIcon(Icons.cancel_outlined).first,
      ); // Quita una unidad de la venta abierta.
      await tester.pumpAndSettle(); // Actualiza el carrito.
      await tester.tap(
        find.text('GUARDAR CAMBIOS'),
      ); // Persiste la edición local.
      await tester.pumpAndSettle(); // Regresa a la ruta anterior.
      final editada = (await repositorio.obtenerTodas())
          .single; // Recupera el resultado guardado.
      expect(editada.id, venta.id); // No crea una segunda venta al editar.
      expect(
        editada.articulos.single.cantidad,
        1,
      ); // Guarda la unidad restante.
      expect(envios, 0); // No envía ni descuenta stock durante la edición.
      expect(tester.takeException(), isNull); // Exige ausencia de errores.
    },
  ); // Finaliza la prueba de edición.
} // Finaliza las pruebas de pendientes.
