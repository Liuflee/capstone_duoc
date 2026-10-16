
// Importaciones
import 'package:flutter/material.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';

// Importa el formulario reutilizable y la configuración individual de sus campos.
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';
// Importa la tarjeta que ejecuta el registro fuera del formulario.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

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

                              // Mantiene una separación inicial antes de los campos.
                              const SizedBox(height: 20),
                              // Reutiliza el formulario con una columna y filas automáticas.
                              FormularioDatos(
                                campos: [ // Define los campos en el orden de presentación.
                                  CampoFormularioDatos(
                                    controlador: _rutCtrl, // Conserva el valor utilizado al registrar el cliente.
                                    etiqueta: 'RUT DEL CLIENTE:', // Muestra el título encima del campo.
                                    textoAyuda: 'RUT', // Indica el dato solicitado dentro del campo vacío.
                                    tipoTeclado: TextInputType.number, // Facilita el ingreso del RUT numérico actual.
                                    habilitado: !_guardando, // Evita cambiar el dato mientras se registra.
                                  ), // Finaliza la configuración del RUT.
                                  CampoFormularioDatos(
                                    controlador: _nombreCtrl, // Conserva el controlador del nombre.
                                    etiqueta: 'NOMBRE DEL CLIENTE NUEVO:', // Conserva el título del formulario anterior.
                                    textoAyuda: 'Nombre', // Conserva la ayuda interior del campo.
                                    tipoTeclado: TextInputType.name, // Utiliza el teclado apropiado para nombres.
                                    habilitado: !_guardando, // Evita cambios mientras se registra.
                                  ), // Finaliza la configuración del nombre.
                                  CampoFormularioDatos(
                                    controlador: _fonoCtrl, // Conserva el controlador del teléfono.
                                    etiqueta: 'TELÉFONO:', // Conserva la etiqueta externa del teléfono.
                                    textoAyuda: 'Teléfono', // Conserva la ayuda interior del campo.
                                    tipoTeclado: TextInputType.phone, // Facilita el ingreso del teléfono en Android.
                                    habilitado: !_guardando, // Evita cambios mientras se registra.
                                  ), // Finaliza la configuración del teléfono.
                                ], // Finaliza los campos; las filas se calculan automáticamente.
                              ), // Finaliza el formulario reutilizable sin botones propios.
                              const SizedBox(height: 40), // Separa el formulario de la acción de registro.
                              Align(
                                alignment: Alignment.centerRight, // Conserva la acción en el extremo derecho.
                                child: CartaNavegacion(
                                  ancho: 240, // Comparte el ancho de la tarjeta de añadir cliente.
                                  alto: 70, // Mantiene espacio suficiente para el icono y el texto.
                                  texto: _guardando ? 'GUARDANDO...' : 'REGISTRAR', // Informa si hay un registro en curso.
                                  icono: Icons.download, // Conserva el icono de la acción anterior.
                                  color: Colors.grey[400], // Conserva el color de la acción anterior.
                                  alPresionar: _guardando ? null : _registrarCliente, // Registra desde la tarjeta externa y evita pulsaciones simultáneas.
                                ), // Finaliza la tarjeta que registra el cliente.
                              ), // Finaliza la alineación de la acción externa.
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
