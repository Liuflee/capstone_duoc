import 'package:frenos_cerna/main.dart'; // Comprueba el área segura aplicada a todas las rutas.
import 'package:frenos_cerna/features/autenticacion/presentation/pagina_autenticacion.dart'; // Comprueba el regreso al login existente.
import 'package:flutter/material.dart'; // Construye el marco compartido de las páginas.
import 'package:flutter_test/flutter_test.dart'; // Comprueba alineación, navegación y visibilidad.
import 'package:frenos_cerna/shared/widgets/barra_superior.dart'; // Verifica la nueva barra común.
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart'; // Verifica el menú elevado y su cierre fijo.
import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart'; // Comprueba la ruta recuperada de vehículos.

void main() {
  testWidgets(
    'la barra superior respeta la barra de estado de Android en Inicio y otras rutas',
    (tester) async {
      tester.view.physicalSize = const Size(
        390,
        844,
      ); // Simula una pantalla Android con barra de estado.
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(
        top: 32,
      ); // Reserva la zona de hora y notificaciones.
      tester.view.viewPadding = const FakeViewPadding(top: 32);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpWidget(
        const MiAplicacion(),
      ); // Usa la configuración real de la aplicación.
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Entrar en modo de prueba'));
      await tester.tap(find.text('Entrar en modo de prueba'));
      await tester.pumpAndSettle(); // Abre Inicio sin una sesión real.
      expect(
        tester.getRect(find.byType(BarraSuperior)).top,
        closeTo(32, 0.01),
      ); // Impide solapar la barra del celular.
      final contexto = tester.element(find.byType(BarraSuperior));
      expect(
        MediaQuery.paddingOf(contexto).top,
        0,
      ); // Evita que otras páginas apliquen dos veces el margen superior.
      Navigator.of(contexto).pushNamed('/vehicles/new');
      await tester.pumpAndSettle(); // Comprueba una página que usa appBar.
      expect(
        tester.getRect(find.byType(BarraSuperior)).top,
        closeTo(32, 0.01),
      ); // Conserva el mismo borde seguro al navegar.
      expect(tester.takeException(), isNull);
    },
  );

  for (final salidaPersonalizada in [false, true]) {
    testWidgets(
      'cerrar sesión regresa al login y elimina el historial con callback $salidaPersonalizada',
      (tester) async {
        var cierres =
            0; // Comprueba la ejecución de la salida proporcionada por Inicio.
        final navegador =
            GlobalKey<
              NavigatorState
            >(); // Permite comprobar que no se pueda regresar.
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navegador,
            home: const Scaffold(body: Text('VISTA ANTERIOR')),
          ),
        ); // Conserva una ruta previa de la aplicación.
        navegador.currentState!.push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              body: SizedBox(
                height: 100,
                child: BarraSuperior(
                  tituloPagina: 'Clientes',
                  nombreUsuario: 'Nombre de prueba',
                  onCerrarSesion: salidaPersonalizada
                      ? () async {
                          cierres++;
                        }
                      : null,
                ),
              ),
            ),
          ),
        ); // Reproduce una vista con o sin callback de cierre.
        await tester.pumpAndSettle(); // Espera la navegación.
        expect(
          find.byTooltip('Cerrar sesión'),
          findsOneWidget,
        ); // Mantiene la salida en todas las barras.
        await tester.tap(
          find.byTooltip('Cerrar sesión'),
        ); // Ejecuta la salida compartida.
        await tester.pumpAndSettle(); // Completa el regreso al acceso.
        expect(
          find.byType(PaginaAutenticacion),
          findsOneWidget,
        ); // Muestra el login real.
        expect(
          navegador.currentState!.canPop(),
          isFalse,
        ); // No permite volver a páginas de la sesión anterior.
        expect(
          cierres,
          salidaPersonalizada ? 1 : 0,
        ); // Conserva la salida personalizada cuando corresponde.
        expect(
          tester.takeException(),
          isNull,
        ); // Descarta errores al reemplazar las rutas.
      },
    );
  }

  // Verifica los cambios comunes a todas las páginas.
  for (final tamano in [
    const Size(1920, 1080),
    const Size(1280, 720),
    const Size(800, 600),
    const Size(390, 844),
  ]) {
    // Comprueba ventanas grandes, pequeñas y móvil.
    testWidgets('el título se centra con el contenido en $tamano', (
      tester,
    ) async {
      // Distingue el centro del contenido del centro total de la ventana.
      tester.view.physicalSize = tamano; // Configura las dimensiones.
      tester.view.devicePixelRatio = 1; // Usa coordenadas lógicas.
      addTearDown(tester.view.resetPhysicalSize); // Restablece la pantalla.
      addTearDown(tester.view.resetDevicePixelRatio); // Restablece la escala.
      final escritorio =
          tamano.width >=
          700; // Comparte el punto de adaptación de las páginas.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: const Drawer(child: MenuLateral(activo: 'Clientes')),
            body: Column(
              children: [
                SizedBox(
                  height: tamano.height * 0.1,
                  child: BarraSuperior(
                    tituloPagina: 'Página Principal',
                    nombreUsuario: 'Usuario con nombre largo',
                    onCerrarSesion: () async {},
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (escritorio)
                        SizedBox(
                          width: tamano.width * 0.12,
                          child: const MenuLateral(activo: 'Página Principal'),
                        ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'CONTENIDO',
                            key: ValueKey('centro_contenido'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ); // Reproduce las mismas proporciones que Inicio.
      await tester.pumpAndSettle(); // Espera la composición completa.
      expect(
        tester.getCenter(find.byKey(const ValueKey('titulo_pagina'))).dx,
        closeTo(
          tester.getCenter(find.byKey(const ValueKey('centro_contenido'))).dx,
          0.01,
        ),
      ); // Exige que el título siga el centro del contenido.
      if (escritorio) {
        // Comprueba el botón de salida desde el primer dibujo.
        final cierre = tester.getRect(
          find.byKey(const ValueKey('cerrar_aplicacion')),
        ); // Obtiene los límites del área pulsable.
        expect(
          cierre.bottom,
          lessThanOrEqualTo(tamano.height),
        ); // Evita que aparezca cortado debajo de la ventana.
        expect(
          cierre.top,
          greaterThan(tamano.height * 0.1),
        ); // Mantiene el cierre dentro del menú.
      } else {
        // Comprueba que el menú móvil conserva su apertura.
        await tester.tap(
          find.byTooltip('Abrir menú'),
        ); // Abre el menú desde la barra.
        await tester.pumpAndSettle(); // Espera el desplegado del Drawer.
        expect(
          find.text('Vehículos'),
          findsOneWidget,
        ); // Conserva el nuevo acceso en Android.
        expect(
          tester
              .getRect(find.byKey(const ValueKey('cerrar_aplicacion')))
              .bottom,
          lessThanOrEqualTo(tamano.height),
        ); // Mantiene visible la salida móvil.
      } // Finaliza las comprobaciones de plataforma.
      expect(
        tester.takeException(),
        isNull,
      ); // Exige ausencia de desbordamientos.
    }); // Finaliza una dimensión de pantalla.
  } // Finaliza las dimensiones.

  for (final alto in [280.0, 420.0, 720.0]) {
    // Comprueba ventanas con poca altura disponible.
    testWidgets('el cierre permanece fijo con menú desplazable de alto $alto', (
      tester,
    ) async {
      // Reproduce el problema del botón visible a medias.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: SizedBox(
                  width: 150,
                  height: alto,
                  child: const MenuLateral(activo: 'Clientes'),
                ),
              ),
            ),
          ),
        ),
      ); // Comprueba también texto ampliado.
      await tester.pumpAndSettle(); // Espera la distribución.
      final antes = tester.getRect(
        find.byKey(const ValueKey('cerrar_aplicacion')),
      ); // Conserva la posición inicial del cierre.
      expect(
        antes.bottom,
        lessThanOrEqualTo(alto),
      ); // Mantiene todo el botón dentro de la altura disponible.
      expect(
        antes.top,
        greaterThanOrEqualTo(0),
      ); // Evita cortar el botón por arriba.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -250),
      ); // Desplaza únicamente las opciones.
      await tester.pumpAndSettle(); // Espera el final del desplazamiento.
      expect(
        tester.getRect(find.byKey(const ValueKey('cerrar_aplicacion'))),
        antes,
      ); // El cierre no se desplaza con la lista.
      final superficie = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MenuLateral),
              matching: find.byType(DecoratedBox),
            )
            .first,
      ); // Obtiene la decoración del menú compartido.
      expect(
        (superficie.decoration as BoxDecoration).boxShadow!.single.offset.dx,
        greaterThan(0),
      ); // Proyecta la sombra hacia el contenido.
      expect(
        tester.takeException(),
        isNull,
      ); // Exige ausencia de errores de distribución.
    }); // Finaliza una altura de menú.
  } // Finaliza las alturas.

  testWidgets(
    'Vehículos aparece debajo de Clientes y abre el historial existente',
    (tester) async {
      // Comprueba posición y navegación recuperada.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 180, child: MenuLateral(activo: 'Clientes')),
          ),
        ),
      ); // Construye el menú real.
      await tester.pumpAndSettle(); // Espera la disposición de opciones.
      expect(
        tester.getTopLeft(find.text('Vehículos')).dy,
        greaterThan(tester.getTopLeft(find.text('Clientes')).dy),
      ); // Coloca el nuevo acceso después de Clientes.
      expect(
        tester.getTopLeft(find.text('Vehículos')).dy,
        lessThan(tester.getTopLeft(find.text('Perfil')).dy),
      ); // Lo mantiene antes de Perfil.
      await tester.tap(find.text('Vehículos')); // Abre el listado de vehículos.
      await tester.pumpAndSettle(); // Espera la navegación y la consulta.
      expect(
        find.byType(PaginaVehiculos),
        findsOneWidget,
      ); // Reutiliza la página del anterior historial de vehículos.
      expect(
        tester.takeException(),
        isNull,
      ); // Exige una navegación sin errores.
    },
  ); // Finaliza la comprobación del nuevo acceso.
} // Finaliza las pruebas compartidas.
