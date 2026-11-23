import 'package:frenos_cerna/features/ventas/presentation/widgets/tema_venta.dart';
import 'package:material_ui/material_ui.dart';

Future<int?> pedirCantidadVenta(
  BuildContext context, {
  required String titulo,
  required int maximo,
  int inicial = 1,
  String accion = 'Continuar',
}) => mostrarDialogoVenta<int>(
  context: context,
  builder: (_) => _DialogoCantidad(
    titulo: titulo,
    maximo: maximo,
    inicial: inicial,
    accion: accion,
  ),
);

class _DialogoCantidad extends StatefulWidget {
  final String titulo;
  final int maximo;
  final int inicial;
  final String accion;

  const _DialogoCantidad({
    required this.titulo,
    required this.maximo,
    required this.inicial,
    required this.accion,
  });

  @override
  State<_DialogoCantidad> createState() => _DialogoCantidadState();
}

class _DialogoCantidadState extends State<_DialogoCantidad> {
  final _formulario = GlobalKey<FormState>();
  late final _cantidad = TextEditingController.fromValue(
    TextEditingValue(
      text: '${widget.inicial}',
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: '${widget.inicial}'.length,
      ),
    ),
  );

  void _confirmar() {
    if (_formulario.currentState!.validate()) {
      Navigator.pop(context, int.parse(_cantidad.text.trim()));
    }
  }

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.titulo),
    content: SizedBox(
      width: 340,
      child: Form(
        key: _formulario,
        child: TextFormField(
          controller: _cantidad,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _confirmar(),
          decoration: InputDecoration(
            labelText: 'Cantidad',
            helperText: 'Máximo: ${widget.maximo} unidades',
            border: const OutlineInputBorder(),
          ),
          validator: (valor) {
            final cantidad = int.tryParse(valor?.trim() ?? '');
            if (cantidad == null || cantidad < 1 || cantidad > widget.maximo) {
              return 'Ingresa entre 1 y ${widget.maximo} unidades';
            }
            return null;
          },
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _confirmar, child: Text(widget.accion)),
    ],
  );
}
