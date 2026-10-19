import 'package:frenos_cerna/shared/widgets/panel_filtros.dart'; // Comparte el margen de la barra de desplazamiento con la tabla.
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart'; // Conserva las ventas antes de confirmar el pago.
// Espera antes de consultar un RUT ingresado.
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart'; // Usa el cliente seleccionado por su RUT.
import 'package:frenos_cerna/features/clientes/pagina_crear_cliente.dart'; // Crea un cliente y regresa a la venta.

// Compone la página sin modificar los widgets compartidos.
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
// Importa las tablas compartidas del inventario y el carrito.
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart';
// Importa la barra superior común a las páginas.

// Importa los campos de formulario reutilizables.
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';
// Importa las cartas que conservan las acciones de la página.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';
import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';

// ============================================================================
// MODELOS DE DATOS (Preparados para Supabase)
// ============================================================================

class ProductoVenta {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;

  ProductoVenta({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
  });

  factory ProductoVenta.fromJson(Map<String, dynamic> json) {
    final codigo = json['codigo_producto']?.toString() ?? 'sin-codigo';
    final codigoBarra = json['cod_barra']?.toString() ?? '';
    final tipo = json['tipo_producto'];

    return ProductoVenta(
      id: codigo,
      nombre: codigoBarra.isEmpty ? codigo : codigoBarra,
      categoria: tipo is Map
          ? (tipo['nombre_tipo'] ?? 'Sin categoría').toString()
          : (json['tipo']?.toString() ?? 'Sin categoría'),
      precio: double.tryParse(json['precio']?.toString() ?? '') ?? 0,
      stock: int.tryParse(json['stock']?.toString() ?? '') ?? 0,
    );
  }
}

// ============================================================================
// INTERFAZ DE LA PÁGINA
// ============================================================================

class PaginaCrearVenta extends StatefulWidget {
  final Future<List<ProductoVenta>> Function()? cargarProductos; // Permite verificar la selección con una fuente controlada sin escribir en la base.
  final Future<List<Cliente>> Function()?
  cargarClientes; // Permite comprobar la búsqueda con datos controlados.
  final VentaPendiente? pendiente; // Permite editar una venta local existente.
  final VentasPendientesRepository?
  repositorioPendientes; // Permite verificar el flujo sin escrituras remotas.
  const PaginaCrearVenta({
    super.key,
    this.cargarProductos,
    this.cargarClientes,
    this.pendiente, // Recibe el borrador sin crear una venta nueva.
    this.repositorioPendientes, // Conserva el mismo almacenamiento durante la edición.
  });

  @override
  State<PaginaCrearVenta> createState() => _PaginaCrearVentaState();
}

class _PaginaCrearVentaState extends State<PaginaCrearVenta> {
  VentasPendientesRepository get _repositorio =>
      widget.repositorioPendientes ??
      VentasPendientesRepository
          .instancia; // Usa el repositorio del usuario actual.
  Cliente? _cliente; // Conserva el cliente vinculado a la venta.
  final _busquedaCliente =
      TextEditingController(); // Conserva la búsqueda por nombre o RUT.
  final _menuClientes = MenuController(); // Controla el desplegable.
  late Future<List<Cliente>> _clientes; // Conserva la consulta del catálogo.
  final _patenteVehiculoCtrl = TextEditingController();

  // La búsqueda del inventario la administra su TablaDatos.

  final List<ProductoVenta> _inventario = [];

  bool _cargandoInventario = true;
  bool _guardando = false;
  String? _errorInventario;

  // Estado del carrito de compras actual
  final List<ProductoVenta> _carrito = [];

  @override
  void initState() {
    super.initState();

    final pendiente = widget.pendiente; // Recupera los datos al editar.
    if (pendiente != null) {
      // Restaura la venta antes de consultar catálogos.
      _cliente = Cliente(
        id: pendiente.rutCliente,
        nombre: pendiente.nombreCliente,
        numero: pendiente.fonoCliente,
        ultimaVenta: '',
        vehiculo: pendiente.patente,
      ); // Selecciona al cliente guardado.
      _patenteVehiculoCtrl.text = pendiente.patente; // Restaura la patente.
      for (final articulo in pendiente.articulos) {
        // Recupera todas las unidades del carrito.
        for (var unidad = 0; unidad < articulo.cantidad; unidad++) {
          // Conserva la cantidad exacta.
          _carrito.add(
            ProductoVenta(
              id: articulo.codigo,
              nombre: articulo.nombre,
              categoria: articulo.categoria,
              precio: articulo.precio,
              stock: articulo.stock,
            ),
          ); // Restituye la unidad editable.
        } // Finaliza las unidades.
      } // Finaliza los artículos.
    } // Finaliza la restauración.
    _cargarInventario();

    _clientes = _consultarClientes();
    _clientes.ignore(); // Conserva el error para el menú sin generar excepciones antes de abrirlo. // Recupera el catálogo al abrir la venta.
  }

  Future<List<Cliente>> _consultarClientes() async {
    // Recupera clientes existentes.
    if (widget.cargarClientes != null) {
      return widget.cargarClientes!(); // Permite pruebas sin conexión.
    }
    final filas = await SupabaseDatabase.client
        .from(SupabaseTables.clientes)
        .select(
          'rut, nombre, fono, vehiculo_cliente(patente, modelo_vehiculo(modelo, marca_vehiculo(marca)))',
        )
        .order('nombre'); // Consulta las columnas existentes.
    return filas
        .map((fila) => Cliente.fromJson(Map<String, dynamic>.from(fila)))
        .toList(); // Conserva los RUT.
  } // Finaliza la consulta.

  Future<void> _crearCliente() async {
    // Conserva la venta durante el registro.
    _menuClientes.close(); // Cierra el desplegable.
    final cliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/clients/new'),
        builder: (context) =>
            const PaginaCrearCliente(devolverClienteCreado: true),
      ),
    ); // Espera el cliente creado.
    if (!mounted || cliente == null) return; // Conserva el estado al cancelar.
    setState(() {
      // Actualiza solamente el cliente.
      _cliente = cliente; // Selecciona automáticamente el cliente nuevo.
      _busquedaCliente.clear(); // Limpia la búsqueda.
      _clientes = _consultarClientes();
      _clientes.ignore(); // Conserva el error para el menú sin generar excepciones antes de abrirlo. // Refresca el catálogo.
    }); // Conserva carrito y patente.
  } // Finaliza la creación.

  Widget _selectorCliente() => LayoutBuilder(
    builder: (context, limites) {
      // Adapta el menú al campo.
      return MenuAnchor(
        // Superpone las opciones sobre la página.
        controller: _menuClientes, // Controla el desplegable.
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Color(0xFFE0E0E0)),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ), // Conserva el gris del buscador y elimina el tinte rosado.
        menuChildren: [
          // Contiene búsqueda y selección.
          SizedBox(
            width: limites.maxWidth,
            height: 350,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Limita el tamaño del menú.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final campoBusqueda = SizedBox(
                        height: 56,
                        child: FormularioDatos.campo(
                          controller: _busquedaCliente,
                          decoration: const InputDecoration(
                            hintText: 'Nombre o RUT',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      );
                      final botonCrear = SizedBox(
                        width: 240,
                        height: 56,
                        child: CartaNavegacion.accion(
                          onPressed: _crearCliente,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('CREAR CLIENTE'),
                          conservarEstiloOriginal: true,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBDBDBD),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                          ),
                        ),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'BUSCAR CLIENTE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (constraints.maxWidth >= 520)
                            Row(
                              children: [
                                Expanded(child: campoBusqueda),
                                const SizedBox(width: 12),
                                botonCrear,
                              ],
                            )
                          else ...[
                            campoBusqueda,
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: botonCrear,
                            ),
                          ],
                        ],
                      );
                    },
                  ), // Mantiene el buscador largo y el botón a su lado.
                  const SizedBox(
                    height: 12,
                  ), // Separa la búsqueda de los resultados.
                  Expanded(
                    child: FutureBuilder<List<Cliente>>(
                      future: _clientes,
                      builder: (context, estado) {
                        // Conserva el catálogo durante la búsqueda.
                        if (estado.hasError) {
                          return Column(
                            children: [
                              const Text('No se pudieron cargar los clientes.'),
                              CartaNavegacion.accion(
                                onPressed: () => setState(
                                  () => _clientes = _consultarClientes(),
                                ),
                                child: const Text('REINTENTAR'),
                              ),
                            ],
                          ); // Permite reintentar.
                        }
                        if (!estado.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          ); // Muestra la carga.
                        }
                        final texto = _busquedaCliente.text
                            .trim()
                            .toLowerCase(); // Normaliza el texto.
                        final resultados = estado.data!
                            .where(
                              (cliente) =>
                                  cliente.nombre.toLowerCase().contains(
                                    texto,
                                  ) ||
                                  cliente.id.contains(texto),
                            )
                            .toList(); // Busca por nombre o RUT.
                        if (resultados.isEmpty) {
                          return const Center(
                            child: Text(
                              'No se encontraron clientes. Puedes crear uno.',
                            ),
                          ); // Ofrece registrar el cliente ausente.
                        }
                        return ListView.separated(
                          itemCount: resultados.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x33000000),
                          ),
                          itemBuilder: (context, index) {
                            final cliente = resultados[index];
                            return MenuItemButton(
                              style: ButtonStyle(
                                foregroundColor: const WidgetStatePropertyAll(
                                  Colors.black,
                                ),
                                overlayColor: const WidgetStatePropertyAll(
                                  Color(0x22000000),
                                ),
                                backgroundColor:
                                    WidgetStateProperty.resolveWith(
                                      (estados) =>
                                          estados.contains(
                                                WidgetState.hovered,
                                              ) ||
                                              estados.contains(
                                                WidgetState.focused,
                                              )
                                          ? const Color(0xFFB7B7B7)
                                          : const Color(0xFFE0E0E0),
                                    ),
                              ), // Mantiene selección y foco dentro de la paleta gris.
                              onPressed: () {
                                setState(() => _cliente = cliente);
                                _menuClientes.close();
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${cliente.nombre} · RUT: ${cliente.id}',
                                  ),
                                  if (cliente.vehiculos.isNotEmpty)
                                    Text(
                                      'Vehículos: ${cliente.vehiculos.join(', ')}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            );
                          },
                        ); // Separa las opciones sin cambiar la selección.
                      },
                    ),
                  ), // Finaliza los resultados.
                ],
              ),
            ),
          ), // Finaliza el contenido.
        ], // Finaliza las opciones.
        builder: (context, controlador, child) => InkWell(
          onTap: _guardando
              ? null
              : () {
                  if (controlador.isOpen) {
                    controlador.close();
                  } else {
                    controlador.open();
                  }
                },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'CLIENTE',
              filled: true,
              fillColor: Color(
                0xFFE0E0E0,
              ), // Conserva el fondo gris de los selectores existentes.
              labelStyle: TextStyle(
                color: Colors.black,
              ), // Evita el color rosado del tema.
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              _cliente == null
                  ? 'SELECCIONAR CLIENTE'
                  : '${_cliente!.nombre} · RUT: ${_cliente!.id}',
            ),
          ),
        ), // Presenta un único campo de cliente.
      ); // Finaliza el selector.
    },
  ); // Finaliza la adaptación.

  Future<void> _cargarInventario() async {
    try {
      final List<ProductoVenta> productos;
      if (widget.cargarProductos != null) {
        productos = await widget.cargarProductos!();
      } // Permite comprobar la interfaz sin una conexión real.
      else {
        final data = await SupabaseDatabase.client
            .from(SupabaseTables.productos)
            .select(
              'codigo_producto, cod_barra, stock, tipo, precio, tipo_producto(nombre_tipo)',
            )
            .gt('stock', 0)
            .order('codigo_producto');
        productos = data
            .map(
              (fila) => ProductoVenta.fromJson(Map<String, dynamic>.from(fila)),
            )
            .toList();
      } // Usa la consulta actual en la aplicación.
      if (mounted) {
        setState(() {
          _inventario
            ..clear()
            ..addAll(productos);
          _cargandoInventario = false;
          _errorInventario = null;
        }); // Conserva el inventario recuperado.
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _cargandoInventario = false;
          _errorInventario = error.toString();
        });
      }
    } // Conserva el error de consulta.
  }

  // Abre el inventario sobre la página sin desplazar los datos de la venta.
  Future<void> _abrirSeleccionProductos() async {
    await showDialog<void>(
      context: context,
      builder: (dialogo) => StatefulBuilder(
        builder: (context, actualizarMenu) => Dialog(
          insetPadding: const EdgeInsets.all(
            20,
          ), // Mantiene un margen visible alrededor del menú.
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.88,
            height: MediaQuery.sizeOf(context).height * 0.78,
            child: Padding(
              padding: const EdgeInsets.all(
                20,
              ), // Separa la tabla de los bordes del menú.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'SELECCIÓN DE PRODUCTOS',
                          style: TextStyle(fontSize: 22),
                        ),
                      ), // Identifica el menú de Figma.
                      CartaNavegacion.accion(
                        tipoBoton: 'icon',
                        tooltip: 'Cerrar selección',
                        child: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogo),
                      ), // Cierra sin perder el carrito.
                    ],
                  ), // Finaliza la cabecera del menú.
                  const SizedBox(height: 20), // Separa la cabecera de la tabla.
                  if (_errorInventario != null)
                    Text(
                      'No se pudo cargar el inventario: $_errorInventario',
                    ), // Conserva los errores de conexión.
                  if (_errorInventario != null)
                    CartaNavegacion.accion(
                      onPressed: () async {
                        await _cargarInventario();
                        actualizarMenu(() {});
                      },
                      child: const Text('REINTENTAR'),
                    ), // Permite recuperar la consulta.
                  if (_cargandoInventario)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ), // Conserva el estado de carga.
                  if (!_cargandoInventario && _errorInventario == null)
                    Expanded(
                      child: TablaDatos(
                        nombresColumnas: const [
                          'PRODUCTO',
                          'CATEGORÍA',
                          'PRECIO',
                          'AÑADIR',
                        ], // Conserva las columnas del prototipo.
                        camposColumnas: const [
                          'producto',
                          'categoria',
                          'precio',
                          '',
                        ], // Conserva búsqueda y filtros por datos.
                        anchosColumnas: const [
                          4,
                          3,
                          2,
                          2,
                        ], // Conserva las proporciones del inventario.
                        filas: _inventario
                            .map(
                              (producto) => <String, dynamic>{
                                'producto': producto.nombre,
                                'categoria': producto.categoria,
                                'precio': producto.precio.toStringAsFixed(0),
                                'registro': producto,
                              },
                            )
                            .toList(), // Conserva el producto original detrás de cada fila.
                        celdasPersonalizadas: {
                          3: (context, fila) => CartaNavegacion.accion(
                            tipoBoton: 'icon',
                            tooltip: 'Añadir al carrito',
                            child: const Icon(
                              Icons.add_circle_outline,
                              size: 35,
                            ), // Conserva la acción de añadir.
                            onPressed: () {
                              _agregarAlCarrito(
                                fila['registro'] as ProductoVenta,
                              );
                              actualizarMenu(() {});
                            }, // Añade unidades sin cerrar el menú.
                          ),
                        }, // Finaliza las acciones de inventario.
                      ),
                    ), // Finaliza la tabla del menú superpuesto.
                ],
              ), // Finaliza el contenido del menú.
            ),
          ), // Finaliza el tamaño del menú.
        ),
      ),
    ); // Espera el cierre de la selección.
  } // Finaliza el menú de productos.

  // Getter para calcular el precio total dinámicamente
  double get _precioTotal =>
      _carrito.fold(0, (suma, item) => suma + item.precio);

  // ==========================================================================
  // FUNCIONES DE ESTADO
  // ==========================================================================

  void _agregarAlCarrito(ProductoVenta producto) {
    if (_guardando) return; // Conserva el carrito durante el registro.
    final cantidadEnCarrito = _carrito
        .where((item) => item.id == producto.id)
        .length;

    if (cantidadEnCarrito >= producto.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay más unidades disponibles.')),
      );
      return;
    }

    setState(() {
      _carrito.add(producto);
    });
  }

  Future<void> _registrarVenta() async {
    if (_guardando) return; // Evita registros simultáneos.
    final rut = int.tryParse(
      _cliente?.id ?? '',
    ); // Usa el cliente seleccionado.

    if (rut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un cliente para registrar la venta.'),
        ),
      );
      return;
    }

    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto.')),
      );
      return;
    }

    final cantidades = <String, int>{};

    for (final producto in _carrito) {
      cantidades.update(
        producto.id,
        (cantidad) => cantidad + 1,
        ifAbsent: () => 1,
      );
    }

    setState(
      () => _guardando = true,
    ); // Impide guardar dos borradores simultáneamente.
    try {
      // Conserva el formulario si falla el almacenamiento.
      final articulos = cantidades.entries.map((entrada) {
        // Agrupa las unidades seleccionadas.
        final producto = _carrito.firstWhere(
          (producto) => producto.id == entrada.key,
        ); // Recupera el producto de la línea.
        return ArticuloVentaPendiente(
          codigo: producto.id,
          nombre: producto.nombre,
          categoria: producto.categoria,
          precio: producto.precio,
          cantidad: entrada.value,
          stock: producto.stock,
        ); // Conserva los datos para volver a editar.
      }).toList(); // Finaliza las líneas del borrador.
      await _repositorio.guardar(
        VentaPendiente(
          id: widget.pendiente?.id ?? VentasPendientesRepository.nuevoId(),
          rutCliente: rut.toString(),
          nombreCliente: _cliente!.nombre,
          fonoCliente: _cliente!.numero,
          patente: _patenteVehiculoCtrl.text.trim().toUpperCase(),
          articulos: articulos,
          revision: widget.pendiente?.revision ?? 0,
          fechaCreacion: widget.pendiente?.fechaCreacion, // La edición conserva el día de la venta pendiente.
        ),
      ); // Guarda solo en este dispositivo; no descuenta stock ni crea la venta en Supabase.
      if (!mounted) return; // Evita navegar desde una página cerrada.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta pendiente guardada en este dispositivo.'),
        ),
      ); // Confirma la persistencia local.
      Navigator.pop(context, true); // Actualiza Ventas o el detalle pendiente.
    } catch (error) {
      // Conserva el cliente y los artículos si falla el guardado.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar la venta pendiente: $error'),
          ),
        ); // Informa el fallo sin perder datos.
      }
    } finally {
      // Restablece las acciones del formulario.
      if (mounted) {
        setState(() => _guardando = false); // Permite corregir y reintentar.
      }
    } // Finaliza el guardado local.
  }

  void _removerDelCarrito(int index) {
    if (_guardando) {
      return; // Solo permite quitar artículos antes de cerrar la venta.
    }
    setState(() {
      _carrito.removeAt(index);
    });
  }

  @override
  void dispose() {
    _busquedaCliente.dispose(); // Libera el buscador.
    _patenteVehiculoCtrl.dispose();

    super.dispose();
  }

  // ==========================================================================
  // BUILD PRINCIPAL
  // ==========================================================================

  @override
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: widget.pendiente == null
        ? 'Registro de venta nueva'
        : 'Edición de venta pendiente',
    activo: 'Ventas', // Conserva el encabezado de Figma.
    padding: const EdgeInsets.fromLTRB(
      30,
      16,
      30,
      30,
    ), // Alinea el contenido bajo la barra existente.
    child: SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, espacio) => Column(
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Utiliza el ancho disponible sin tocar los widgets.
          children: [
            if (espacio.maxWidth >= 900)
              Row(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Alinea los datos y los productos desde arriba.
                children: [
                  Expanded(
                    flex: 6,
                    child: _construirFormularioCliente(context),
                  ), // Sitúa el formulario a la izquierda.
                  const SizedBox(
                    width: 40,
                  ), // Separa las columnas como en Figma.
                  Expanded(
                    flex: 5,
                    child: _construirCarritoYTotal(), // Comparte el inicio vertical con el botón de regreso.
                  ), // Sitúa productos y total a la derecha.
                ], // Finaliza las columnas de escritorio.
              )
            else ...[
              _construirFormularioCliente(
                context,
              ), // Conserva los datos primero en Android.
              const SizedBox(height: 24), // Separa las secciones en móvil.
              _construirCarritoYTotal(), // Conserva el carrito debajo del formulario.
            ], // Finaliza la distribución adaptable.
          ], // Finaliza el contenido de la venta.
        ),
      ),
    ), // Permite desplazar la página en Android.
  ); // Finaliza la composición de venta.

  // ==========================================================================
  // WIDGET: FORMULARIO CLIENTE
  // ==========================================================================

  Widget _construirFormularioCliente(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CartaNavegacion.accion(
          // Conserva las medidas y la función de la acción original.
          tipoBoton: 'elevated',

          onPressed: _guardando ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_return, color: Colors.black),
          label: Text(
            widget.pendiente == null
                ? 'VOLVER A VENTAS'
                : 'VOLVER A VENTA PENDIENTE',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB7B7B7),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),

        const SizedBox(height: 12), // Iguala la separación entre los botones superiores y los campos de cliente y búsqueda.

        _selectorCliente(), // Selecciona un cliente existente o recién creado.
        const SizedBox(height: 24), // Separa el cliente de la patente.
        FormularioDatos(
          campos: [
            CampoFormularioDatos(
              controlador: _patenteVehiculoCtrl,
              etiqueta: 'PATENTE DEL VEHÍCULO (OPCIONAL):',
              textoAyuda: 'Patente ya registrada',
              habilitado: !_guardando,
            ), // Conserva la patente opcional.
          ], // Finaliza los campos alineados.
        ), // Finaliza el formulario reutilizable.
        if (_cliente?.vehiculos.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Vehículos del cliente:'),
                for (final patente in _cliente!.patentesVehiculos)
                  ActionChip(
                    label: Text(patente),
                    onPressed: _guardando
                        ? null
                        : () => setState(
                            () => _patenteVehiculoCtrl.text = patente,
                          ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================================================
  // WIDGET: CARRITO Y TOTAL
  // ==========================================================================

  Widget _construirCarritoYTotal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Abre la selección sobre la página y conserva los productos actuales.
        Padding(
          padding: const EdgeInsets.only(right: margenDesplazamientoTabla), // Alinea el botón con el borde visible de la tabla en escritorio y Android.
          child: CartaNavegacion.accion(
            onPressed: _guardando ? null : _abrirSeleccionProductos,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('AÑADIR NUEVO PRODUCTO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9D9D9),
              foregroundColor: Colors.black,
            ),
          ),
        ), // Conserva el tamaño y la acción de añadir productos.
        const SizedBox(height: 12), // Separa la acción del carrito.
        // ======================================================================
        // CONTENEDOR DEL CARRITO
        // ======================================================================

        SizedBox(
          height: 350, // Conserva el alto original del carrito y su total.
          child: Column(
            children: [
              Expanded(
                child: TablaDatos(
                  nombresColumnas: const [
                    'PRODUCTOS',
                    'PRECIO',
                    'REMOVER',
                  ], // Conserva los productos y sus acciones.
                  camposColumnas: const [
                    'producto',
                    'precio',
                    '',
                  ], // Excluye la acción de los filtros.
                  anchosColumnas: const [
                    5,
                    2,
                    2,
                  ], // Distribuye el ancho original del carrito.
                  altoFila: 70, // Mantiene espacio para los controles.
                  filas: _carrito
                      .asMap()
                      .entries
                      .map(
                        (entrada) => <String, dynamic>{
                          'producto': entrada
                              .value
                              .nombre, // Permite buscar por nombre.
                          'precio':
                              '\$${entrada.value.precio.toStringAsFixed(0)}', // Conserva el precio del producto.
                          'indice': entrada.key, // Conserva la posición original incluso cuando se filtra.
                        },
                      )
                      .toList(), // Adapta el carrito a la tabla compartida.
                  celdasPersonalizadas: {
                    2: (context, fila) => CartaNavegacion.accion(
                      tipoBoton: 'icon', // Conserva el icono de quitar.
                      onPressed: _guardando
                          ? null
                          : () => _removerDelCarrito(
                              fila['indice'] as int,
                            ), // Conserva el tamaño de la acción original.
                      child: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                        size: 30,
                      ), // Quita el producto original sin confundir las filas filtradas.
                    ), // Finaliza la acción del carrito.
                  }, // Finaliza las acciones personalizadas.
                ), // Finaliza la tabla compartida del carrito.
              ), // Reserva espacio para las filas encima del total.
              Container(
                color: Colors.red[400],
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PRECIO TOTAL:\$${_precioTotal.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ], // Finaliza el carrito y su total.
          ), // Finaliza la distribución vertical.
        ),

        const SizedBox(height: 20),

        // ======================================================================
        // BOTÓN REGISTRAR VENTA
        // ======================================================================
        CartaNavegacion.accion(
          // Conserva las medidas y la función de la acción original.
          tipoBoton: 'elevated',

          onPressed: _guardando ? null : _registrarVenta,
          icon: const Icon(Icons.download, color: Colors.black),
          label: Text(
            widget.pendiente == null ? 'REGISTRAR VENTA' : 'GUARDAR CAMBIOS',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB7B7B7),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// HEADER FIJO DE LA TABLA
// ============================================================================

// ============================================================================
// CAMPO EDITABLE
// ============================================================================
