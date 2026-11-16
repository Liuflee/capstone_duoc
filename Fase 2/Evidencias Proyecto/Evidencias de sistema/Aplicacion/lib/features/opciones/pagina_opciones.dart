import 'package:frenos_cerna/core/tema/paleta_taller.dart';
// Importa los controles visuales de Flutter.
import 'package:material_ui/material_ui.dart';
// Reutiliza el marco común de las páginas.
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';

// Conserva las preferencias visuales únicamente durante la sesión actual.
class PreferenciasVisuales extends ChangeNotifier {
  static final instancia =
      PreferenciasVisuales._(); // Comparte los ajustes entre páginas.
  PreferenciasVisuales._(); // Evita crear ajustes independientes.
  double brillo = 1; // Usa el brillo original por defecto.
  double saturacion = 1; // Usa los colores originales por defecto.
  void actualizar({
    double? nuevoBrillo,
    double? nuevaSaturacion,
  }) {
    brillo = nuevoBrillo ?? brillo;
    saturacion =
        nuevaSaturacion ?? saturacion; // Actualiza solo los valores indicados.
    notifyListeners(); // Aplica los cambios a la aplicación.
  } // Finaliza la actualización.

  List<double> get matriz {
    final inversa = 1 - saturacion; // Calcula la contribución del gris.
    final rojo = 0.2126 * inversa;
    final verde = 0.7152 * inversa;
    final azul = 0.0722 * inversa; // Usa la luminancia de cada canal.
    return [
      brillo * (rojo + saturacion),
      brillo * verde,
      brillo * azul,
      0,
      0,
      brillo * rojo,
      brillo * (verde + saturacion),
      brillo * azul,
      0,
      0,
      brillo * rojo,
      brillo * verde,
      brillo * (azul + saturacion),
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]; // Mantiene el canal de transparencia sin cambios.
  } // Finaliza la transformación de color.
} // Finaliza el estado compartido de preferencias.

class PaginaOpciones extends StatelessWidget {
  const PaginaOpciones({super.key});

  @override
  Widget build(BuildContext context) => PaginaTematica(builder: _pagina);

  Widget _pagina(BuildContext context) {
    final tema = Theme.of(context);
    final paleta = PaletaTaller.de(context);
    final preferencias = PreferenciasVisuales.instancia;
    return EstructuraPagina(
      titulo: 'Opciones',
      activo: 'Opciones',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Apariencia', style: tema.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Text('Tema de color', style: tema.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, espacio) {
                      const separacion = 10.0;
                      final columnas = espacio.maxWidth >= 650
                          ? 3
                          : espacio.maxWidth >= 400
                          ? 2
                          : 1;
                      final ancho =
                          (espacio.maxWidth - (columnas - 1) * separacion) /
                          columnas;
                      return Wrap(
                        spacing: separacion,
                        runSpacing: separacion,
                        children: [
                          for (final opcion in PaletaTaller.values)
                            SizedBox(
                              width: ancho,
                              child: _OpcionPaleta(
                                paleta: opcion,
                                seleccionada: opcion == paleta,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ajustes de pantalla',
                    style: tema.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    color: paleta.oscura ? paleta.tarjeta : paleta.barra,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: AnimatedBuilder(
                        animation: preferencias,
                        builder: (context, _) => Column(
                          children: [
                            _AjusteVisual(
                              titulo: 'Brillo',
                              valor: preferencias.brillo,
                              min: .65,
                              max: 1.15,
                              alCambiar: (valor) =>
                                  preferencias.actualizar(nuevoBrillo: valor),
                            ),
                            _AjusteVisual(
                              titulo: 'Saturación de color',
                              valor: preferencias.saturacion,
                              min: 0,
                              max: 1.5,
                              alCambiar: (valor) => preferencias.actualizar(
                                nuevaSaturacion: valor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionPaleta extends StatelessWidget {
  final PaletaTaller paleta;
  final bool seleccionada;

  const _OpcionPaleta({required this.paleta, required this.seleccionada});

  @override
  Widget build(BuildContext context) {
    final actual = PaletaTaller.de(context);
    final borde = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: seleccionada
            ? actual.acento
            : actual.borde.withValues(alpha: .26),
        width: seleccionada ? 2 : 1,
      ),
    );
    return Semantics(
      selected: seleccionada,
      button: true,
      child: Material(
        shape: borde,
        color: actual.fondo,
        child: InkWell(
          customBorder: borde,
          onTap: seleccionada
              ? null
              : () async {
                  try {
                    await paleta.activar();
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo guardar el tema.'),
                      ),
                    );
                  }
                },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final color in [
                        paleta.menu,
                        paleta.tarjeta,
                        paleta.acento,
                      ])
                        ColoredBox(
                          color: color,
                          child: const SizedBox(width: 9, height: 20),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(paleta.nombre)),
                if (seleccionada)
                  const Icon(Icons.check_circle_outline, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AjusteVisual extends StatelessWidget {
  final String titulo;
  final double valor;
  final double min;
  final double max;
  final ValueChanged<double> alCambiar;

  const _AjusteVisual({
    required this.titulo,
    required this.valor,
    required this.min,
    required this.max,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = '${(valor * 100).round()} %';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo)),
              const SizedBox(width: 8),
              Text(porcentaje),
            ],
          ),
          Semantics(
            label: titulo,
            child: Slider(
              value: valor,
              min: min,
              max: max,
              activeColor: PaletaTaller.de(context).acento,
              semanticFormatterCallback: (valor) =>
                  '${(valor * 100).round()} %',
              onChanged: alCambiar,
            ),
          ),
        ],
      ),
    );
  }
}
