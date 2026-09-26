import 'package:flutter/material.dart';
import 'menu_lateral.dart';
import 'pagina_vehiculos.dart'; // Importamos para acceder al modelo HistorialVehiculo

// ============================================================================
// MODELOS DE DATOS SECUNDARIOS (Preparados para un JOIN en Supabase)
// ============================================================================

class DetalleServicio {
  final String tipoServicio;
  final String kilometraje;
  final String estado;

  DetalleServicio({required this.tipoServicio, required this.kilometraje, required this.estado});

  factory DetalleServicio.fromJson(Map<String, dynamic> json) {
    return DetalleServicio(
      tipoServicio: json['tipo_servicio'] ?? 'NO REGISTRADO',
      kilometraje: json['kilometraje'] ?? '0',
      estado: json['estado'] ?? 'PENDIENTE',
    );
  }
}

class CompraVehiculo {
  final String id;
  final String nombre;
  final double precio;

  CompraVehiculo({required this.id, required this.nombre, required this.precio});

  factory CompraVehiculo.fromJson(Map<String, dynamic> json) {
    return CompraVehiculo(
      id: json['id'].toString(),
      nombre: json['nombre'],
      precio: double.parse(json['precio'].toString()),
    );
  }
}

// ============================================================================
// INTERFAZ DE LA PÁGINA
// ============================================================================
class PaginaDetalleVehiculo extends StatefulWidget {
  final HistorialVehiculo vehiculo;

  const PaginaDetalleVehiculo({super.key, required this.vehiculo});

  @override
  State<PaginaDetalleVehiculo> createState() => _PaginaDetalleVehiculoState();
}

class _PaginaDetalleVehiculoState extends State<PaginaDetalleVehiculo> {
  // Dummy data simulando la consulta a Supabase:
  // supabase.from('detalles_servicio').select().eq('vehiculo_id', widget.vehiculo.id)
  final DetalleServicio detalle = DetalleServicio(
    tipoServicio: 'UBER',
    kilometraje: '2 MILLAS',
    estado: 'REPARACIÓN HECHA',
  );

  // supabase.from('compras').select().eq('vehiculo_id', widget.vehiculo.id)
  final List<CompraVehiculo> compras = [
    CompraVehiculo(id: '1', nombre: 'ALERÓN ACELERÓN', precio: 20000),
    CompraVehiculo(id: '2', nombre: 'VENTANA TÉRMICA', precio: 300000),
    CompraVehiculo(id: '3', nombre: 'MOTOR 420T', precio: 50000),
  ];

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    // Limpiamos los saltos de línea del nombre del vehículo para el título
    final nombreVehiculoLimpio = widget.vehiculo.vehiculoNombre.replaceAll('\n', ' ');

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
                  Container(width: 40, height: 40, color: Colors.grey[500], child: const Icon(Icons.settings_input_component, color: Colors.white)),
                  const SizedBox(width: 10),
                  const Text('Frenos\nCerna', style: TextStyle(color: Colors.black, fontSize: 16)),
                ],
              ),
            // Título dinámico basado en la imagen
            Expanded(
              child: Text(
                '“$nombreVehiculoLimpio” de “${widget.vehiculo.clienteNombre}”', 
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                if (esPantallaGrande) const Text('Leonardo', style: TextStyle(color: Colors.black, fontSize: 16)),
                const SizedBox(width: 10),
                CircleAvatar(backgroundColor: Colors.red[800], child: const Icon(Icons.build, color: Colors.black)),
              ],
            )
          ],
        ),
      ),
      drawer: esPantallaGrande ? null : const Drawer(child: MenuLateral(activo: 'Vehiculos')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande) const SizedBox(width: 150, child: MenuLateral(activo: 'Vehiculos')),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              // Usamos Flex (Row o Column) dependiendo del tamaño de la pantalla
              child: esPantallaGrande 
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _construirColumnaIzquierda(context)),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _construirColumnaDerecha(context)),
                      ],
                    )
                  : Column(
                      children: [
                        _construirColumnaIzquierda(context),
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
  // COLUMNA IZQUIERDA (Botón, Detalles de servicio, Tabla de compras)
  // ============================================================================
  Widget _construirColumnaIzquierda(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_return, color: Colors.black),
          label: const Text('VOLVER A HISTORIAL', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[200],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
        const SizedBox(height: 30),
        
        // Bloque gris de detalles del servicio
        Container(
          width: double.infinity,
          color: Colors.grey[300],
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TIPO DE SERVICIO: ${detalle.tipoServicio}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('KILOMETRAJE AL LLEGAR: ${detalle.kilometraje}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('ESTADO: ${detalle.estado}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 40),

        const Text('COMPRAS PARA VEHÍCULO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        // Tabla de compras
        SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.red[400]),
            border: TableBorder.all(color: Colors.black, width: 2),
            dataRowMaxHeight: 60,
            columns: const [
              DataColumn(label: Text('NOMBRE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('PRECIO', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('VER', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ],
            rows: compras.asMap().entries.map((entrada) {
              int indice = entrada.key;
              CompraVehiculo compra = entrada.value;
              return DataRow(
                color: MaterialStateProperty.all(indice % 2 == 0 ? Colors.grey[200] : Colors.grey[300]),
                cells: [
                  DataCell(Text(compra.nombre, style: const TextStyle(fontSize: 16))),
                  DataCell(Text('\$${compra.precio.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}', style: const TextStyle(fontSize: 16))),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.search, size: 30, color: Colors.black),
                      onPressed: () {
                        // Lógica para ver detalle del producto específico
                      },
                    )
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
    final nombreVehiculoLimpio = widget.vehiculo.vehiculoNombre.replaceAll('\n', ' ');

    return Column(
      children: [
        CircleAvatar(
          radius: 70,
          backgroundColor: Colors.red[400],
          child: const Icon(Icons.person_outline, size: 80, color: Colors.black),
        ),
        const SizedBox(height: 20),
        
        // Tarjeta de información del cliente y vehículo
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              // Sección superior (Roja)
              Container(
                width: double.infinity,
                color: Colors.red[400],
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NOMBRE DE CLIENTE:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 10),
                    Text(widget.vehiculo.clienteNombre, style: const TextStyle(fontSize: 22, color: Colors.black)),
                  ],
                ),
              ),
              // Sección inferior (Gris)
              Container(
                width: double.infinity,
                color: Colors.grey[400],
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TIPO DE AUTO:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 10),
                    Text(nombreVehiculoLimpio, style: const TextStyle(fontSize: 22, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        ElevatedButton.icon(
          onPressed: () {
            // Lógica para redirigir a la página de edición del cliente
          },
          icon: const Icon(Icons.search, color: Colors.black, size: 30),
          label: const Text('VER CLIENTE', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ],
    );
  }
}