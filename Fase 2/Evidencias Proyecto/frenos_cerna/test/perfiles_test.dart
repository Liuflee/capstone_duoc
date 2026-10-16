import 'package:flutter/material.dart'; // Construye las vistas reales.
import 'package:flutter_test/flutter_test.dart'; // Verifica funciones y permisos sin crear ni borrar cuentas reales.
import 'package:frenos_cerna/features/perfil/data/perfiles_repository.dart'; // Proporciona perfiles controlados.
import 'package:frenos_cerna/features/perfil/pagina_perfil.dart'; // Verifica las secciones y los accesos.
import 'package:frenos_cerna/features/perfil/pagina_gestion_perfil.dart'; // Verifica las cuatro vistas de cada sección.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart'; // Comprueba la referencia de dimensiones.

class RepositorioPerfilesPrueba extends PerfilesRepository {
  // Simula operaciones conservando la identidad del solicitante.
  PerfilGestion? actual = const PerfilGestion(
    id: 'sesion',
    nombre: 'Dueño actual',
    tipo: TipoPerfil.dueno,
    correo: 'dueno@example.com',
  ); // Mantiene la sesión inicial.
  final perfiles = <PerfilGestion>[
    const PerfilGestion(
      id: 'otro-dueno',
      nombre: 'Otro dueño',
      tipo: TipoPerfil.dueno,
    ),
    const PerfilGestion(
      id: 'mecanico',
      nombre: 'Mecánico registrado',
      tipo: TipoPerfil.mecanico,
    ),
  ]; // Define personas de ambas secciones.
  int creaciones = 0,
      ediciones = 0,
      eliminaciones = 0; // Cuenta las operaciones que las vistas solicitan.
  @override // Devuelve la misma sesión al crear otros usuarios.
  Future<PerfilGestion?> obtenerActual() async => actual; // No reemplaza la identidad del dueño.
  @override // Conserva la separación por rol.
  Future<List<PerfilGestion>> listar(TipoPerfil tipo) async =>
      perfiles.where((perfil) => perfil.tipo == tipo).toList(); // Simula el catálogo visible de una sección.
  @override // Captura únicamente una creación explícita.
  Future<void> crear({
    required TipoPerfil tipo,
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    creaciones++;
    perfiles.add(PerfilGestion(id: 'nuevo', nombre: nombre, tipo: tipo));
  } // No envía contraseñas a ningún servicio.

  @override // Actualiza una identidad existente.
  Future<void> editar(PerfilGestion perfil, String nombre) async {
    ediciones++;
    final indice = perfiles.indexWhere((fila) => fila.id == perfil.id);
    perfiles[indice] = PerfilGestion(
      id: perfil.id,
      nombre: nombre,
      tipo: perfil.tipo,
    );
  } // Conserva el identificador.

  @override // Captura la eliminación después de confirmar.
  Future<void> eliminar(PerfilGestion perfil) async {
    eliminaciones++;
    perfiles.removeWhere((fila) => fila.id == perfil.id);
  } // Conserva la sesión actual y los demás perfiles.
} // Finaliza la fuente de pruebas.

void pantalla(WidgetTester tester, Size tamano) {
  // Configura una ventana reproducible.
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1; // Mantiene coordenadas lógicas.
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(
    tester.view.resetDevicePixelRatio,
  ); // Restablece la ventana después de cada prueba.
} // Finaliza la configuración.

Widget lanzador(Widget pagina) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => pagina)),
        child: const Text('ABRIR'),
      ),
    ),
  ),
); // Conserva una ruta de regreso para verificar guardados.

void main() {
  // Verifica la gestión de perfiles sin tocar datos reales.
  for (final tamano in [const Size(1440, 1000), const Size(390, 844)]) {
    // Comprueba Windows y Android.
    testWidgets(
      'las secciones de perfiles tienen todos sus accesos en $tamano',
      (tester) async {
        // Verifica rutas y consulta del usuario actual.
        pantalla(tester, tamano);
        final repositorio =
            RepositorioPerfilesPrueba(); // Conserva una fuente aislada.
        await tester.pumpWidget(
          MaterialApp(home: PaginaPerfil(repositorio: repositorio)),
        );
        await tester.pumpAndSettle(); // Abre el panel completo.
        for (final tipo in TipoPerfil.values) {
          // Comprueba dueño y mecánico.
          expect(
            find.text('PERFIL ' + tipo.nombre),
            findsNothing,
          ); // Retira el acceso de consulta por sección.
          for (final modo in [
            ModoPerfil.crear,
            ModoPerfil.editar,
            ModoPerfil.eliminar,
          ]) {
            // Comprueba crear, editar y eliminar.
            final etiqueta =
                (modo == ModoPerfil.ver
                    ? 'PERFIL '
                    : modo == ModoPerfil.crear
                    ? 'CREAR PERFIL '
                    : modo == ModoPerfil.editar
                    ? 'EDITAR PERFIL '
                    : 'ELIMINAR PERFIL ') +
                tipo.nombre; // Identifica cada acción de la sección.
            await tester.ensureVisible(find.text(etiqueta));
            await tester.tap(find.text(etiqueta));
            await tester.pumpAndSettle(); // Abre la ruta real.
            if (modo == ModoPerfil.crear) {
              expect(
                tester
                    .widget<PaginaGestionPerfil>(
                      find.byType(PaginaGestionPerfil),
                    )
                    .modo,
                modo,
              );
            } else {
              final selector = tester.widget<PaginaSeleccionarPerfil>(
                find.byType(PaginaSeleccionarPerfil),
              );
              expect(selector.tipo, tipo);
              expect(selector.modo, modo);
            } // Distingue el formulario vacío de la selección de un perfil existente.
            Navigator.of(
              tester.element(
                find.byType(
                  modo == ModoPerfil.crear
                      ? PaginaGestionPerfil
                      : PaginaSeleccionarPerfil,
                ),
              ),
            ).pop();
            await tester.pumpAndSettle(); // Regresa al panel.
          } // Finaliza los modos.
        } // Finaliza las secciones.
        await tester.ensureVisible(find.text('VER MI PERFIL'));
        await tester.tap(find.text('VER MI PERFIL'));
        await tester.pumpAndSettle(); // Abre la identidad de la sesión.
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller!
              .text,
          'Dueño actual',
        ); // No muestra el perfil de otra persona.
        expect(
          find.text('GUARDAR CAMBIOS'),
          findsNothing,
        ); // Conserva Mi perfil como consulta.
        expect(
          tester.takeException(),
          isNull,
        ); // Exige ausencia de desbordamientos.
      },
    ); // Finaliza la navegación en una pantalla.

    testWidgets('cada modo limita campos y acciones en $tamano', (
      tester,
    ) async {
      // Comprueba que ver y eliminar nunca permitan editar.
      pantalla(tester, tamano);
      final repositorio =
          RepositorioPerfilesPrueba(); // Conserva una fuente controlada.
      for (final tipo in TipoPerfil.values) {
        // Comprueba ambos tipos de perfil.
        for (final modo in ModoPerfil.values) {
          // Comprueba las cuatro vistas.
          final perfil = repositorio.perfiles.firstWhere(
            (perfil) => perfil.tipo == tipo,
          ); // Selecciona una persona existente de la sección.
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey(tipo.name + modo.name),
              home: PaginaGestionPerfil(
                tipo: tipo,
                modo: modo,
                perfil: modo == ModoPerfil.crear ? null : perfil,
                repositorio: repositorio,
              ),
            ),
          );
          await tester.pumpAndSettle(); // Construye una vista independiente.
          final campos = tester
              .widgetList<TextFormField>(find.byType(TextFormField))
              .toList(); // Obtiene los campos del formulario real.
          if (modo == ModoPerfil.crear) {
            expect(campos, hasLength(3));
            expect(
              campos.every((campo) => campo.controller!.text.isEmpty),
              isTrue,
            );
          } else {
            expect(campos.first.controller!.text, perfil.nombre);
          } // Nunca rellena la creación con datos de otra persona.
          expect(
            campos.every(
              (campo) =>
                  campo.enabled ==
                  (modo == ModoPerfil.crear || modo == ModoPerfil.editar),
            ),
            isTrue,
          ); // Limita la edición a las vistas adecuadas.
          expect(
            find.text('GUARDAR CAMBIOS'),
            modo == ModoPerfil.editar ? findsOneWidget : findsNothing,
          ); // Solo la edición ofrece guardar cambios.
          expect(
            find.text('ELIMINAR PERFIL'),
            modo == ModoPerfil.eliminar ? findsOneWidget : findsNothing,
          ); // Solo la eliminación ofrece retirar el perfil.
          expect(
            tester.takeException(),
            isNull,
          ); // Exige distribución válida en móvil y escritorio.
        } // Finaliza las vistas de un tipo.
      } // Finaliza ambos tipos.
    }); // Finaliza los modos de una pantalla.
  } // Finaliza las plataformas.

  testWidgets('crear conserva la sesión y editar conserva el identificador', (
    tester,
  ) async {
    // Comprueba guardados reales de la interfaz con una fuente simulada.
    pantalla(tester, const Size(1440, 1000));
    final repositorio =
        RepositorioPerfilesPrueba(); // Conserva una sesión de dueño.
    await tester.pumpWidget(
      lanzador(
        PaginaGestionPerfil(
          tipo: TipoPerfil.mecanico,
          modo: ModoPerfil.crear,
          repositorio: repositorio,
        ),
      ),
    );
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle(); // Abre el formulario vacío.
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Mecánico nuevo');
    await tester.enterText(campos.at(1), 'nuevo@example.com');
    await tester.enterText(
      campos.at(2),
      'clave123',
    ); // Completa los campos necesarios.
    await tester.ensureVisible(find.text('CREAR PERFIL'));
    await tester.tap(find.text('CREAR PERFIL'));
    await tester.pumpAndSettle(); // Guarda el perfil nuevo.
    expect(repositorio.creaciones, 1);
    expect(
      repositorio.actual!.id,
      'sesion',
    ); // Conserva la identidad del dueño.
    final creado = repositorio.perfiles.last; // Recupera el perfil creado.
    await tester.pumpWidget(
      lanzador(
        PaginaGestionPerfil(
          tipo: TipoPerfil.mecanico,
          modo: ModoPerfil.editar,
          perfil: creado,
          repositorio: repositorio,
        ),
      ),
    );
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle(); // Abre la edición de ese registro.
    await tester.enterText(
      find.byType(TextFormField).first,
      'Nombre corregido',
    );
    await tester.tap(find.text('GUARDAR CAMBIOS'));
    await tester.pumpAndSettle(); // Persiste el cambio.
    expect(repositorio.ediciones, 1);
    expect(repositorio.perfiles.last.id, creado.id);
    expect(
      repositorio.perfiles.last.nombre,
      'Nombre corregido',
    ); // No duplica el perfil.
  }); // Finaliza creación y edición.

  testWidgets('eliminar exige confirmación y conserva el perfil al cancelar', (
    tester,
  ) async {
    // Verifica la acción destructiva solicitada únicamente para perfiles.
    pantalla(tester, const Size(1440, 1000));
    final repositorio = RepositorioPerfilesPrueba();
    final perfil =
        repositorio.perfiles.last; // Selecciona un mecánico de prueba.
    await tester.pumpWidget(
      lanzador(
        PaginaGestionPerfil(
          tipo: TipoPerfil.mecanico,
          modo: ModoPerfil.eliminar,
          perfil: perfil,
          repositorio: repositorio,
        ),
      ),
    );
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle(); // Abre el registro en consulta.
    await tester.tap(find.text('ELIMINAR PERFIL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle(); // Cancela la primera solicitud.
    expect(repositorio.eliminaciones, 0); // No retira el acceso al cancelar.
    await tester.tap(find.text('ELIMINAR PERFIL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ELIMINAR'));
    await tester
        .pumpAndSettle(); // Confirma explícitamente el registro elegido.
    expect(repositorio.eliminaciones, 1);
    expect(
      repositorio.perfiles.any((fila) => fila.id == perfil.id),
      isFalse,
    ); // Retira solamente el perfil confirmado.
  }); // Finaliza la confirmación de eliminación.

  testWidgets('un mecánico no puede crear, editar ni eliminar perfiles', (
    tester,
  ) async {
    // Comprueba las restricciones de la interfaz.
    pantalla(tester, const Size(1440, 1000));
    final repositorio = RepositorioPerfilesPrueba();
    repositorio.actual = repositorio
        .perfiles
        .last; // Simula una sesión sin permisos administrativos.
    for (final modo in [
      ModoPerfil.crear,
      ModoPerfil.editar,
      ModoPerfil.eliminar,
    ]) {
      // Comprueba todas las acciones de administración.
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(modo),
          home: PaginaGestionPerfil(
            tipo: TipoPerfil.mecanico,
            modo: modo,
            perfil: modo == ModoPerfil.crear ? null : repositorio.perfiles.last,
            repositorio: repositorio,
          ),
        ),
      );
      await tester.pumpAndSettle(); // Abre la vista restringida.
      expect(
        tester
            .widgetList<TextFormField>(find.byType(TextFormField))
            .every((campo) => !campo.enabled),
        isTrue,
      ); // No permite introducir modificaciones.
      final cartas = tester
          .widgetList<CartaNavegacion>(find.byType(CartaNavegacion))
          .where(
            (carta) =>
                carta.contenido is Text &&
                [
                  'CREAR PERFIL',
                  'GUARDAR CAMBIOS',
                  'ELIMINAR PERFIL',
                ].contains((carta.contenido as Text).data),
          ); // Localiza las acciones administrativas.
      expect(
        cartas.every((carta) => carta.alPresionar == null),
        isTrue,
      ); // No confía únicamente en campos desactivados.
    } // Finaliza las acciones.
  }); // Finaliza la verificación de permisos.
} // Finaliza las pruebas de perfiles.
