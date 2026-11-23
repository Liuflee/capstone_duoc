import 'package:frenos_cerna/shared/widgets/navegacion_inferior.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:material_ui/material_ui.dart';

class EstructuraPagina extends StatelessWidget {
  final String titulo;
  final String activo;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool mostrarVolver;
  final bool mostrarNavegacionMovil;
  final bool esRaizSeccion;

  const EstructuraPagina({
    super.key,
    required this.titulo,
    required this.activo,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(40, 24, 40, 24),
    this.mostrarVolver = false,
    this.mostrarNavegacionMovil = true,
    this.esRaizSeccion = false,
  });

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final anchoMenu = DimensionesNavegacion.anchoMenuEn(context);
    final altoBarra = DimensionesNavegacion.altoBarra(ancho);
    final escritorio = anchoMenu > 0;
    return Scaffold(
      backgroundColor: PaletaTaller.de(context).fondo,
      drawer: MenuLateral.desplegable(context, activo: activo),
      bottomNavigationBar: NavegacionInferior.para(
        context,
        activo: activo,
        habilitada: mostrarNavegacionMovil,
        esRaizSeccion: esRaizSeccion,
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(altoBarra),
        child: SizedBox(
          height: altoBarra,
          child: BarraSuperior(
            tituloPagina: titulo,
            mostrarVolver: mostrarVolver,
          ),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (escritorio)
            SizedBox(
              width: anchoMenu,
              child: MenuLateral(activo: activo),
            ),
          Expanded(
            child: Padding(
              padding: escritorio ? padding : const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
