import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/core/tema/paleta_taller.dart';
import 'package:frenos_cerna/features/inventario/pagina_crear_producto.dart';
import 'package:frenos_cerna/features/ventas/presentation/pagina_crear_ventas.dart';
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';

// El reconocimiento conserva el código completo, incluidos sus ceros iniciales.
Future<void> escanearProducto(BuildContext context) async {
  final codigo = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: '/products/scan'),
      builder: (_) => const PaginaEscanerProducto(),
    ),
  );
  if (codigo == null || !context.mounted) return;
  // La consulta se hace después de liberar la cámara.
  final progreso = mostrarDialogoConTema<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Buscando producto…')),
          ],
        ),
      ),
    ),
  );
  List<Map<String, dynamic>>? filas;
  Object? error;
  try {
    filas = await SupabaseDatabase.client
        .from(SupabaseTables.productos)
        .select(
          'codigo_producto,cod_barra,stock,precio,tipo,tipo_producto(nombre_tipo)',
        )
        .eq('cod_barra', codigo)
        .limit(2);
  } catch (fallo) {
    error = fallo;
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  await progreso;
  if (!context.mounted) return;
  if (error != null || filas == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se pudo consultar el inventario. Revisa la conexión y vuelve a escanear.',
        ),
      ),
    );
    return;
  }
  if (filas.isEmpty) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/products/new'),
        builder: (_) => PaginaCrearProducto(codigoBarraInicial: codigo),
      ),
    );
    return;
  }
  if (filas.length > 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Hay varios productos con este código de barras. Revisa sus códigos en Inventario.',
        ),
      ),
    );
    return;
  }
  final producto = ProductoVenta.fromJson(filas.single);
  if (producto.stock <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('El producto ${producto.id} está sin stock.')),
    );
    return;
  }
  final cantidad = await mostrarDialogoConTema<int>(
    context: context,
    builder: (_) => _CantidadEscaneada(producto: producto),
  );
  if (cantidad == null || !context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: '/sales/new'),
      builder: (_) => PaginaCrearVenta(
        productoEscaneado: producto,
        cantidadEscaneada: cantidad,
      ),
    ),
  );
}

class _CantidadEscaneada extends StatefulWidget {
  final ProductoVenta producto;
  const _CantidadEscaneada({required this.producto});
  @override
  State<_CantidadEscaneada> createState() => _CantidadEscaneadaState();
}

class _CantidadEscaneadaState extends State<_CantidadEscaneada> {
  final controlador = TextEditingController(text: '1');
  final formulario = GlobalKey<FormState>();
  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text('Vender ${widget.producto.id}'),
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Disponibles: ${widget.producto.stock} unidades'),
          const SizedBox(height: 16),
          FormularioDatos(
            claveFormulario: formulario,
            ajustarAlAnchoDisponible: true,
            campos: [
              CampoFormularioDatos(
                controlador: controlador,
                etiqueta: 'CANTIDAD A VENDER',
                textoAyuda: 'Unidades',
                tipoTeclado: TextInputType.number,
                validador: (valor) {
                  final unidades = int.tryParse(valor?.trim() ?? '');
                  return unidades == null ||
                          unidades < 1 ||
                          unidades > widget.producto.stock
                      ? 'Ingresa entre 1 y ${widget.producto.stock}'
                      : null;
                },
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CANCELAR'),
      ),
      FilledButton(
        onPressed: () {
          if (formulario.currentState!.validate()) {
            Navigator.pop(context, int.parse(controlador.text.trim()));
          }
        },
        child: const Text('CONTINUAR'),
      ),
    ],
  );
}

class PaginaEscanerProducto extends StatefulWidget {
  const PaginaEscanerProducto({super.key});
  @override
  State<PaginaEscanerProducto> createState() => _PaginaEscanerProductoState();
}

class _PaginaEscanerProductoState extends State<PaginaEscanerProducto> {
  final controlador = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  );
  bool detectado = false;
  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  void reconocer(BarcodeCapture captura) {
    if (detectado) return;
    for (final barra in captura.barcodes) {
      final codigo = barra.rawValue?.trim();
      if (codigo == null || codigo.isEmpty) continue;
      detectado = true;
      Navigator.pop(context, codigo);
      return;
    }
  }

  @override
  Widget build(BuildContext context) => PaginaTematica(
    builder: (context) => Scaffold(
      backgroundColor: PaletaTaller.de(context).fondo,
      appBar: AppBar(
        title: const Text('Escanear producto'),
        actions: [
          IconButton(
            tooltip: 'Encender o apagar linterna',
            icon: const Icon(Icons.flashlight_on),
            onPressed: () async {
              try {
                await controlador.toggleTorch();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La linterna no está disponible.'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Apunta la cámara al código de barras del producto.'),
          ),
          Expanded(
            child: MobileScanner(
              controller: controlador,
              onDetect: reconocer,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? 'Permite el acceso a la cámara desde los ajustes del celular y vuelve a abrir el escáner.'
                        : 'No se pudo iniciar la cámara. Cierra el escáner e inténtalo nuevamente.',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
