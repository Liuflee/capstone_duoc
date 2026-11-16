import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:material_ui/material_ui.dart';

class PanelVenta extends StatelessWidget {
  final Widget child;

  const PanelVenta({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final paleta = PaletaTaller.de(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      color: Color.alphaBlend(
        paleta.tarjeta.withValues(alpha: .24),
        paleta.fondo,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: paleta.borde.withValues(alpha: paleta.oscura ? .7 : .14),
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}
