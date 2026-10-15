import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/autenticacion/data/autenticacion_repository.dart';
import 'package:frenos_cerna/features/autenticacion/presentation/pagina_autenticacion.dart';

void main() {
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
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
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
}
