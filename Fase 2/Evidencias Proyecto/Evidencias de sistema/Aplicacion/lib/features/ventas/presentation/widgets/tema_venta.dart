import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:material_ui/material_ui.dart';

class TemaVenta extends StatelessWidget {
  static const _dimensionesBoton = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(64, 50)),
    iconSize: WidgetStatePropertyAll(22),
    visualDensity: VisualDensity.standard,
  );
  static const _dimensionesBotonIcono = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size.square(48)),
    iconSize: WidgetStatePropertyAll(26),
    visualDensity: VisualDensity.standard,
  );

  final Widget child;

  const TemaVenta({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paleta = PaletaTaller.de(context);
    return Theme(
      data: tema.copyWith(
        textTheme: tema.textTheme.apply(fontSizeFactor: 1.12),
        inputDecorationTheme: tema.inputDecorationTheme.copyWith(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        listTileTheme: tema.listTileTheme.copyWith(minVerticalPadding: 10),
        filledButtonTheme: FilledButtonThemeData(
          style: _dimensionesBoton.merge(tema.filledButtonTheme.style),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: _dimensionesBoton.merge(tema.outlinedButtonTheme.style),
        ),
        textButtonTheme: TextButtonThemeData(
          style: _dimensionesBoton.merge(tema.textButtonTheme.style),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: _dimensionesBotonIcono.merge(tema.iconButtonTheme.style),
        ),
        colorScheme: tema.colorScheme.copyWith(
          primary: paleta.oscura ? paleta.texto : paleta.menu,
          onPrimary: paleta.oscura ? paleta.fondo : Colors.white,
          secondaryContainer: Color.alphaBlend(
            paleta.acento.withValues(alpha: .16),
            paleta.fondo,
          ),
          onSecondaryContainer: paleta.texto,
          outline: paleta.borde.withValues(alpha: .55),
          surface: paleta.fondo,
          onSurface: paleta.texto,
          onSurfaceVariant: paleta.texto.withValues(alpha: .78),
        ),
      ),
      child: child,
    );
  }
}

Future<T?> mostrarDialogoVenta<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => mostrarDialogoConTema<T>(
  context: context,
  builder: (_) => TemaVenta(child: Builder(builder: builder)),
);

ButtonStyle estiloAccionPrincipalVenta(BuildContext context) {
  final paleta = PaletaTaller.de(context);
  final acento = paleta.oscura ? paleta.acento : paleta.menu;
  return FilledButton.styleFrom(
    backgroundColor: acento,
    foregroundColor:
        ThemeData.estimateBrightnessForColor(acento) == Brightness.dark
        ? Colors.white
        : Colors.black,
  );
}
