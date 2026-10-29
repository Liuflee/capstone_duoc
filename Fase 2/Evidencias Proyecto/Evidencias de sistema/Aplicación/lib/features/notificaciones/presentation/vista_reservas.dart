import 'package:frenos_cerna/features/clientes/pagina_crear_cliente.dart'; // Permite crear un cliente y devolverlo a la reserva.
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart'; // Conserva el cliente y su contacto.
import 'package:frenos_cerna/features/clientes/presentation/selector_cliente.dart'; // Reutiliza la búsqueda por nombre o RUT.
import 'package:flutter/material.dart'; // Construye las reservas y su diálogo.
import 'package:frenos_cerna/features/notificaciones/data/reservas_repository.dart'; // Guarda los estados en Supabase.
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart'; // Conserva el marco compartido.
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart'; // Reutiliza la tabla y su búsqueda.
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart'; // Reutiliza el campo de código.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart'; // Conserva los botones del proyecto.

class VistaReservas extends StatefulWidget {
  final Future<List<Cliente>> Function()?
  cargarClientes; // Permite verificar la vinculación sin datos reales.
  final bool
  reservados; // True muestra las reservas listas en la ruta existente.
  final ReservasRepository
  repositorio; // Permite comprobar el flujo sin datos reales.
  const VistaReservas({
    super.key,
    required this.reservados,
    this.cargarClientes,
    this.repositorio = const ReservasRepository(),
  });
  @override
  State<VistaReservas> createState() => _VistaReservasState();
}

class _VistaReservasState extends State<VistaReservas> {
  late Future<List<Map<String, dynamic>>>
  _datos; // Conserva una consulta por carga.
  bool _ocupado = false; // Impide repetir cambios de estado.
  @override
  void initState() {
    super.initState();
    _recargar();
  } // Recupera las reservas persistentes.

  void _recargar() {
    _datos = widget.repositorio.listar(listas: widget.reservados);
  }

  Future<void> _reservar() async {
    final codigo = TextEditingController(); // Conserva el código mientras se completa la reserva.
    final clave = GlobalKey<FormState>(); // Valida el formulario.
    bool guardando = false; // Evita envíos duplicados.
    Cliente? cliente; // Mantiene el cliente elegido sin perder el código.
    String? error; // Mantiene el motivo del error visible.
    try {
      final creada = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogo) => StatefulBuilder(
          builder: (context, actualizar) => PopScope(
            canPop: !guardando,
            child: Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor:
                  Colors.transparent, // Evita tonos ajenos a la aplicación.
              insetPadding: EdgeInsets.fromLTRB(
                24 +
                    (MediaQuery.sizeOf(context).width >= 700
                        ? MediaQuery.sizeOf(context).width * 0.12
                        : 0),
                24,
                24,
                24,
              ), // Centra sobre el área de contenido.
              child: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'RESERVAR PRODUCTO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FormularioDatos(
                          ancho: 392,
                          ajustarAlAnchoDisponible: true,
                          claveFormulario: clave,
                          campos: [
                            CampoFormularioDatos(
                              controlador: codigo,
                              etiqueta: 'CÓDIGO DEL PRODUCTO:',
                              textoAyuda: 'Ej.: SP0-01223',
                              habilitado: !guardando,
                              validador: (valor) => (valor ?? '').trim().isEmpty
                                  ? 'Ingresa el código del producto'
                                  : null,
                            ),
                          ],
                        ), // Admite códigos alfanuméricos.
                        const SizedBox(
                          height: 16,
                        ), // Separa el producto del destinatario.
                        Text(
                          cliente == null
                              ? 'CLIENTE: SIN SELECCIONAR'
                              : 'CLIENTE: ${cliente!.nombre} · RUT: ${cliente!.id}',
                          style: const TextStyle(
                            color: Colors.black, // Usa el negro de las etiquetas de la aplicación.
                            decoration: TextDecoration.none, // Evita heredar el subrayado amarillo del contexto externo al diálogo.
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ), // Mantiene el tamaño de la etiqueta del código sin heredar estilos externos.
                        ), // Identifica a quién corresponde la reserva.
                        const SizedBox(height: 12), // Separa los datos del cliente del botón de vinculación.
                        CartaNavegacion.accion(
                          onPressed: guardando
                              ? null
                              : () async {
                                  final existente = await showDialog<bool>(
                                    context: dialogo,
                                    builder: (opciones) => Dialog(
                                      backgroundColor: Colors.white,
                                      surfaceTintColor: Colors.transparent, // Conserva el fondo compartido.
                                      insetPadding: EdgeInsets.fromLTRB(
                                        24 +
                                            (MediaQuery.sizeOf(opciones)
                                                        .width >=
                                                    700
                                                ? MediaQuery.sizeOf(opciones)
                                                          .width *
                                                      0.12
                                                : 0),
                                        24,
                                        24,
                                        24,
                                      ), // Centra sobre el mismo eje de la reserva.
                                      child: SizedBox(
                                        width: 440,
                                        child: SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'VINCULAR CON CLIENTE',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.black,
                                                  ),
                                                ), // Identifica el paso de vinculación.
                                                const SizedBox(height: 20),
                                                CartaNavegacion.accion(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        opciones,
                                                        true,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.person_search,
                                                  ),
                                                  label: const Text(
                                                    'CLIENTE EXISTENTE',
                                                  ),
                                                ), // Reutiliza la búsqueda por nombre o RUT.
                                                const SizedBox(height: 12),
                                                CartaNavegacion.accion(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        opciones,
                                                        false,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.person_add_alt_1,
                                                  ),
                                                  label: const Text(
                                                    'NUEVO CLIENTE',
                                                  ),
                                                ), // Abre la creación sin perder el código de la reserva.
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                  if (existente == null || !dialogo.mounted) {
                                    return; // Mantiene el cliente anterior al cancelar.
                                  }
                                  final Cliente? elegido = existente
                                      ? await seleccionarClienteExistente(
                                          dialogo,
                                          cargarClientes: widget.cargarClientes,
                                        )
                                      : await Navigator.push<Cliente>(
                                          dialogo,
                                          MaterialPageRoute(
                                            settings: const RouteSettings(
                                              name: '/clients/new',
                                            ),
                                            builder: (_) =>
                                                const PaginaCrearCliente(
                                                  devolverClienteCreado: true,
                                                ),
                                          ),
                                        ); // Vuelve con el cliente creado, igual que en vehículos.
                                  if (dialogo.mounted && elegido != null) {
                                    actualizar(
                                      () => cliente = elegido,
                                    ); // Conserva ambos datos al volver.
                                  }
                                },
                          icon: const Icon(Icons.person_search_outlined),
                          label: const Text('VINCULAR CLIENTE'),
                        ),
                        if (error != null)
                          Text(
                            error!,
                          ), // Conserva el código cuando falla la escritura.
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CartaNavegacion(
                                ancho: 240,
                                alto: 70, // Conserva el alto y comparte el ancho disponible en una misma fila.
                                alPresionar: guardando
                                    ? null
                                    : () => Navigator.pop(dialogo, false),
                                texto: 'CANCELAR',
                              ),
                            ), // Alinea Cancelar al borde inferior izquierdo.
                            const SizedBox(width: 12), // Separa ambas acciones.
                            Expanded(
                              child: CartaNavegacion(
                                ancho: 240,
                                alto: 70, // Comparte el ancho de la fila sin cambiar el alto.
                                alPresionar: guardando
                                    ? null
                                    : () async {
                                        if (!clave.currentState!.validate()) {
                                          return; // Exige un código antes de guardar.
                                        }
                                        if (cliente == null) {
                                          actualizar(
                                            () => error = 'Selecciona el cliente para saber a quién avisar.',
                                          ); // Exige vinculación antes de guardar.
                                          return;
                                        }
                                        actualizar(() {
                                          guardando = true;
                                          error = null;
                                        });
                                        try {
                                          await widget.repositorio.reservar(
                                            codigo.text,
                                            rutCliente: cliente!.id, // Guarda la relación con el cliente seleccionado.
                                          ); // Guarda únicamente la reserva.
                                          if (dialogo.mounted) {
                                            Navigator.pop(dialogo, true);
                                          }
                                        } catch (fallo) {
                                          if (dialogo.mounted) {
                                            actualizar(() {
                                              guardando = false;
                                              error =
                                                  fallo.toString().contains(
                                                    '23505',
                                                  )
                                                  ? 'Este cliente ya tiene una reserva pendiente de este producto.'
                                                  : 'No se pudo reservar: $fallo';
                                            });
                                          }
                                        }
                                      },
                                texto: guardando ? 'GUARDANDO...' : 'RESERVAR',
                              ),
                            ), // Alinea Reservar al borde inferior derecho.
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      if (creada == true && mounted) {
        setState(_recargar); // Actualiza después del guardado real.
      }
    } finally {
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      ); // Espera el cierre de la ventana.
      codigo.dispose(); // Libera el campo al terminar la animación.
    }
  }

  Future<void> _lista(Map<String, dynamic> fila) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('RESERVA LISTA'),
        content: Text('¿El producto ${fila['codigo_producto']} ya está listo?'),
        actions: [
          CartaNavegacion.accion(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('CANCELAR'),
          ),
          CartaNavegacion.accion(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    ); // Confirma el cambio sin borrar la reserva.
    if (confirmar != true || !mounted || _ocupado) return;
    setState(() => _ocupado = true);
    try {
      await widget.repositorio.marcarLista(
        fila['id'] as Object,
      ); // Actualiza el estado de la reserva existente.
      if (mounted) setState(_recargar);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: widget.reservados ? 'Reservas listas' : 'Reservar producto',
    activo: 'Notificaciones',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 16,
          children: [
            CartaNavegacion.accion(
              onPressed: _reservar,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('RESERVAR PRODUCTO'),
            ),
            if (!widget.reservados)
              CartaNavegacion.accion(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(
                        name: '/notifications/reserved',
                      ),
                      builder: (_) => VistaReservas(
                        reservados: true,
                        repositorio: widget.repositorio,
                        cargarClientes: widget.cargarClientes,
                      ),
                    ),
                  ); // Consulta las reservas terminadas.
                  if (mounted) setState(_recargar);
                },
                icon: const Icon(Icons.inventory_outlined),
                label: const Text('RESERVAS LISTAS'),
              )
            else
              CartaNavegacion.accion(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.keyboard_return),
                label: const Text('VOLVER A RESERVAS'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _datos,
            builder: (context, estado) {
              if (estado.hasError) {
                return Column(
                  children: [
                    Text('No se pudieron cargar las reservas: ${estado.error}'),
                    CartaNavegacion.accion(
                      onPressed: () => setState(_recargar),
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                );
              }
              if (!estado.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final filas = estado.data!
                  .map(
                    (fila) => {
                      ...fila,
                      'cliente_visible':
                          (fila['cliente'] as Map?)?['nombre']?.toString() ??
                          fila['rut_cliente']?.toString() ??
                          'Sin cliente',
                      'contacto':
                          (fila['cliente'] as Map?)?['fono']?.toString() ??
                          '', // Muestra a quién se debe avisar.
                      'estado_visible': fila['estado'] == 'lista'
                          ? 'LISTA'
                          : 'RESERVADO',
                    },
                  )
                  .toList(); // Presenta los estados en mayúsculas.
              return TablaDatos(
                nombresColumnas: [
                  'PRODUCTO',
                  'CLIENTE',
                  'TELÉFONO',
                  'ESTADO',
                  if (!widget.reservados) 'MARCAR LISTA',
                ],
                camposColumnas: [
                  'codigo_producto',
                  'cliente_visible',
                  'contacto',
                  'estado_visible',
                  if (!widget.reservados) '',
                ],
                anchosColumnas: [3, 3, 2, 2, if (!widget.reservados) 1],
                filas: filas,
                mensajeSinDatos: widget.reservados
                    ? 'No hay reservas listas.'
                    : 'No hay productos reservados.',
                celdasPersonalizadas: {
                  if (!widget.reservados)
                    4: (context, fila) => CartaNavegacion.accion(
                      tipoBoton: 'icon',
                      tooltip: 'Marcar reserva lista',
                      onPressed: _ocupado ? null : () => _lista(fila),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.black,
                      ),
                    ), // Cambia el estado sin eliminar datos.
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
