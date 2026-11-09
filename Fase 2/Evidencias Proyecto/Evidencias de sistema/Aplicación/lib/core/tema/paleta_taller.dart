import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PaletaTaller {
  original(
    'Original',
    0xffb74545,
    0xff721919,
    0xffe0e0e0,
    0xffe0e0e0,
    0xffffffff,
    0xffef6767,
  ),
  carbon(
    'Carbón rojo',
    0xffd92329,
    0xff0b0f14,
    0xff10151c,
    0xff1b222c,
    0xff0d1015,
    0xff84242c,
  ),
  cobre(
    'Grafito cobre',
    0xffac6947,
    0xff171311,
    0xff201b18,
    0xff2c2521,
    0xff12100f,
    0xff704632,
  ),
  azul(
    'Medianoche azul',
    0xff2865af,
    0xff0b1321,
    0xff111d2d,
    0xff1c2a3e,
    0xff090f19,
    0xff254e7c,
  ),
  verde(
    'Petróleo esmeralda',
    0xff16745e,
    0xff0c1918,
    0xff102422,
    0xff1a3330,
    0xff091412,
    0xff225c4f,
  ),
  bronce(
    'Obsidiana bronce',
    0xff956e34,
    0xff171510,
    0xff222019,
    0xff302c23,
    0xff12110e,
    0xff67522e,
  );

  final String nombre;
  final int _acento, _menu, _barra, _tarjeta, _fondo, _tabla;
  const PaletaTaller(
    this.nombre,
    this._acento,
    this._menu,
    this._barra,
    this._tarjeta,
    this._fondo,
    this._tabla,
  );
  Color get acento => Color(_acento);
  Color get menu => Color(_menu);
  Color get barra => Color(_barra);
  Color get tarjeta => Color(_tarjeta);
  Color get fondo => Color(_fondo);
  Color get tabla => Color(_tabla);
  bool get oscura => this != original;
  Color get borde => oscura ? const Color(0xff465262) : Colors.black;
  Color get texto => oscura ? const Color(0xfff1f3f5) : Colors.black;
  static final seleccion = ValueNotifier(original);
  static Future<void> cargar() async {
    final indice =
        (await SharedPreferences.getInstance()).getInt('paleta_taller') ?? 0;
    seleccion.value = indice >= 0 && indice < values.length
        ? values[indice]
        : original;
  }

  Future<void> activar() async {
    seleccion.value = this;
    await (await SharedPreferences.getInstance()).setInt(
      'paleta_taller',
      index,
    );
  }

  static PaletaTaller de(BuildContext context) {
    final tema = Theme.of(context);
    return tema.brightness == Brightness.dark ? seleccion.value : original;
  }

  Color adaptar(Color color, {bool tinta = false, bool linea = false}) {
    if (!oscura || color.a < 0.1) return color;
    if (linea) return borde;
    if (color == acento ||
        color == tabla ||
        color == fondo ||
        color == barra ||
        color == menu ||
        color == tarjeta)
      return color;
    if (tinta ||
        color == Colors.black ||
        color == Colors.black54 ||
        color == Colors.black45)
      return texto;
    if (color == Colors.white) return fondo;
    if (color.r > color.g * 1.2 && color.r > color.b * 1.2) return acento;
    return tarjeta;
  }

  ThemeData aplicar(ThemeData base) {
    if (!oscura) return base;
    final esquema = ColorScheme.dark(
      primary: acento,
      secondary: acento,
      surface: tarjeta,
      onSurface: texto,
    );
    return base.copyWith(
      colorScheme: esquema,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: fondo,
      canvasColor: tarjeta,
      cardColor: tarjeta,
      dividerColor: borde,
      iconTheme: IconThemeData(color: texto),
      textTheme: base.textTheme.apply(bodyColor: texto, displayColor: texto),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tarjeta,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tarjeta,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

// Las pantallas del taller comparten el tema sin cambiar el diseño del acceso.
class PaginaTematica extends StatelessWidget {
  final WidgetBuilder builder;
  const PaginaTematica({super.key, required this.builder});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<PaletaTaller>(
    valueListenable: PaletaTaller.seleccion,
    builder: (context, paleta, _) => Theme(
      data: paleta.aplicar(Theme.of(context)),
      child: Builder(builder: builder),
    ),
  );
}

class SelectorPaletas extends StatelessWidget {
  final bool compacto;
  const SelectorPaletas({super.key, required this.compacto});
  @override
  Widget build(BuildContext context) {
    final actual = PaletaTaller.de(context);
    if (compacto) {
      return PopupMenuButton<PaletaTaller>(
        tooltip: 'Cambiar paleta',
        icon: const Icon(Icons.palette_outlined),
        initialValue: actual,
        onSelected: (p) => p.activar(),
        itemBuilder: (_) => [
          for (final p in PaletaTaller.values)
            PopupMenuItem(value: p, child: Text(p.nombre)),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in PaletaTaller.values)
          IconButton(
            tooltip: p.nombre,
            style: IconButton.styleFrom(
              backgroundColor: p.barra,
              foregroundColor: p.acento,
              side: BorderSide(color: p == actual ? p.texto : p.acento),
            ),
            onPressed: p.activar,
            icon: Icon(p == actual ? Icons.check : Icons.palette, size: 19),
          ),
      ],
    );
  }
}
