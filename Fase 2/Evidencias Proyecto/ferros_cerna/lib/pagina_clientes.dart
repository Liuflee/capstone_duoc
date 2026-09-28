import 'package:ferros_cerna/data/supabase_database.dart';
import 'package:flutter/material.dart';

import 'pagina_crear_cliente.dart';
import 'pagina_editar_cliente.dart';
import 'menu_lateral.dart';

// ============================================================
// MODELO CLIENTE
// ============================================================

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

// ============================================================
// PÁGINA CLIENTES
// ============================================================

class PaginaClientes extends StatefulWidget {
  const PaginaClientes({super.key});

  @override
  State<PaginaClientes> createState() => _PaginaClientesState();
}

class _PaginaClientesState extends State<PaginaClientes> {
  // ==========================================================
  // VARIABLES
  // ==========================================================

  List<Cliente> clientes = [];
  List<Cliente> clientesFiltrados = [];

  bool _cargando = true;
  String? _error;

  final TextEditingController _busquedaController =
      TextEditingController();

  // ==========================================================
  // INICIALIZACIÓN
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  // ==========================================================
  // LIBERAR CONTROLADORES
  // ==========================================================

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  // ==========================================================
  // CARGAR CLIENTES
  // ==========================================================

  Future<void> _cargarClientes() async {
    try {
      final response = await SupabaseDatabase.client
          .from(SupabaseTables.clientes)
          .select('rut, nombre, fono')
          .order('nombre');

      final data = response as List<dynamic>;

      if (!mounted) return;

      final listaClientes = data
          .map(
            (item) => Cliente.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      setState(() {
        clientes = listaClientes;
        clientesFiltrados = List.from(listaClientes);
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

  // ============================================================
  // BUSCAR CLIENTES
  // ============================================================

  void _buscarClientes() {
    final texto =
        _busquedaController.text.trim().toLowerCase();

    setState(() {
      if (texto.isEmpty) {
        clientesFiltrados = List.from(clientes);
      } else {
        clientesFiltrados = clientes.where((cliente) {
          final nombre =
              cliente.nombre.toLowerCase();

          final rut =
              cliente.id.toLowerCase();

          final numero =
              cliente.numero.toLowerCase();

          return nombre.contains(texto) ||
              rut.contains(texto) ||
              numero.contains(texto);
        }).toList();
      }
    });
  }

// ============================================================
// BORRAR CLIENTE
// ============================================================

Future<void> _borrarCliente(Cliente cliente) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.black,

      // ========================================================
      // TÍTULO
      // ========================================================

      title: const Text(
        'Borrar cliente',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ========================================================
      // MENSAJE
      // ========================================================

      content: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          children: [
            const TextSpan(
              text: '¿Borrar a ',
            ),

            TextSpan(
              text: cliente.nombre.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const TextSpan(
              text: '?',
            ),
          ],
        ),
      ),

      // ========================================================
      // BOTONES
      // ========================================================

      actions: [

        // ======================================================
        // BOTÓN CANCELAR
        // ======================================================

        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, false);
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
          ),

          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ======================================================
        // BOTÓN BORRAR
        // ======================================================

        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),

          child: const Text(
            'Borrar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmar != true || !mounted) return;

  try {
    await SupabaseDatabase.client
        .from(SupabaseTables.clientes)
        .delete()
        .eq(
          'rut',
          int.parse(cliente.id),
        );

    await _cargarClientes();
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No se pudo borrar el cliente: $error',
        ),
      ),
    );
  }
}

  // ============================================================
  // CONSTRUIR PÁGINA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande =
        MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: construirAppBar(
        context,
        'Clientes',
        esPantallaGrande,
      ),

      // ========================================================
      // MENÚ LATERAL MÓVIL
      // ========================================================

      drawer: esPantallaGrande
          ? null
          : const Drawer(
              child: MenuLateral(
                activo: 'Clientes',
              ),
            ),

      // ========================================================
      // CONTENIDO PRINCIPAL
      // ========================================================

      body: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // ======================================================
          // MENÚ LATERAL ESCRITORIO
          // ======================================================

          if (esPantallaGrande)
            const ContenedorMenuLateral(
              activo: 'Clientes',
            ),

          // ======================================================
          // ÁREA PRINCIPAL
          // ======================================================

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.all(20.0),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,

                children: [

                  // ==================================================
                  // BOTÓN AÑADIR CLIENTE
                  // ==================================================

                  ElevatedButton.icon(
                    onPressed: () async {
                      final actualizado =
                          await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PaginaCrearCliente(),
                        ),
                      );

                      if (actualizado == true) {
                        _cargarClientes();
                      }
                    },

                    icon: const Icon(
                      Icons.person_add_alt_1,
                      color: Colors.black,
                    ),

                    label: const Text(
                      '+ Añadir cliente',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.grey[400],

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                

                  // ==================================================
                  // BUSCADOR
                  // ==================================================

                  Container(
                    width: 300,
                    color: Colors.grey[300],

                    padding: const EdgeInsets.only(
                      left: 10,
                    ),

                    child: Row(
                      children: [

                        Expanded(
                          child: TextField(
                            controller: _busquedaController,

                            decoration: const InputDecoration(
                              hintText: 'BUSCAR CLIENTE',
                              border: InputBorder.none,
                            ),

                            // ==================================================
                            // BÚSQUEDA AUTOMÁTICA
                            // ==================================================

                            onChanged: (_) {
                              _buscarClientes();
                            },
                          ),
                        ),

                        // ==================================================
                        // BOTÓN DECORATIVO
                        // ==================================================

                        IconButton(
                          onPressed: null,

                          icon: const Icon(
                            Icons.search,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // SEPARACIÓN ENTRE BUSCADOR Y TABLA
                  // ==================================================

                  const SizedBox(height: 20),

                  // ==================================================
                  // MENSAJE DE ERROR
                  // ==================================================

                  if (_error != null)
                    Text(
                      'Error al cargar clientes: $_error',
                    ),



                  // ==================================================
                  // MENSAJE DE ERROR
                  // ==================================================

                  if (_error != null)
                    Text(
                      'Error al cargar clientes: $_error',
                    ),

                  // ==================================================
                  // CARGANDO / TABLA
                  // ==================================================

                  if (_cargando)
                    const Expanded(
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    )
                  else
                    Expanded(
                      child:
                          _ConstruirTablaClientes(
                        clientes:
                            clientesFiltrados,

                        onEditar:
                            (cliente) async {
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

                        onBorrar:
                            _borrarCliente,
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

// ============================================================
// TABLA DE CLIENTES
// ============================================================

class _ConstruirTablaClientes
    extends StatelessWidget {
  final List<Cliente> clientes;

  final Future<void> Function(Cliente)
      onEditar;

  final Future<void> Function(Cliente)
      onBorrar;

  const _ConstruirTablaClientes({
    required this.clientes,
    required this.onEditar,
    required this.onBorrar,
  });

  // ============================================================
  // CONSTRUIR TABLA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {

        // ========================================================
        // ANCHO DE LA TABLA
        // ========================================================

        const double anchoMinimoTabla = 850;

        final double anchoTabla =
            constraints.maxWidth >
                    anchoMinimoTabla
                ? constraints.maxWidth
                : anchoMinimoTabla;

        // ========================================================
        // ANCHO DE COLUMNAS FIJAS
        //
        // NÚMERO  = 150
        // RUT     = 150
        // CAMBIAR = 145
        // BORRAR  = 145
        //
        // TOTAL = 590
        // ========================================================

        final double anchoNombre =
            anchoTabla - 590;

        // ========================================================
        // SCROLL HORIZONTAL
        // ========================================================

        return SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,

          child: SizedBox(
            width: anchoTabla,

            child: CustomScrollView(
              slivers: [

                // ==================================================
                // ENCABEZADO FIJO
                // ==================================================

                SliverPersistentHeader(
                  pinned: true,

                  delegate:
                      _EncabezadoTablaDelegate(
                    child:
                        _crearEncabezado(
                      anchoNombre,
                    ),
                  ),
                ),

                // ==================================================
                // FILAS
                // ==================================================

                SliverList(
                  delegate:
                      SliverChildBuilderDelegate(
                    (context, index) {

                      final cliente =
                          clientes[index];

                      return _crearFila(
                        context,
                        cliente,
                        index,
                        anchoNombre,
                      );
                    },

                    childCount:
                        clientes.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ENCABEZADO DE LA TABLA
  // ============================================================

  Widget _crearEncabezado(
    double anchoNombre,
  ) {
    return Container(
      color: Colors.red[400],

      child: Row(
        children: [

          // ======================================================
          // COLUMNA NOMBRE
          // ======================================================

          SizedBox(
            width: anchoNombre,

            child: Container(
              height: 56,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  top: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.centerLeft,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),

              child: const Text(
                'NOMBRE',

                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          // ======================================================
          // COLUMNA NÚMERO
          // ======================================================

          SizedBox(
            width: 150,

            child: Container(
              height: 56,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  top: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: const Text(
                'NÚMERO',

                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          // ======================================================
          // COLUMNA RUT
          // ======================================================

          SizedBox(
            width: 150,

            child: Container(
              height: 56,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  top: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: const Text(
                'RUT',

                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          // ======================================================
          // COLUMNA CAMBIAR
          // ======================================================

          SizedBox(
            width: 145,

            child: Container(
              height: 56,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  top: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: const Text(
                'CAMBIAR',

                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          // ======================================================
          // COLUMNA BORRAR
          // ======================================================

          SizedBox(
            width: 145,

            child: Container(
              height: 56,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  right: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  top: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: const Text(
                'BORRAR',

                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILA DE CLIENTE
  // ============================================================

  Widget _crearFila(
    BuildContext context,
    Cliente cliente,
    int index,
    double anchoNombre,
  ) {

    // ==========================================================
    // COLOR ALTERNADO DE LAS FILAS
    // ==========================================================

    final color =
        index % 2 == 0
            ? Colors.grey[200]
            : Colors.grey[300];

    return Container(
      height: 70,
      color: color,

      child: Row(
        children: [

          // ======================================================
          // COLUMNA NOMBRE
          // ======================================================

          SizedBox(
            width: anchoNombre,

            child: Container(
              height: 70,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
              ),

              child: Row(
                children: [

                  // ------------------------------------------------
                  // ICONO DEL CLIENTE
                  // ------------------------------------------------

                  CircleAvatar(
                    backgroundColor:
                        Colors.red[300],

                    child: const Icon(
                      Icons.person,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ------------------------------------------------
                  // NOMBRE DEL CLIENTE
                  // ------------------------------------------------

                  Expanded(
                    child: Text(
                      cliente.nombre,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // COLUMNA NÚMERO
          // ======================================================

          SizedBox(
            width: 150,

            child: Container(
              height: 70,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: Text(
                cliente.numero,

                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          ),

          // ======================================================
          // COLUMNA RUT
          // ======================================================

          SizedBox(
            width: 150,

            child: Container(
              height: 70,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: Text(
                cliente.id,

                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          ),

          // ======================================================
          // COLUMNA CAMBIAR
          // ======================================================

          SizedBox(
            width: 145,

            child: Container(
              height: 70,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 30,
                ),

                onPressed: () {
                  onEditar(cliente);
                },
              ),
            ),
          ),

          // ======================================================
          // COLUMNA BORRAR
          // ======================================================

          SizedBox(
            width: 145,

            child: Container(
              height: 70,

              decoration:
                  const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  right: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: IconButton(
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: 30,
                ),

                onPressed: () {
                  onBorrar(cliente);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ENCABEZADO FIJO DE LA TABLA
// ============================================================

class _EncabezadoTablaDelegate
    extends SliverPersistentHeaderDelegate {
  final Widget child;

  _EncabezadoTablaDelegate({
    required this.child,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(
    covariant _EncabezadoTablaDelegate oldDelegate,
  ) {
    return oldDelegate.child != child;
  }
}

// ============================================================
// APP BAR
// ============================================================

PreferredSizeWidget construirAppBar(
  BuildContext context,
  String titulo,
  bool esPantallaGrande,
) {
  return AppBar(
    backgroundColor: Colors.grey[300],
    elevation: 0,

    title: Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [

        // ======================================================
        // LOGO Y NOMBRE DE LA EMPRESA
        // ======================================================

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

                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),

        // ======================================================
        // TÍTULO DE LA PÁGINA
        // ======================================================

        Text(
          titulo,

          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),

        // ======================================================
        // USUARIO
        // ======================================================

        Row(
          children: [

            if (esPantallaGrande)
              const Text(
                'Leonardo',

                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),

            const SizedBox(width: 10),

            CircleAvatar(
              backgroundColor:
                  Colors.red[800],

              child: const Icon(
                Icons.build,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ============================================================
// CAMPO EDITABLE
// ============================================================

class CampoEditable
    extends StatelessWidget {
  final TextEditingController? controlador;
  final String? hint;

  const CampoEditable({
    super.key,
    this.controlador,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      color: Colors.grey[300],

      child: Row(
        children: [

          // ====================================================
          // CAMPO DE TEXTO
          // ====================================================

          Expanded(
            child: TextField(
              controller: controlador,

              decoration:
                  InputDecoration(
                hintText: hint,
                border:
                    InputBorder.none,

                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
              ),

              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ),

          // ====================================================
          // ICONO EDITAR
          // ====================================================

          Container(
            color: Colors.grey[400],

            padding:
                const EdgeInsets.all(8),

            child: const Icon(
              Icons.edit_square,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}