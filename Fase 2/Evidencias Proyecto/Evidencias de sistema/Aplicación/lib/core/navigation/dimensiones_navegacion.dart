import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

abstract final class DimensionesNavegacion {
  static const double altoBarraInferior = 66;

  static bool usaBarraInferior(BuildContext context) {
    final plataforma = Theme.of(context).platform;
    final pantalla = MediaQuery.sizeOf(context);
    final telefono =
        !kIsWeb &&
        (plataforma == TargetPlatform.android ||
            plataforma == TargetPlatform.iOS) &&
        pantalla.shortestSide < 600;
    return telefono;
  }

  static bool usaMenuDesplegable(BuildContext context) =>
      !usaBarraInferior(context) && MediaQuery.sizeOf(context).width < 700;

  static double anchoMenuEn(BuildContext context) => usaBarraInferior(context)
      ? 0
      : anchoMenu(MediaQuery.sizeOf(context).width);

  static double anchoMenu(double ancho) =>
      ancho < 700 ? 0 : (ancho * .15).clamp(148.0, 224.0).toDouble();

  static double altoBarra(double ancho) => ancho < 700 ? 62 : 68;
}
