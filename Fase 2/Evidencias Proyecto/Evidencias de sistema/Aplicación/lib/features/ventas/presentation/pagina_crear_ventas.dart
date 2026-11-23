import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:frenos_cerna/features/clientes/pagina_crear_cliente.dart';
import 'package:frenos_cerna/features/ventas/data/carrito_de_venta.dart';
import 'package:frenos_cerna/features/ventas/data/producto_venta.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart';
import 'package:frenos_cerna/features/ventas/presentation/formato_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/carrito_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/dialogo_cantidad_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/dialogo_catalogo_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/panel_venta.dart';
import 'package:frenos_cerna/features/ventas/presentation/widgets/tema_venta.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
import 'package:material_ui/material_ui.dart';

export 'package:frenos_cerna/features/ventas/data/producto_venta.dart';

class PaginaCrearVenta extends StatefulWidget {
  final Future<List<ProductoVenta>> Function()? cargarProductos;
  final Future<List<Cliente>> Function()? cargarClientes;
  final VentaPendiente? pendiente;
  final VentasPendientesRepository? repositorioPendientes;
  final ProductoVenta? productoEscaneado;
  final int cantidadEscaneada;

  const PaginaCrearVenta({
    super.key,
    this.productoEscaneado,
    this.cantidadEscaneada = 1,
    this.cargarProductos,
    this.cargarClientes,
    this.pendiente,
    this.repositorioPendientes,
  });

  @override
  State<PaginaCrearVenta> createState() => _PaginaCrearVentaState();
}

class _PaginaCrearVentaState extends State<PaginaCrearVenta> {
  final _patente = TextEditingController();
  final _carrito = CarritoDeVenta();
  Cliente? _cliente;
  bool _guardando = false;

  VentasPendientesRepository get _repositorio =>
      widget.repositorioPendientes ?? VentasPendientesRepository.instancia;

  @override
  void initState() {
    super.initState();
    final pendiente = widget.pendiente;
    if (pendiente != null) {
      _cliente = Cliente(
        id: pendiente.rutCliente,
        nombre: pendiente.nombreCliente,
        numero: pendiente.fonoCliente,
        ultimaVenta: '',
        vehiculo: pendiente.patente,
      );
      _patente.text = pendiente.patente;
      for (final articulo in pendiente.articulos) {
        _carrito.restaurar(
          ProductoVenta(
            id: articulo.codigo,
            nombre: articulo.nombre,
            categoria: articulo.categoria,
            precio: articulo.precio,
            stock: articulo.stock,
          ),
          articulo.cantidad,
        );
      }
      return;
    }

    final escaneado = widget.productoEscaneado;
    if (escaneado != null) {
      _carrito.agregar(escaneado, widget.cantidadEscaneada);
    }
  }

  @override
  void dispose() {
    _patente.dispose();
    super.dispose();
  }

  Future<List<Cliente>> _consultarClientes() async {
    final cargar = widget.cargarClientes;
    if (cargar != null) return cargar();
    final filas = await SupabaseDatabase.client
        .from(SupabaseTables.clientes)
        .select(
          'rut, nombre, fono, vehiculo_cliente(patente, modelo_vehiculo(modelo, marca_vehiculo(marca)))',
        )
        .order('nombre');
    return filas.map(Cliente.fromJson).toList();
  }

  Future<List<ProductoVenta>> _consultarProductos() async {
    final cargar = widget.cargarProductos;
    if (cargar != null) return cargar();
    final filas = await SupabaseDatabase.client
        .from(SupabaseTables.productos)
        .select(
          'codigo_producto, sku, cod_barra, stock, tipo, precio, tipo_producto(nombre_tipo)',
        )
        .gt('stock', 0)
        .order('codigo_producto');
    return filas.map(ProductoVenta.fromJson).toList();
  }

  Future<void> _elegirCliente() async {
    final cliente = await mostrarDialogoVenta<Cliente>(
      context: context,
      builder: (dialogo) => DialogoCatalogoVenta<Cliente>(
        titulo: 'Seleccionar cliente',
        ayudaBusqueda: 'Nombre o RUT',
        sinResultados: 'No se encontraron clientes.',
        errorCarga: 'No se pudieron cargar los clientes.',
        cargar: _consultarClientes,
        coincide: (cliente, texto) =>
            cliente.nombre.toLowerCase().contains(texto) ||
            cliente.id.contains(texto),
        accion: TextButton.icon(
          onPressed: () {
            Navigator.pop(dialogo);
            _crearCliente();
          },
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Crear cliente'),
        ),
        resultado: (context, cliente, _) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const Icon(Icons.person_outline),
          title: Text(_nombreCliente(cliente)),
          subtitle: cliente.vehiculos.isEmpty
              ? null
              : Text(
                  cliente.vehiculos.join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(dialogo, cliente),
        ),
      ),
    );
    if (mounted && cliente != null) setState(() => _cliente = cliente);
  }

  Future<void> _crearCliente() async {
    final cliente = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/clients/new'),
        builder: (_) => const PaginaCrearCliente(devolverClienteCreado: true),
      ),
    );
    if (mounted && cliente != null) setState(() => _cliente = cliente);
  }

  String _nombreCliente(Cliente cliente) =>
      '${cliente.nombre} · RUT: ${cliente.id}';

  Future<void> _buscarProductos() => mostrarDialogoVenta<void>(
    context: context,
    builder: (_) => DialogoCatalogoVenta<ProductoVenta>(
      titulo: 'Añadir productos',
      ayudaBusqueda: 'Código, SKU o categoría',
      sinResultados: 'No hay productos que coincidan.',
      errorCarga: 'No se pudo cargar el inventario.',
      cargar: _consultarProductos,
      coincide: (producto, texto) => producto.coincideCon(texto),
      resultado: _resultadoProducto,
    ),
  );

  Widget _resultadoProducto(
    BuildContext context,
    ProductoVenta producto,
    VoidCallback actualizarCatalogo,
  ) {
    final original = _carrito[producto.id];
    final enCarrito = original?.cantidad ?? 0;
    final precio = original?.producto.precio ?? producto.precio;
    final disponibles = _carrito.disponibles(producto);
    final descripcion = [
      if (producto.nombre != producto.id) producto.id,
      if (producto.sku.isNotEmpty) 'SKU ${producto.sku}',
      producto.categoria,
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      title: Text(
        producto.nombre,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
          Text('${precioVenta(precio)} c/u · Disponibles: $disponibles'),
          if (enCarrito > 0) Text('En el carrito: $enCarrito'),
        ],
      ),
      trailing: const Icon(
        Icons.add_circle_outline,
        semanticLabel: 'Elegir cantidad',
      ),
      enabled: disponibles > 0,
      onTap: disponibles <= 0
          ? null
          : () async {
              final cantidad = await pedirCantidadVenta(
                context,
                titulo: 'Añadir ${producto.nombre}',
                maximo: disponibles,
                accion: 'Añadir al carrito',
              );
              if (!mounted || cantidad == null || _guardando) return;
              if (!_carrito.agregar(producto, cantidad)) return;
              setState(() {});
              actualizarCatalogo();
            },
    );
  }

  void _cambiarCantidad(LineaCarritoVenta linea, int cantidad) {
    if (_guardando) return;
    setState(() => _carrito.fijarCantidad(linea.producto.id, cantidad));
  }

  Future<void> _editarCantidad(LineaCarritoVenta linea) async {
    final cantidad = await pedirCantidadVenta(
      context,
      titulo: 'Cantidad de ${linea.producto.nombre}',
      inicial: linea.cantidad,
      maximo: linea.producto.stock < linea.cantidad
          ? linea.cantidad
          : linea.producto.stock,
      accion: 'Actualizar cantidad',
    );
    if (mounted && cantidad != null) _cambiarCantidad(linea, cantidad);
  }

  void _aviso(String mensaje) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));

  Future<void> _registrarVenta() async {
    if (_guardando) return;
    final cliente = _cliente;
    final rut = int.tryParse(cliente?.id ?? '');
    if (cliente == null || rut == null) {
      _aviso('Selecciona un cliente para registrar la venta.');
      return;
    }
    if (_carrito.isEmpty) {
      _aviso('Agrega al menos un producto.');
      return;
    }

    setState(() => _guardando = true);
    final pendiente = widget.pendiente;
    try {
      await _repositorio.guardar(
        VentaPendiente(
          id: pendiente?.id ?? VentasPendientesRepository.nuevoId(),
          rutCliente: rut.toString(),
          nombreCliente: cliente.nombre,
          fonoCliente: cliente.numero,
          patente: _patente.text.trim().toUpperCase(),
          articulos: [
            for (final (:producto, :cantidad) in _carrito.lineas)
              ArticuloVentaPendiente(
                codigo: producto.id,
                nombre: producto.nombre,
                categoria: producto.categoria,
                precio: producto.precio,
                cantidad: cantidad,
                stock: producto.stock,
              ),
          ],
          revision: pendiente?.revision ?? 0,
          fechaCreacion: pendiente?.fechaCreacion,
        ),
      );
      if (!mounted) return;
      _aviso('Venta pendiente guardada en este dispositivo.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _aviso('No se pudo guardar la venta pendiente: $error');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => PaginaTematica(
    builder: (context) => PopScope(
      canPop: !_guardando,
      child: EstructuraPagina(
        titulo: widget.pendiente == null
            ? 'Nueva venta'
            : 'Editar venta pendiente',
        activo: 'Ventas',
        mostrarVolver: true,
        mostrarNavegacionMovil: false,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: TemaVenta(
          child: LayoutBuilder(
            builder: (_, espacio) {
              if (MediaQuery.viewInsetsOf(context).bottom > 0)
                return _contenido();
              final resumen = _resumen();
              if (espacio.maxHeight < 350) return _contenido(resumen: resumen);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _contenido()),
                  resumen,
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _contenido({Widget? resumen}) => LayoutBuilder(
    builder: (context, espacio) {
      final cliente = PanelVenta(child: _datosCliente(context));
      final carrito = PanelVenta(
        child: CarritoVenta(
          lineas: _carrito.lineas.toList(),
          habilitado: !_guardando,
          buscarProductos: _buscarProductos,
          cambiarCantidad: _cambiarCantidad,
          editarCantidad: _editarCantidad,
        ),
      );
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (espacio.maxWidth >= 840)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: cliente),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: carrito),
                ],
              )
            else ...[
              cliente,
              const SizedBox(height: 12),
              carrito,
            ],
            if (resumen != null) ...[const SizedBox(height: 12), resumen],
          ],
        ),
      );
    },
  );

  Widget _datosCliente(BuildContext context) {
    final cliente = _cliente;
    final tema = Theme.of(context).textTheme;
    final patentes = cliente?.patentesVehiculos ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Cliente y vehículo', style: tema.titleLarge),
        const SizedBox(height: 12),
        Tooltip(
          message: cliente == null
              ? 'Buscar por nombre o RUT'
              : 'Cambiar cliente',
          child: OutlinedButton.icon(
            onPressed: _guardando ? null : _elegirCliente,
            icon: const Icon(Icons.person_outline),
            label: Text(
              cliente == null ? 'Seleccionar cliente' : _nombreCliente(cliente),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _patente,
          enabled: !_guardando,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Patente (opcional)',
            hintText: 'Patente ya registrada',
            prefixIcon: Icon(Icons.directions_car_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        if (patentes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Vehículos del cliente', style: tema.labelMedium),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final patente in patentes)
                ActionChip(
                  label: Text(patente),
                  onPressed: _guardando ? null : () => _patente.text = patente,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _resumen() => LayoutBuilder(
    builder: (context, espacio) {
      final total = _carrito.total;
      final unidades = _carrito.unidades;
      final tema = Theme.of(context).textTheme;
      final bloques = <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              unidades == 1 ? '1 unidad' : '$unidades unidades',
              style: tema.labelMedium,
            ),
            Text('Total ${precioVenta(total)}', style: tema.titleLarge),
          ],
        ),
        FilledButton.icon(
          style: estiloAccionPrincipalVenta(context),
          onPressed: _guardando ? null : _registrarVenta,
          icon: Icon(_guardando ? Icons.hourglass_empty : Icons.save_outlined),
          label: Text(
            _guardando
                ? 'Guardando…'
                : widget.pendiente == null
                ? 'Guardar como pendiente'
                : 'Guardar cambios',
          ),
        ),
      ];
      return PanelVenta(
        child: espacio.maxWidth < 440
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  bloques.first,
                  const SizedBox(height: 8),
                  bloques.last,
                ],
              )
            : Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: bloques,
              ),
      );
    },
  );
}
