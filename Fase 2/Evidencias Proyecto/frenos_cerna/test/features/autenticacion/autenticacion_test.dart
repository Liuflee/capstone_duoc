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
    await tester.pumpWidget(const MaterialApp(home: PaginaAutenticacion()));

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿No tienes cuenta? Regístrate'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
