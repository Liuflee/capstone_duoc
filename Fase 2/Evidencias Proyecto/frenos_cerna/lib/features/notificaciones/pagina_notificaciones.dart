import 'package:flutter/material.dart';
import 'package:ferros_cerna/shared/widgets/menu_lateral.dart';

class _ProductoProveedor {
  final String nombre;
  final int precioAnterior;
  final int precioActual;
  final String fecha;

  const _ProductoProveedor({
    required this.nombre,
    required this.precioAnterior,
    required this.precioActual,
    required this.fecha,
  });
}

class _ProductoReservado {
  final String nombre;
  final String proveedor;
  final DateTime fecha;

  const _ProductoReservado({
    required this.nombre,
    required this.proveedor,
    required this.fecha,
  });
}

class PaginaNotificaciones extends StatefulWidget {
  const PaginaNotificaciones({super.key});

  @override
  State<PaginaNotificaciones> createState() => _PaginaNotificacionesState();
}

class _PaginaNotificacionesState extends State<PaginaNotificaciones> {
  final TextEditingController _busquedaController = TextEditingController();
  final List<_ProductoReservado> _reservados = [];
  bool _mostrarReservados = false;
  String _busqueda = '';

  static const List<_ProductoProveedor> _productos = [
    _ProductoProveedor(
      nombre: 'RUEDA GORDA',
      precioAnterior: 100000,
      precioActual: 150000,
      fecha: '01/02/2003',
    ),
    _ProductoProveedor(
      nombre: 'VENTANA ROJA',
      precioAnterior: 200000,
      precioActual: 210000,
      fecha: '12/09/2002',
    ),
    _ProductoProveedor(
      nombre: 'MANUBRIO POLIGONAL',
      precioAnterior: 90000,
      precioActual: 70000,
      fecha: '09/07/2002',
    ),
    _ProductoProveedor(
      nombre: 'PASTILLAS DE FRENO',
      precioAnterior: 32000,
      precioActual: 34500,
      fecha: '18/08/2002',
    ),
    _ProductoProveedor(
      nombre: 'DISCO DELANTERO',
      precioAnterior: 84500,
      precioActual: 84500,
      fecha: '03/06/2002',
    ),
  ];

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  String _formatearPrecio(int precio) {
    return '\$${precio.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  Future<void> _reservarProducto() async {
    final nombreController = TextEditingController();
    final proveedorController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reservar producto'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) => valor == null || valor.trim().isEmpty
                      ? 'Ingresa el nombre del producto'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: proveedorController,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );

    if (resultado == true && mounted) {
      setState(() {
        _reservados.insert(
          0,
          _ProductoReservado(
            nombre: nombreController.text.trim(),
            proveedor: proveedorController.text.trim().isEmpty
                ? 'Sin especificar'
                : proveedorController.text.trim(),
            fecha: DateTime.now(),
          ),
        );
        _mostrarReservados = true;
      });
    }
    nombreController.dispose();
    proveedorController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (esPantallaGrande)
              const Row(
                children: [
                  Icon(Icons.settings_input_component, size: 38),
                  SizedBox(width: 10),
                  Text(
                    'Frenos\nCerna',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            const Expanded(
              child: Text(
                'Notificaciones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            Row(
              children: [
                if (esPantallaGrande)
                  const Text(
                    'Leonardo',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                const SizedBox(width: 10),
                const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.build, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Notificaciones')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande)
            const SizedBox(
              width: 150,
              child: MenuLateral(activo: 'Notificaciones'),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(esPantallaGrande ? 30 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _BotonSeccion(
                        icono: Icons.inventory_2_outlined,
                        texto: 'RESERVAR\nPRODUCTO',
                        seleccionado: !_mostrarReservados,
                        onPressed: _reservarProducto,
                      ),
                      _BotonSeccion(
                        icono: Icons.menu_book_outlined,
                        texto: 'LISTA\nRESERVADOS',
                        seleccionado: _mostrarReservados,
                        onPressed: () => setState(
                          () => _mostrarReservados = !_mostrarReservados,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: TextField(
                        controller: _busquedaController,
                        onChanged: (valor) => setState(() => _busqueda = valor),
                        decoration: InputDecoration(
                          hintText: 'BUSCAR PRODUCTO',
                          filled: true,
                          fillColor: Colors.grey[300],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: _busqueda.isEmpty
                              ? const Icon(Icons.search, size: 28)
                              : IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _busquedaController.clear();
                                    setState(() => _busqueda = '');
                                  },
                                ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_mostrarReservados)
                    _construirListaReservados(esPantallaGrande)
                  else
                    _construirCatalogo(esPantallaGrande),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCatalogo(bool esPantallaGrande) {
    final productos = _productos
        .where(
          (producto) =>
              producto.nombre.toLowerCase().contains(_busqueda.toLowerCase()),
        )
        .toList();

    if (productos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No se encontraron productos.')),
      );
    }

    if (!esPantallaGrande) {
      return Column(
        children: productos
            .map(
              (producto) => _TarjetaProducto(
                producto: producto,
                formatearPrecio: _formatearPrecio,
              ),
            )
            .toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.red[400]),
        dataRowMinHeight: 76,
        dataRowMaxHeight: 92,
        columnSpacing: 28,
        border: const TableBorder(
          verticalInside: BorderSide(color: Colors.black, width: 1.5),
        ),
        columns: const [
          DataColumn(label: _EncabezadoTabla('PRODUCTO')),
          DataColumn(label: _EncabezadoTabla('PRECIO VIEJO')),
          DataColumn(label: _EncabezadoTabla('PRECIO NUEVO')),
          DataColumn(label: _EncabezadoTabla('FECHA')),
        ],
        rows: productos.asMap().entries.map((entrada) {
          final indice = entrada.key;
          final producto = entrada.value;
          return DataRow(
            color: WidgetStateProperty.all(
              indice.isEven ? Colors.grey[300] : Colors.grey[200],
            ),
            cells: [
              DataCell(_TextoTabla(producto.nombre)),
              DataCell(_TextoTabla(_formatearPrecio(producto.precioAnterior))),
              DataCell(_TextoTabla(_formatearPrecio(producto.precioActual))),
              DataCell(_TextoTabla(producto.fecha, pequeno: true)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _construirListaReservados(bool esPantallaGrande) {
    final productos = _reservados
        .where(
          (producto) =>
              producto.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
              producto.proveedor.toLowerCase().contains(
                _busqueda.toLowerCase(),
              ),
        )
        .toList();

    if (productos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            _reservados.isEmpty
                ? 'Aún no hay productos reservados.'
                : 'No se encontraron productos reservados.',
          ),
        ),
      );
    }

    if (!esPantallaGrande) {
      return Column(
        children: productos
            .map(
              (producto) => Card(
                color: Colors.grey[200],
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(producto.nombre),
                  subtitle: Text(
                    '${producto.proveedor} · En espera · ${_formatearFecha(producto.fecha)}',
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.red[400]),
        dataRowMinHeight: 76,
        dataRowMaxHeight: 92,
        columnSpacing: 36,
        columns: const [
          DataColumn(label: _EncabezadoTabla('PRODUCTO')),
          DataColumn(label: _EncabezadoTabla('PROVEEDOR')),
          DataColumn(label: _EncabezadoTabla('FECHA')),
          DataColumn(label: _EncabezadoTabla('ESTADO')),
        ],
        rows: productos.asMap().entries.map((entrada) {
          final indice = entrada.key;
          final producto = entrada.value;
          return DataRow(
            color: WidgetStateProperty.all(
              indice.isEven ? Colors.grey[300] : Colors.grey[200],
            ),
            cells: [
              DataCell(_TextoTabla(producto.nombre)),
              DataCell(_TextoTabla(producto.proveedor)),
              DataCell(
                _TextoTabla(_formatearFecha(producto.fecha), pequeno: true),
              ),
              const DataCell(_TextoTabla('EN ESPERA')),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }
}

class _BotonSeccion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool seleccionado;
  final VoidCallback onPressed;

  const _BotonSeccion({
    required this.icono,
    required this.texto,
    required this.seleccionado,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 92,
      child: Material(
        color: seleccionado ? Colors.red[400] : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(icono, size: 54, color: Colors.black87),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    texto,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: seleccionado ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  final String texto;

  const _EncabezadoTabla(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _TextoTabla extends StatelessWidget {
  final String texto;
  final bool pequeno;

  const _TextoTabla(this.texto, {this.pequeno = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: pequeno ? 14 : 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  final _ProductoProveedor producto;
  final String Function(int) formatearPrecio;

  const _TarjetaProducto({
    required this.producto,
    required this.formatearPrecio,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[200],
      margin: const EdgeInsets.only(bottom: 10),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto.nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.black54),
            _DatoProducto(
              etiqueta: 'Precio viejo',
              valor: formatearPrecio(producto.precioAnterior),
            ),
            _DatoProducto(
              etiqueta: 'Precio nuevo',
              valor: formatearPrecio(producto.precioActual),
            ),
            _DatoProducto(etiqueta: 'Fecha', valor: producto.fecha),
          ],
        ),
      ),
    );
  }
}

class _DatoProducto extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _DatoProducto({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(etiqueta), Text(valor)],
      ),
    );
  }
}
