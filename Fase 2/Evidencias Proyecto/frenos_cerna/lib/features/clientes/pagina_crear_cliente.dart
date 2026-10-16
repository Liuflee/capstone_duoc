// Devuelve el cliente creado al flujo que lo solicita.
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
// Compone la página con los widgets existentes.
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
// Importaciones
import 'package:flutter/material.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';

// Importa el formulario reutilizable y la configuración individual de sus campos.
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';
// Importa la tarjeta que ejecuta el registro fuera del formulario.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

// Se crea la clase PaginaCrearCliente que extiende StatefulWidget
class PaginaCrearCliente extends StatefulWidget {
  // Constructor de la clase
  final bool devolverClienteCreado; // Permite volver con el cliente al registro de vehículo.
  const PaginaCrearCliente({super.key, this.devolverClienteCreado = false});

  @override
  State<PaginaCrearCliente> createState() => _PaginaCrearClienteState();
}

// Se crea la clase que administra el estado de la página
class _PaginaCrearClienteState extends State<PaginaCrearCliente> {
  // Controladores que almacenan los valores de los formularios
  final _rutCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _fonoCtrl = TextEditingController();

  // Indica si se está registrando un cliente
  // Se utiliza para evitar múltiples registros simultáneos
  bool _guardando = false;

  @override
  void dispose() {
    // Se liberan los recursos de los controladores
    // cuando la página deja de utilizarse
    _rutCtrl.dispose();
    _nombreCtrl.dispose();
    _fonoCtrl.dispose();

    super.dispose();
  }

  // Se crea la función para registrar un cliente
  Future<void> _registrarCliente() async {
    // Evita registros duplicados si se vuelve a activar la acción mientras guarda.
    if (_guardando) return;

    // Recupera los valores ingresados en los formularios
    // trim elimina los espacios al inicio y al final
    final rut = int.tryParse(_rutCtrl.text.trim());
    final fono = int.tryParse(_fonoCtrl.text.trim());
    final nombre = _nombreCtrl.text.trim();

    // Comprueba que los campos tengan valores válidos
    // Por ahora RUT y teléfono deben ser valores numéricos
    if (rut == null || fono == null || nombre.isEmpty) {
      // Muestra un mensaje cuando falta información
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa RUT, nombre y teléfono válidos.'),
        ),
      );

      // Detiene el registro si la validación falla
      return;
    }

    // Actualiza el estado para indicar que se está guardando
    setState(() {
      _guardando = true;
    });

    try {
      // Se conecta con Supabase y registra el nuevo cliente
      await SupabaseDatabase.client.from(SupabaseTables.clientes).insert({
        // Datos que se enviarán a la tabla clientes
        'rut': rut,
        'nombre': nombre,
        'fono': fono,
      });

      // Comprueba que la página continúe montada
      if (!mounted) return;

      // Regresa a la página anterior
      // Envía true para indicar que se registró un cliente
      // La página de clientes podrá actualizar su listado
      Navigator.pop(
        context,
        widget.devolverClienteCreado
            ? Cliente(
                id: rut.toString(),
                nombre: nombre,
                numero: fono.toString(),
                ultimaVenta: 'No disponible',
                vehiculo: 'Sin registrar',
              )
            : true,
      ); // Conserva el resultado anterior y devuelve el cliente al flujo de vinculación.
    } catch (error) {
      // Comprueba que la página continúe montada
      if (!mounted) return;

      // Muestra un mensaje si ocurre un error al registrar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el cliente: $error')),
      );
    } finally {
      // Restablece el estado del botón si la página sigue activa
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Creación de cliente',
    activo: 'Clientes', // Conserva el encabezado del prototipo.
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CartaNavegacion.accion(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.keyboard_return),
              label: const Text('VOLVER A CLIENTES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2A0A0),
                foregroundColor: Colors.black,
              ),
            ),
          ), // Permite volver sin registrar.
          const SizedBox(
            height: 42,
          ), // Sustituye el espacio de la imagen que se decidió omitir.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: FormularioDatos(
                ancho: 1250,
                separacionFilas: 24,
                campos: [
                  CampoFormularioDatos(
                    controlador: _nombreCtrl,
                    etiqueta: 'NOMBRE DEL CLIENTE NUEVO:',
                    textoAyuda: 'Editar nombre',
                    habilitado: !_guardando,
                  ), // Conserva el nombre de Figma.
                  CampoFormularioDatos(
                    controlador: _fonoCtrl,
                    etiqueta: 'NÚMERO DEL CLIENTE NUEVO:',
                    textoAyuda: 'Editar número',
                    tipoTeclado: TextInputType.phone,
                    habilitado: !_guardando,
                  ), // Conserva el teléfono.
                  CampoFormularioDatos(
                    controlador: _rutCtrl,
                    etiqueta: 'RUT DEL CLIENTE:',
                    textoAyuda: 'RUT numérico',
                    tipoTeclado: TextInputType.number,
                    habilitado: !_guardando,
                  ), // Conserva la clave requerida por la base actual.
                ],
              ),
            ),
          ), // Alinea los campos sin cambiar su widget.
          const SizedBox(height: 32), // Separa la acción del formulario.
          Align(
            alignment: Alignment.centerRight,
            child: CartaNavegacion(
              ancho: 240,
              alto: 70,
              texto: _guardando ? 'GUARDANDO...' : 'REGISTRAR',
              icono: Icons.download,
              color: const Color(0xFFB7B7B7),
              alPresionar: _guardando ? null : _registrarCliente,
            ),
          ), // Mantiene el registro en la esquina inferior derecha.
        ],
      ),
    ), // Permite desplazar el registro en Android.
  ); // Finaliza la composición.
}
