import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenos_cerna/features/asistente/asistente_global.dart';
import 'package:frenos_cerna/main.dart';

void main() {
  testWidgets('la app monta el asistente solo en plataformas móviles nativas', (
    tester,
  ) async {
    await tester.pumpWidget(const MiAplicacion());

    final esMovilNativo =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    expect(
      find.byType(AsistenteGlobal),
      esMovilNativo ? findsOneWidget : findsNothing,
    );
  }, variant: TargetPlatformVariant.all());
}
