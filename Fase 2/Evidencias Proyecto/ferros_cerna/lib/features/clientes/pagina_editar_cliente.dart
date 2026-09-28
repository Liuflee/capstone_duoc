import 'package:flutter/material.dart';
import 'package:ferros_cerna/core/data/supabase_database.dart';
import 'package:ferros_cerna/features/clientes/pagina_clientes.dart';
import 'package:ferros_cerna/shared/widgets/menu_lateral.dart';

class PaginaEditarCliente extends StatefulWidget {
  final Cliente cliente;

  const PaginaEditarCliente({super.key, required this.cliente});

  @override
  State<PaginaEditarCliente> createState() => _PaginaEditarClienteState();
}

class _PaginaEditarClienteState extends State<PaginaEditarCliente> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _fonoCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.cliente.nombre);
    _fonoCtrl = TextEditingController(text: widget.cliente.numero);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _fonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCliente() async {
    final fono = int.tryParse(_fonoCtrl.text.trim());
    final nombre = _nombreCtrl.text.trim();
    if (fono == null || nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre y teléfono válidos.')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .update({'nombre': nombre, 'fono': fono})
          .eq('rut', int.parse(widget.cliente.id));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el cliente: $error')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _borrarCliente() async {
    setState(() => _guardando = true);
    try {
      await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .delete()
          .eq('rut', int.parse(widget.cliente.id));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar el cliente: $error')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;
    final cliente = widget.cliente;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: construirAppBar(
        context,
        'Cliente “${cliente.nombre}”',
        esPantallaGrande,
      ),
      drawer: esPantallaGrande
          ? null
          : const Drawer(child: MenuLateral(activo: 'Clientes')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esPantallaGrande) const ContenedorMenuLateral(activo: 'Clientes'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VEHÍCULO DEL CLIENTE:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                color: Colors.grey[300],
                                child: Text(
                                  cliente.vehiculo,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                color: Colors.grey[400],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'REVISAR',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(Icons.search),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          CampoEditable(controlador: _nombreCtrl),
                          const SizedBox(height: 20),
                          CampoEditable(controlador: _fonoCtrl),
                        ],
                      ),
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.red[300],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cliente.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            cliente.numero,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _guardando ? null : _borrarCliente,
                            icon: const Icon(
                              Icons.person_remove,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Borrar Cliente',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardarCliente,
                      icon: const Icon(Icons.save, color: Colors.black),
                      label: const Text('GUARDAR CAMBIOS'),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'HISTORIAL DE VENTAS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.red[400]),
                    border: TableBorder.all(color: Colors.black, width: 2),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'NOMBRE PRODUCTO',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'FECHA',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'EXPANDIR',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    rows: [
                      DataRow(
                        color: WidgetStateProperty.all(Colors.grey[200]),
                        cells: [
                          const DataCell(
                            Text(
                              'MOTOR INALAMBRICO 4K 120 GIGAS,\nRUEDA REDONDA GIGANTE,\nREPUESTO #3212...',
                            ),
                          ),
                          const DataCell(Text('02/02/2002')),
                          const DataCell(Icon(Icons.arrow_drop_down, size: 40)),
                        ],
                      ),
                    ],
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
