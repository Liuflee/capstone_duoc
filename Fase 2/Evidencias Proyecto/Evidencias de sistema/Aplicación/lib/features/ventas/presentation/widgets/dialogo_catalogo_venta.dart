import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:material_ui/material_ui.dart';

class DialogoCatalogoVenta<T> extends StatefulWidget {
  final String titulo;
  final String ayudaBusqueda;
  final String sinResultados;
  final String errorCarga;
  final Future<List<T>> Function() cargar;
  final bool Function(T, String) coincide;
  final Widget Function(BuildContext, T, VoidCallback) resultado;
  final Widget? accion;

  const DialogoCatalogoVenta({
    super.key,
    required this.titulo,
    required this.ayudaBusqueda,
    required this.sinResultados,
    required this.errorCarga,
    required this.cargar,
    required this.coincide,
    required this.resultado,
    this.accion,
  });

  @override
  State<DialogoCatalogoVenta<T>> createState() =>
      _DialogoCatalogoVentaState<T>();
}

class _DialogoCatalogoVentaState<T> extends State<DialogoCatalogoVenta<T>> {
  late Future<List<T>> _consulta = widget.cargar();
  String _busqueda = '';

  void _actualizarResultados() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Dialog(
      backgroundColor: PaletaTaller.de(context).fondo,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(
        width: 620,
        height: 580,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.titulo,
                            style: tema.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar selección',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      textInputAction: TextInputAction.search,
                      onChanged: (valor) => setState(
                        () => _busqueda = valor.trim().toLowerCase(),
                      ),
                      decoration: InputDecoration(
                        hintText: widget.ayudaBusqueda,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (widget.accion case final accion?) ...[
                      const SizedBox(height: 4),
                      Align(alignment: Alignment.centerLeft, child: accion),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              FutureBuilder<List<T>>(future: _consulta, builder: _resultados),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultados(BuildContext context, AsyncSnapshot<List<T>> estado) {
    if (estado.connectionState != ConnectionState.done) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (estado.hasError) {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.errorCarga),
            TextButton(
              onPressed: () => setState(() => _consulta = widget.cargar()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    final resultados = estado.requireData
        .where((item) => widget.coincide(item, _busqueda))
        .toList();
    if (resultados.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(widget.sinResultados, textAlign: TextAlign.center),
        ),
      );
    }
    return SliverList.separated(
      itemCount: resultados.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, indice) =>
          widget.resultado(context, resultados[indice], _actualizarResultados),
    );
  }
}
