import 'package:flutter/material.dart';
import 'package:ferros_cerna/core/data/supabase_database.dart';
import 'package:ferros_cerna/features/clientes/pagina_clientes.dart';
import 'package:ferros_cerna/shared/widgets/menu_lateral.dart';

class PaginaCrearCliente extends StatefulWidget {
  const PaginaCrearCliente({super.key});

  @override
  State<PaginaCrearCliente> createState() => _PaginaCrearClienteState();
}

class _PaginaCrearClienteState extends State<PaginaCrearCliente> {
  final _rutCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _fonoCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _rutCtrl.dispose();
    _nombreCtrl.dispose();
    _fonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrarCliente() async {
    final rut = int.tryParse(_rutCtrl.text.trim());
    final fono = int.tryParse(_fonoCtrl.text.trim());
    final nombre = _nombreCtrl.text.trim();
    if (rut == null || fono == null || nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa RUT, nombre y teléfono válidos.'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await SupabaseDatabase.client.from(SupabaseTables.clientes).insert({
        'rut': rut,
        'nombre': nombre,
        'fono': fono,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el cliente: $error')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: construirAppBar(context, 'Creación de cliente', esPantallaGrande),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'RUT DEL CLIENTE:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  CampoEditable(controlador: _rutCtrl),
                  const SizedBox(height: 20),
                  const Text(
                    'NOMBRE DEL CLIENTE NUEVO:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  CampoEditable(controlador: _nombreCtrl, hint: 'Nombre'),
                  const SizedBox(height: 20),
                  const Text(
                    'TELÉFONO:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  CampoEditable(controlador: _fonoCtrl, hint: 'Teléfono'),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _registrarCliente,
                      icon: const Icon(Icons.download, color: Colors.black),
                      label: const Text(
                        'REGISTRAR',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
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
