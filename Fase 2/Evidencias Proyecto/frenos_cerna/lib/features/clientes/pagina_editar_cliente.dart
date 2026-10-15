// Importaciones de Flutter y los componentes del proyecto
import 'package:flutter/material.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';

import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';

// Se crea la página de edición, que recibe el cliente seleccionado
class PaginaEditarCliente extends StatefulWidget {

  // Cliente cuyos datos se mostrarán y podrán modificarse
  final Cliente cliente;

  // Constructor de la página
  const PaginaEditarCliente({
    super.key,
    required this.cliente,
  });

  @override
  State<PaginaEditarCliente> createState() => _PaginaEditarClienteState();
}

// Se crea el estado para administrar los campos y las operaciones de Supabase
class _PaginaEditarClienteState extends State<PaginaEditarCliente> {

  // Controladores de los campos que pueden editarse
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _fonoCtrl;

  // Evita que se repitan las operaciones mientras se guarda o elimina
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    // Se cargan los datos originales en los campos del formulario
    _nombreCtrl = TextEditingController(text: widget.cliente.nombre);
    _fonoCtrl = TextEditingController(text: widget.cliente.numero);
  }

  @override
  void dispose() {

    // Libera los controladores cuando se cierra la página
    _nombreCtrl.dispose();
    _fonoCtrl.dispose();

    super.dispose();
  }

  // Se crea la función para actualizar los datos del cliente en Supabase
  Future<void> _guardarCliente() async {

    // Obtiene el nombre y el teléfono ingresados en el formulario
    final String nombre = _nombreCtrl.text.trim();
    final int? fono = int.tryParse(_fonoCtrl.text.trim());

    // Comprueba que los campos tengan valores válidos
    if (fono == null || nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un nombre y teléfono válidos.'),
        ),
      );
      return;
    }

    // Deshabilita los botones mientras se envían los datos
    setState(() {
      _guardando = true;
    });

    try {

      // Actualiza el registro identificado por su RUT
      await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .update({
            'nombre': nombre,
            'fono': fono,
          })
          .eq('rut', int.parse(widget.cliente.id));

      // Evita utilizar el contexto si la página ya fue cerrada
      if (!mounted) return;

      // Vuelve a Clientes e indica que el listado debe actualizarse
      Navigator.pop(context, true);

    } catch (error) {

      if (!mounted) return;

      // Informa si la actualización no se completó
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el cliente: $error'),
        ),
      );

    } finally {

      // Vuelve a habilitar los botones si la página continúa abierta
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // Se crea la función para borrar el cliente de Supabase
  Future<void> _borrarCliente() async {

    // Deshabilita las acciones mientras se realiza la eliminación
    setState(() {
      _guardando = true;
    });

    try {

      // Borra el registro correspondiente al RUT del cliente
      await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .delete()
          .eq('rut', int.parse(widget.cliente.id));

      if (!mounted) return;

      // Regresa a Clientes para actualizar el listado
      Navigator.pop(context, true);

    } catch (error) {

      if (!mounted) return;

      // Muestra el error cuando Supabase no puede eliminar el cliente
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo borrar el cliente: $error'),
        ),
      );

    } finally {

      // Restablece el estado de los botones si la página sigue abierta
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // Se recupera el cliente recibido por el constructor
    final Cliente cliente = widget.cliente;

    return Scaffold(

      // Se mantiene el fondo de las otras páginas de Frenos Cerna
      backgroundColor: Colors.grey[200],

      // Se calculan las dimensiones de la ventana
      body: LayoutBuilder(
        builder: (context, constraints) {

          final double ancho = constraints.maxWidth;
          final double alto = constraints.maxHeight;

          // Se organiza la página verticalmente
          return Column(
            children: [

              // BARRA SUPERIOR
              SizedBox(
                width: ancho,
                height: alto * 0.10,

                // El título muestra el nombre del cliente seleccionado
                child: BarraSuperior(
                  tituloPagina: 'Cliente “${cliente.nombre}”',
                ),
              ),

              // ZONA DE WIDGETS
              Expanded(
                child: Row(

                  // Hace que el menú y el contenido utilicen toda la altura
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    // BARRA LATERAL
                    SizedBox(
                      width: ancho * 0.12,

                      // Mantiene seleccionada la sección Clientes
                      child: const MenuLateral(
                        activo: 'Clientes',
                      ),
                    ),

                    // CONTENIDO PRINCIPAL
                    Expanded(
                      child: Container(
                        width: double.infinity,

                        // Deja un espacio interior similar al de Inicio
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

                        // Permite calcular el alto disponible para el historial
                        child: LayoutBuilder(
                          builder: (context, espacio) {

                            final double altoContenido = espacio.maxHeight;

                            // Limita la altura de la tabla para que no ocupe
                            // toda la pantalla y pueda desplazarse internamente
                            final double altoTabla =
                                (altoContenido * 0.40)
                                    .clamp(180.0, 360.0)
                                    .toDouble();

                            // Permite desplazar el formulario completo
                            // si la ventana ofrece poco espacio vertical
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(20),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,

                                children: [

                                  // INFORMACIÓN Y EDICIÓN DEL CLIENTE
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [

                                      // Información del vehículo y campos editables
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,

                                          children: [

                                            // Título de la información del vehículo
                                            const Text(
                                              'VEHÍCULO DEL CLIENTE:',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 10),

                                            // Vehículo registrado y opción de revisión
                                            Wrap(
                                              spacing: 10,
                                              runSpacing: 10,
                                              crossAxisAlignment: WrapCrossAlignment.center,

                                              children: [

                                                // Muestra el vehículo asociado al cliente
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

                                                // Revisión pendiente de implementar
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  color: Colors.grey[400],

                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
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

                                            // Campo para modificar el nombre del cliente
                                            CampoEditable(
                                              controlador: _nombreCtrl,
                                              hint: 'Nombre',
                                            ),

                                            const SizedBox(height: 20),

                                            // Campo para modificar el teléfono del cliente
                                            CampoEditable(
                                              controlador: _fonoCtrl,
                                              hint: 'Teléfono',
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 20),

                                      // Resumen del cliente y botón para eliminarlo
                                      Column(
                                        children: [

                                          // Avatar del cliente
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

                                          // Nombre actual del cliente
                                          Text(
                                            cliente.nombre,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          // Teléfono actual del cliente
                                          Text(
                                            cliente.numero,
                                            style: const TextStyle(fontSize: 16),
                                          ),

                                          const SizedBox(height: 20),

                                          // Botón que elimina el cliente en Supabase
                                          ElevatedButton.icon(
                                            onPressed: _guardando
                                                ? null
                                                : _borrarCliente,

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

                                  // BOTÓN GUARDAR CAMBIOS
                                  Align(
                                    alignment: Alignment.centerRight,

                                    child: ElevatedButton.icon(
                                      onPressed: _guardando
                                          ? null
                                          : _guardarCliente,

                                      icon: const Icon(
                                        Icons.save,
                                        color: Colors.black,
                                      ),

                                      label: const Text('GUARDAR CAMBIOS'),
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // HISTORIAL DE VENTAS
                                  const Text(
                                    'HISTORIAL DE VENTAS',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Se reutiliza TablaDatos con tres columnas
                                  // Los registros siguen siendo de ejemplo
                                  // hasta conectar el historial con Supabase
                                  SizedBox(
                                    height: altoTabla,

                                    child: TablaDatos(
                                      nombresColumnas: const [
                                        'NOMBRE PRODUCTO',
                                        'FECHA',
                                        'EXPANDIR',
                                      ],

                                      // EXPANDIR no utiliza un campo de datos
                                      // porque se construye con un icono
                                      camposColumnas: const [
                                        'producto',
                                        'fecha',
                                        '',
                                      ],

                                      // Proporciones del ancho de las columnas
                                      anchosColumnas: const [
                                        550,
                                        160,
                                        130,
                                      ],

                                      // Datos demostrativos de la tabla original
                                      filas: const [
                                        {
                                          'producto':
                                              'MOTOR INALAMBRICO 4K 120 GIGAS,\n'
                                              'RUEDA REDONDA GIGANTE,\n'
                                              'REPUESTO #3212...',
                                          'fecha': '02/02/2002',
                                        },
                                      ],

                                      // Reemplaza la última celda por un icono
                                      // sin asignarle una acción todavía
                                      celdasPersonalizadas: {
                                        2: (context, fila) => const Icon(
                                          Icons.arrow_drop_down,
                                          size: 40,
                                        ),
                                      },

                                      // Mantiene el historial dentro de su altura
                                      altoFila: 90,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
