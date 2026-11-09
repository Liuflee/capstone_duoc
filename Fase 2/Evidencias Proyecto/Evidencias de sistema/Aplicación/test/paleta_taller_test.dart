import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frenos_cerna/main.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/features/perfil/pagina_perfil.dart';

void main() {
  testWidgets(
    'El tema guardado pinta la base y el fondo de las páginas al cambiar de paleta',
    (tester) async {
      SharedPreferences.setMockInitialValues({'paleta_taller': 1});
      await PaletaTaller.cargar();
      addTearDown(() => PaletaTaller.seleccion.value = PaletaTaller.original);
      await tester.pumpWidget(const MiAplicacion());
      await tester.pumpAndSettle();
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute(builder: (_) => const PaginaPerfil()));
      await tester.pumpAndSettle();
      for (final p in PaletaTaller.values) {
        await p.activar();
        await tester.pumpAndSettle();
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).color,
          p.fondo,
        );
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
          p.fondo,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
