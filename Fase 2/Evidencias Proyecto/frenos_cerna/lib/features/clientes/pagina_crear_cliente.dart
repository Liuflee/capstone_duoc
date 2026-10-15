
// Importaciones
import 'package:flutter/material.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';

import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';

import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';

// Se crea la clase PaginaCrearCliente que extiende StatefulWidget
class PaginaCrearCliente extends StatefulWidget {

  // Constructor de la clase
  const PaginaCrearCliente({super.key});

  @override
  State<PaginaCrearCliente> createState() =>
      _PaginaCrearClienteState();
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
          content: Text(
            'Completa RUT, nombre y teléfono válidos.',
          ),
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
      await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .insert({

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
      Navigator.pop(context, true);

    } catch (error) {

      // Comprueba que la página continúe montada
      if (!mounted) return;

      // Muestra un mensaje si ocurre un error al registrar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo registrar el cliente: $error',
          ),
        ),
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
  Widget build(BuildContext context) {

    return Scaffold(

      // Color de fondo de la página
      backgroundColor: Colors.grey[200],

      // Cuerpo de la página
      body: LayoutBuilder(

        // Se obtienen las dimensiones disponibles de la ventana
        builder: (context, constraints) {

          // Dimensiones disponibles de la ventana
          final double ancho = constraints.maxWidth;
          final double alto = constraints.maxHeight;

          // Se crea la distribución vertical de la página
          return Column(
            children: [

              // BARRA SUPERIOR
              SizedBox(
                width: ancho,
                height: alto * 0.10,

                // Se llama el widget de barra superior
                child: const BarraSuperior(
                  tituloPagina: 'Creación de cliente',
                ),
              ),

              // ZONA DE WIDGETS
              Expanded( // Ocupa la altura restante de la página
                child: Row(

                  // Extiende los elementos verticalmente
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    // BARRA LATERAL
                    SizedBox(
                      width: ancho * 0.12,

                      // Se llama el widget del menú lateral
                      // Clientes permanece seleccionado
                      child: const MenuLateral(
                        activo: 'Clientes',
                      ),
                    ),

                    // CONTENIDO PRINCIPAL
                    Expanded( // Ocupa el ancho restante
                      child: Container(

                        // Estilos del contenedor principal
                        width: double.infinity,

                        // Espaciado interior del contenido
                        padding: const EdgeInsets.fromLTRB(
                          20, 12, 20, 20,
                        ),

                        // Permite desplazarse verticalmente
                        // cuando el formulario supera el alto disponible
                        child: SingleChildScrollView(

                          // Espaciado adicional del formulario
                          padding: const EdgeInsets.all(20),

                          // Se distribuyen los formularios verticalmente
                          child: Column(

                            // Centra los elementos horizontalmente
                            crossAxisAlignment:
                                CrossAxisAlignment.center,

                            children: [

                              // FORMULARIO RUT

                              // Separación superior
                              const SizedBox(height: 20),

                              // Título del campo RUT
                              const Text(
                                'RUT DEL CLIENTE:',

                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // Separación entre título y campo
                              const SizedBox(height: 10),

                              // Campo para ingresar el RUT
                              CampoEditable(
                                controlador: _rutCtrl,
                              ),

                              // Separación entre formularios
                              const SizedBox(height: 20),

                              // FORMULARIO NOMBRE

                              // Título del campo nombre
                              const Text(
                                'NOMBRE DEL CLIENTE NUEVO:',

                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // Separación entre título y campo
                              const SizedBox(height: 10),

                              // Campo para ingresar el nombre
                              CampoEditable(
                                controlador: _nombreCtrl,
                                hint: 'Nombre',
                              ),

                              // Separación entre formularios
                              const SizedBox(height: 20),

                              // FORMULARIO TELÉFONO

                              // Título del campo teléfono
                              const Text(
                                'TELÉFONO:',

                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // Separación entre título y campo
                              const SizedBox(height: 10),

                              // Campo para ingresar el teléfono
                              CampoEditable(
                                controlador: _fonoCtrl,
                                hint: 'Teléfono',
                              ),

                              // Separación entre campos y botón
                              const SizedBox(height: 40),

                              // BOTÓN REGISTRAR
                              Align(

                                // Sitúa el botón a la derecha
                                alignment: Alignment.centerRight,

                                child: ElevatedButton.icon(

                                  // Desactiva el botón mientras se guarda
                                  // Si no está guardando, permite registrar
                                  onPressed: _guardando
                                      ? null
                                      : _registrarCliente,

                                  // Icono del botón
                                  icon: const Icon(
                                    Icons.download,
                                    color: Colors.black,
                                  ),

                                  // Texto del botón
                                  label: const Text(
                                    'REGISTRAR',

                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  // Estilos del botón
                                  style: ElevatedButton.styleFrom(

                                    // Color de fondo
                                    backgroundColor: Colors.grey[400],

                                    // Espaciado interior
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
                    ),

                  ],
                ),
              ),

            ],
          );

        },
      ),
    );
  }
}
