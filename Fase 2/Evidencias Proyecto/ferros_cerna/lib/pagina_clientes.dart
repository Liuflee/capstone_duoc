import 'package:ferros_cerna/data/supabase_database.dart';
import 'package:flutter/material.dart';

import 'pagina_crear_cliente.dart';
import 'pagina_editar_cliente.dart';
import 'menu_lateral.dart';

class Cliente {
  final String id;
  final String nombre;
  final String numero;
  final String ultimaVenta;
  final String vehiculo;

  Cliente({
    required this.id,
    required this.nombre,
    required this.numero,
    required this.ultimaVenta,
    required this.vehiculo,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['rut']?.toString() ?? 'sin-rut',
      nombre: (json['nombre'] ?? 'Sin nombre').toString(),
      numero: (json['fono'] ?? 'Sin teléfono').toString(),
      ultimaVenta: 'No disponible',
      vehiculo: 'Sin registrar',
    );
  }
}

class PaginaClientes extends StatefulWidget {
  const PaginaClientes({super.key});

  @override
  State<PaginaClientes> createState() => _PaginaClientesState();
}

class _PaginaClientesState extends State<PaginaClientes> {
  List<Cliente> clientes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    try {
      final response = await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .select('rut, nombre, fono')
          .order('nombre');

      final data = response as List<dynamic>;
      if (!mounted) return;
      setState(() {
        clientes = data
            .map(
              (item) =>
                  Cliente.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _borrarCliente(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar cliente'),
        content: Text('¿Borrar a ${cliente.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .delete()
          .eq('rut', int.parse(cliente.id));
      await _cargarClientes();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar el cliente: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: construirAppBar(context, 'Clientes', esPantallaGrande),
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Clientes')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande) const ContenedorMenuLateral(activo: 'Clientes'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final actualizado = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaginaCrearCliente(),
                        ),
                      );
                      if (actualizado == true) _cargarClientes();
                    },
                    icon: const Icon(
                      Icons.person_add_alt_1,
                      color: Colors.black,
                    ),
                    label: const Text(
                      '+ Añadir cliente',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 300,
                    color: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'BUSCAR CLIENTE',
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.search, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) Text('Error al cargar clientes: $_error'),
                  if (_cargando)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.red[400],
                            ),
                            border: TableBorder.all(
                              color: Colors.black,
                              width: 2,
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'NOMBRE',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'NÚMERO',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'RUT',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'CAMBIAR',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'BORRAR',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            rows: clientes.asMap().entries.map((entrada) {
                              Cliente cliente = entrada.value;
                              return DataRow(
                                color: WidgetStateProperty.all(
                                  entrada.key % 2 == 0
                                      ? Colors.grey[200]
                                      : Colors.grey[300],
                                ),
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.red[300],
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          cliente.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(cliente.numero)),
                                  DataCell(Text(cliente.id)),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 30),
                                      onPressed: () async {
                                        final actualizado =
                                            await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PaginaEditarCliente(
                                                      cliente: cliente,
                                                    ),
                                              ),
                                            );
                                        if (actualizado == true) {
                                          _cargarClientes();
                                        }
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.red,
                                        size: 30,
                                      ),
                                      onPressed: () => _borrarCliente(cliente),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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

// ============================================================================
// WIDGETS COMPARTIDOS (Públicos para usarse en los otros archivos)
// ============================================================================

PreferredSizeWidget construirAppBar(
  BuildContext context,
  String titulo,
  bool esPantallaGrande,
) {
  return AppBar(
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
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
  );
}

class CampoEditable extends StatelessWidget {
  final TextEditingController? controlador;
  final String? hint;

  const CampoEditable({super.key, this.controlador, this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      color: Colors.grey[300],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controlador,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Container(
            color: Colors.grey[400],
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.edit_square, size: 30),
          ),
        ],
      ),
    );
  }
}
