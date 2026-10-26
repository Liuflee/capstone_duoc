import 'package:frenos_cerna/features/clientes/pagina_clientes.dart'; // Proporciona clientes controlados a las reservas.
import 'package:frenos_cerna/features/notificaciones/data/reservas_repository.dart'; // Simula la persistencia de reservas.
import 'package:frenos_cerna/features/notificaciones/presentation/vista_reservas.dart'; // Comprueba el flujo completo de reservas.
import 'package:frenos_cerna/features/inventario/pagina_edicion_producto.dart'; // Verifica que editar reutiliza el formulario sin eliminación.
import 'package:frenos_cerna/features/vehiculos/pagina_crear_vehiculo.dart'; // Comprueba el centro del diálogo respecto al contenido.
import 'package:frenos_cerna/features/inicio/pagina_inicio.dart'; // Comprueba las acciones por dispositivo.
import 'package:frenos_cerna/shared/widgets/panel_filtros.dart'; // Comprueba la alineación de los controles externos.
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart'; // Compara los extremos visibles de la tabla.
import 'package:flutter/material.dart'; // Construye los widgets tal como los usa la aplicación.
import 'package:flutter_test/flutter_test.dart'; // Protege las correcciones visuales solicitadas.
import 'package:frenos_cerna/features/inventario/pagina_inventario.dart'; // Comprueba el botón que tenía texto blanco.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart'; // Comprueba el área completa de la marca.
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart'; // Comprueba el borde continuo del menú.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart'; // Compara acciones e iconos de tabla.

class ReservasPrueba extends ReservasRepository {
  final filas = <
      Map<String,
          dynamic>>[]; // Conserva los registros entre vistas para simular Supabase.
  @override
  Future<List<Map<String, dynamic>>> listar({required bool listas}) async =>
      filas
          .where((fila) => fila['estado'] == (listas ? 'lista' : 'reservado'))
          .map((fila) => Map<String, dynamic>.from(fila))
          .toList();
  @override
  Future<void> reservar(String codigo, {required String rutCliente}) async {
    filas.add({
      'id': filas.length + 1,
      'codigo_producto': codigo.trim().toUpperCase(),
      'rut_cliente':
          rutCliente, // Conserva el destinatario de la reserva simulada.
      'estado': 'reservado',
    });
  } // Simula una reserva persistente.

  @override
  Future<void> marcarLista(Object id) async {
    filas.singleWhere((fila) => fila['id'] == id)['estado'] = 'lista';
  } // Conserva el registro al completar.
}

void main() {
  for (final ancho in [390.0, 1440.0]) {
    testWidgets(
      'reservar por código y mover a reservas listas con ancho $ancho',
      (tester) async {
        tester.view.physicalSize = Size(
          ancho,
          1000,
        ); // Comprueba móvil y escritorio.
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repositorio = ReservasPrueba(); // Aísla los registros reales.
        await tester.pumpWidget(
          MaterialApp(
            home: VistaReservas(
              reservados: false,
              repositorio: repositorio,
              cargarClientes: () async => [
                Cliente(
                  id: '123',
                  nombre: 'Cliente reserva',
                  numero: '456',
                  ultimaVenta: '',
                  vehiculo: '',
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('No hay productos reservados.'),
          findsOneWidget,
        ); // No muestra todos los productos del inventario.
        await tester.tap(find.text('RESERVAR PRODUCTO'));
        await tester.pumpAndSettle(); // Abre el diálogo de código.
        expect(
          tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
          Colors.white,
        ); // Conserva el fondo del proyecto.
        await tester.tap(find.text('RESERVAR'));
        await tester.pumpAndSettle(); // Intenta enviar sin código.
        expect(repositorio.filas, isEmpty); // Rechaza reservas vacías.
        await tester.enterText(find.byType(TextFormField), 'sp0-01223');
        await tester.tap(find.text('VINCULAR CLIENTE'));
        await tester.pumpAndSettle(); // Abre el selector sin perder el código.
        await tester.tap(find.text('CLIENTE EXISTENTE'));
        await tester.pumpAndSettle(); // Selecciona el flujo de búsqueda.
        await tester.ensureVisible(find.byTooltip('Vincular este cliente'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Vincular este cliente'));
        await tester.pumpAndSettle(); // Vincula el destinatario de la reserva.
        await tester.tap(find.text('RESERVAR'));
        await tester.pumpAndSettle(); // Guarda y refresca la tabla.
        expect(repositorio.filas.single['estado'], 'reservado');
        expect(
          tester
              .widget<TablaDatos>(find.byType(TablaDatos))
              .filas
              .single['codigo_producto'],
          'SP0-01223',
        ); // Muestra la reserva recién guardada.
        await tester.ensureVisible(find.byTooltip('Marcar reserva lista'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Marcar reserva lista'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONFIRMAR'));
        await tester.pumpAndSettle(); // Confirma el cambio de estado.
        expect(repositorio.filas, hasLength(1)); // No elimina registros.
        expect(repositorio.filas.single['estado'], 'lista');
        await tester.tap(find.text('RESERVAS LISTAS'));
        await tester.pumpAndSettle(); // Abre la segunda vista.
        expect(
          tester
              .widget<TablaDatos>(find.byType(TablaDatos))
              .filas
              .single['estado_visible'],
          'LISTA',
        );
        expect(
          find.text('REMOVER'),
          findsNothing,
        ); // No ofrece borrar reservas.
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'editar producto precarga el formulario y conserva categoría y calidad',
    (tester) async {
      tester.view.physicalSize = const Size(
        1440,
        1200,
      ); // Muestra los campos completos.
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final producto = Producto(
        id: 'SP0-01223',
        nombre: 'SP0-01223',
        codigoBarra: '789030',
        categoria: 'Pastillas',
        precio: 14000,
        cantidad: 7,
        tipoId: 1,
        calidadId: 10,
      ); // Define un registro existente.
      await tester.pumpWidget(
        MaterialApp(
          home: PaginaEdicionProducto(
            producto: producto,
            cargarCatalogos: () async => {
              'categorias': [
                {'id': 1, 'nombre_tipo': 'Pastillas'},
                {'id': 2, 'nombre_tipo': 'Discos'},
              ],
              'calidades': [
                {'id': 10, 'nombre_calidad': 'Cerámica'},
              ],
              'relaciones': [
                {'id_tipo': 1, 'id_calidad': 10},
              ],
            },
          ),
        ),
      );
      await tester
          .pumpAndSettle(); // Completa la carga de las opciones existentes.
      final campos =
          tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(campos.map((campo) => campo.controller!.text), [
        'SP0-01223',
        '14000',
        '7',
        '789030',
      ]); // Comprueba los datos y el orden de Añadir producto.
      expect(
        campos.first.enabled,
        isFalse,
      ); // Protege la clave referenciada por ventas.
      expect(
        tester
            .widget<DropdownButton<Object>>(
              find.byType(DropdownButton<Object>).first,
            )
            .value,
        1,
      ); // Precarga la categoría.
      expect(
        tester
            .widget<DropdownButton<Object>>(
              find.byType(DropdownButton<Object>).last,
            )
            .value,
        10,
      ); // Precarga la calidad vinculada.
      expect(
        find.text('ELIMINAR'),
        findsNothing,
      ); // Retira la acción de borrado.
      expect(
        find.text('GUARDAR CAMBIOS'),
        findsOneWidget,
      ); // Guarda en el mismo registro.
      expect(tester.takeException(), isNull);
    },
  );

  for (final ancho in [390.0, 1920.0]) {
    testWidgets(
      'vincular cliente se centra respecto al contenido con ancho $ancho',
      (tester) async {
        tester.view.physicalSize = Size(
          ancho,
          1080,
        ); // Comprueba celular y escritorio.
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(home: PaginaCrearVehiculo()),
        ); // Abre el formulario real.
        await tester.pumpAndSettle();
        final boton = find.text('VINCULAR CON CLIENTE');
        await tester.ensureVisible(boton); // Hace visible la acción en móvil.
        await tester.tap(boton);
        await tester.pumpAndSettle(); // Abre la ventana centrada.
        final centro = tester.getCenter(
          find.byKey(const ValueKey('dialogo_vincular_cliente')),
        ); // Mide únicamente la ventana visible.
        expect(
          centro.dx,
          closeTo(ancho * (ancho >= 700 ? 0.56 : 0.5), 0.01),
        ); // Excluye el doce por ciento del menú en escritorio.
        expect(
          centro.dy,
          closeTo(540, 0.01),
        ); // Conserva el centro vertical de la pantalla.
        expect(
          tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
          Colors.white,
        ); // Conserva el fondo blanco solicitado.
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final plataforma in [TargetPlatform.android, TargetPlatform.windows]) {
    testWidgets('Inicio ofrece escaneo o datos según $plataforma', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440,
          1000); // Mantiene el tamaño para verificar que la decisión dependa de la plataforma.
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: plataforma),
          routes: {'/data': (_) => const Scaffold(body: Text('DESTINO DATOS'))},
          home: const PaginaInicio(),
        ),
      ); // Reproduce Inicio con una ruta controlada.
      await tester.pumpAndSettle();
      final cartas = tester.widgetList<CartaNavegacion>(
        find.byType(CartaNavegacion),
      ); // Revisa las tarjetas reales.
      expect(
        cartas.singleWhere((carta) => carta.texto == 'DASHBOARD').alPresionar,
        isNull,
      ); // Deja la ruta del dashboard vacía.
      if (plataforma == TargetPlatform.android) {
        final escaneo = cartas.singleWhere(
          (carta) => carta.texto == 'ESCANEAR PRODUCTO',
        );
        expect(
          escaneo.icono,
          Icons.barcode_reader,
        ); // Conserva el escaneo de barras en celular.
        expect(
          escaneo.alPresionar,
          isNull,
        ); // Mantiene el escaneo pendiente de conectar.
        expect(find.text('DATOS'), findsNothing); // Evita duplicar accesos.
      } else {
        expect(find.text('ESCANEAR PRODUCTO'), findsNothing);
        await tester.tap(find.text('DATOS'));
        await tester
            .pumpAndSettle(); // Comprueba que Datos conserva su navegación.
        expect(find.text('DESTINO DATOS'), findsOneWidget);
      }
      expect(
        tester.takeException(),
        isNull,
      ); // Descarta errores de distribución.
    });
  }

  for (final ancho in [390.0, 1440.0]) {
    testWidgets(
      'buscador y filtros comparten los bordes de la tabla en $ancho',
      (tester) async {
        tester.view.physicalSize = Size(
          ancho,
          900,
        ); // Comprueba móvil y escritorio.
        tester.view.devicePixelRatio = 1; // Usa medidas lógicas reproducibles.
        addTearDown(tester.view.resetPhysicalSize); // Restablece el tamaño.
        addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PanelFiltros<String>(
                datos: const [
                  'A',
                  'B',
                ], // Ofrece dos valores para mostrar el filtro.
                camposBusqueda: [
                  (dato) => dato,
                ], // Conserva la búsqueda funcional.
                categorias: [
                  CategoriaFiltro<String>(
                    id: 'grupo',
                    etiqueta: 'GRUPO',
                    valor: (dato) => dato,
                  ),
                ], // Muestra una categoría real.
                child: (filas) => TablaDatos(
                  mostrarControles: false, // Utiliza el buscador del panel.
                  nombresColumnas: const ['CÓDIGO'],
                  camposColumnas: const ['codigo'],
                  anchosColumnas: const [1],
                  filas: [
                    for (final fila in filas) {'codigo': fila},
                  ], // Refleja los resultados filtrados.
                ),
              ),
            ),
          ),
        ); // Reproduce la composición compartida por las vistas.
        await tester.pumpAndSettle(); // Completa la distribución.
        final celda = find
            .ancestor(of: find.text('CÓDIGO'), matching: find.byType(Container))
            .first; // Localiza la cabecera visible.
        final tabla = tester.getRect(
          celda,
        ); // Excluye la reserva del desplazamiento.
        final buscador = tester.getRect(
          find.byType(CampoBusqueda),
        ); // Obtiene el buscador externo.
        expect(
          buscador.left,
          closeTo(tabla.left, 0.01),
        ); // Comprueba el borde izquierdo.
        expect(
          buscador.right,
          closeTo(tabla.right, 0.01),
        ); // Comprueba el borde derecho.
        expect(
          tester.getRect(find.text('GRUPO')).left,
          greaterThanOrEqualTo(tabla.left),
        ); // Conserva los filtros dentro del ancho visible.
        final contador = tester.getRect(
          find.text('2 DE 2'),
        ); // Respeta la distribución móvil original.
        expect(
          ancho < 560 ? contador.left : contador.right,
          closeTo(ancho < 560 ? tabla.left : tabla.right, 0.01),
        ); // Alinea el contador a la izquierda en móvil y a la derecha en escritorio.
        await tester.enterText(
          find.byType(TextField),
          'A',
        ); // Comprueba que la búsqueda se conserve.
        await tester.pumpAndSettle(); // Actualiza las filas.
        expect(
          find.text('1 DE 2'),
          findsOneWidget,
        ); // Mantiene el filtrado original.
        expect(tester.takeException(), isNull); // Descarta desbordamientos.
      },
    );
  }

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
      final decoracion = tester
          .widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(MenuLateral),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration as BoxDecoration; // Obtiene la superficie compartida.
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

  testWidgets('Añadir producto usa texto negro y el tamaño de Añadir cliente', (
    tester,
  ) async {
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
  }); // Finaliza la revisión del inventario.
} // Finaliza las pruebas de estilo.
