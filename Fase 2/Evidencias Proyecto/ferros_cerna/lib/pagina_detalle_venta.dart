import 'package:flutter/material.dart';
import 'package:ferros_cerna/data/ventas_repository.dart';

import 'menu_lateral.dart'; // Importa el menú centralizado

// ============================================================================
// MODELO DE DATOS (Preparado para la tabla detalle_venta en Supabase)
// ============================================================================
class ItemVenta {
  final String idProducto;
  final String nombre;
  final double total;

  ItemVenta({
    required this.idProducto,
    required this.nombre,
    required this.total,
  });

  factory ItemVenta.fromJson(Map<String, dynamic> json) {
    return ItemVenta(
      idProducto: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Artículo',
      total: double.tryParse(json['total']?.toString() ?? '') ?? 0,
    );
  }
}

// ============================================================================
// INTERFAZ DE LA PÁGINA
// ============================================================================
class PaginaDetalleVenta extends StatefulWidget {
  final String idVenta;
  final String clienteNombre;
  final String vehiculoNombre;
  final double total;
  final String? fecha; // Será nulo si la venta está en proceso
  final bool desdeHistorial; // Para cambiar el texto del botón de retroceso

  const PaginaDetalleVenta({
    super.key,
    required this.idVenta,
    required this.clienteNombre,
    required this.vehiculoNombre,
    required this.total,
    this.fecha,
    required this.desdeHistorial,
  });

  @override
  State<PaginaDetalleVenta> createState() => _PaginaDetalleVentaState();
}

class _PaginaDetalleVentaState extends State<PaginaDetalleVenta> {
  // Datos de prueba simulando la consulta a la tabla detalle_venta
  List<ItemVenta> _items = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    try {
      final venta = await VentaRegistro.obtenerPorId(widget.idVenta);
      if (!mounted) return;
      setState(() {
        _items = venta.items.map(ItemVenta.fromJson).toList();
        _cargando = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    // Título dinámico
    final tituloPagina = widget.desdeHistorial
        ? 'Venta “${widget.clienteNombre}” del “${widget.fecha}”'
        : 'Venta de “${widget.clienteNombre}” (En Proceso)';

    final textoBotonVolver = widget.desdeHistorial
        ? 'VOLVER A HISTORIAL\nDE VENTAS'
        : 'VOLVER A VENTAS';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (esPantallaGrande)
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[500],
                    child: const Icon(
                      Icons.settings_input_component,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Frenos\nCerna',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            Expanded(
              child: Text(
                tituloPagina,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis,
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
                CircleAvatar(
                  backgroundColor: Colors.red[800],
                  child: const Icon(Icons.build, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Ventas')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande)
            const SizedBox(width: 150, child: MenuLateral(activo: 'Ventas')),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: esPantallaGrande
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _construirColumnaIzquierda(
                            context,
                            textoBotonVolver,
                          ),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 2,
                          child: _construirColumnaDerecha(context),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _construirColumnaIzquierda(context, textoBotonVolver),
                        const SizedBox(height: 40),
                        _construirColumnaDerecha(context),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // COLUMNA IZQUIERDA (Botón, Total y Tabla de Productos)
  // ============================================================================
  Widget _construirColumnaIzquierda(BuildContext context, String textoBoton) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BOTÓN VOLVER
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_return, color: Colors.black),
          label: Text(
            textoBoton,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[200],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
        const SizedBox(height: 40),

        // CAJA DE PRECIO TOTAL
        Container(
          color: Colors.red[400],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text(
            'PRECIO TOTAL:\$${widget.total.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // TABLA DE PRODUCTOS
        if (_error != null)
          Text('Error al cargar el detalle: $_error')
        else if (_cargando)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.red[400]),
              border: TableBorder.all(color: Colors.black, width: 2),
              dataRowMaxHeight: 80,
              columns: const [
                DataColumn(
                  label: Text(
                    'PRODUCTO / SERVICIO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              rows: _items.asMap().entries.map((entrada) {
                final indice = entrada.key;
                final item = entrada.value;
                return DataRow(
                  color: WidgetStateProperty.all(
                    indice % 2 == 0 ? Colors.grey[200] : Colors.grey[300],
                  ),
                  cells: [
                    DataCell(Text(item.nombre)),
                    DataCell(
                      Text(
                        '\$${item.total.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ============================================================================
  // COLUMNA DERECHA (Perfil del cliente y vehículo)
  // ============================================================================
  Widget _construirColumnaDerecha(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 70,
          backgroundColor: Colors.red[400],
          child: const Icon(
            Icons.person_outline,
            size: 80,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.red[400],
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NOMBRE DE CLIENTE:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.clienteNombre,
                      style: const TextStyle(fontSize: 22, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: Colors.grey[400],
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TIPO DE AUTO:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.vehiculoNombre.replaceAll('\n', ' '),
                      style: const TextStyle(fontSize: 22, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.search, color: Colors.black, size: 30),
          label: const Text(
            'VER CLIENTE',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ],
    );
  }
}
