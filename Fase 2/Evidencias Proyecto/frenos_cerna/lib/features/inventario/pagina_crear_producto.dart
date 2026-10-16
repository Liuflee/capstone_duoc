// Importa Flutter, la conexión existente y los widgets compartidos.
import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

// Presenta el registro como página independiente.
class PaginaCrearProducto extends StatefulWidget {
  const PaginaCrearProducto({super.key}); // Crea el registro.
  @override // Crea el estado del formulario.
  State<PaginaCrearProducto> createState() => _PaginaCrearProductoState();
} // Finaliza la página pública.

class _PaginaCrearProductoState extends State<PaginaCrearProducto> {
  final _codigo = TextEditingController(); // Conserva la clave requerida por la base actual.
  final _nombre =
      TextEditingController(); // Conserva el nombre o código de barra.
  final _precio = TextEditingController(); // Conserva el precio.
  final _stock = TextEditingController(
    text: '0',
  ); // Conserva las existencias iniciales.
  final _clave = GlobalKey<FormState>(); // Valida el formulario.
  Object? _calidad; // Conserva la calidad seleccionada del catálogo existente.
  List<Map<String, dynamic>> _calidades =
      []; // Almacena las calidades disponibles.
  Object? _categoria; // Conserva la clave real de categoría.
  List<Map<String, dynamic>> _categorias =
      []; // Conserva el catálogo existente.
  String? _errorCategorias; // Informa errores al recuperar categorías.
  @override // Carga las categorías al abrir el formulario.
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final respuesta = await SupabaseDatabase.client
          .from(SupabaseTables.tiposProducto)
          .select();
      final calidades = await SupabaseDatabase.client
          .from(SupabaseTables.calidadesProducto)
          .select(); // Consulta las calidades existentes.
      if (mounted) {
        _calidades = List<Map<String, dynamic>>.from(
          calidades,
        ); // Conserva sus identificadores.
        setState(
          () => _categorias = List<Map<String, dynamic>>.from(respuesta),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _errorCategorias = error.toString());
    } // Conserva los errores de consulta.
  }

  bool _guardando = false; // Evita registros simultáneos.
  @override // Libera los recursos.
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _precio.dispose();
    _stock.dispose();
    super.dispose();
  }

  String? _entero(String? valor) =>
      int.tryParse(valor ?? '') == null || int.parse(valor!) < 0
      ? 'Ingresa un entero igual o mayor que cero'
      : null; // Valida los datos numéricos.
  Future<void> _registrar() async {
    if (_guardando || !_clave.currentState!.validate()) {
      return; // Evita registros inválidos.
    }
    setState(() => _guardando = true); // Indica el guardado.
    try {
      await SupabaseDatabase.client.from(SupabaseTables.productos).insert({
        'codigo_producto': _codigo.text
            .trim(), // Conserva el código del registro anterior.
        'cod_barra': _nombre.text.trim().isEmpty
            ? null
            : _nombre.text.trim(), // Conserva la columna existente.
        if (_calidad != null)
          'calidad': _calidad, // Guarda la calidad existente.
        if (_categoria != null) 'tipo': _categoria, // Conserva la categoría seleccionada. // Usa el campo de nombre disponible en la base actual.
        'precio': int.parse(_precio.text.trim()),
        'stock': int.parse(
          _stock.text.trim(),
        ), // Conserva precio y existencias.
      }); // Utiliza únicamente columnas existentes.
      if (mounted) {
        Navigator.pop(context, true); // Actualiza el inventario al regresar.
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar el producto: $error')),
        );
      }
    } // Conserva el formulario ante errores.
    finally {
      if (mounted) setState(() => _guardando = false);
    } // Restablece las acciones.
  } // Finaliza el registro.

  @override // Construye la composición de creación de producto.
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Creación de producto',
    activo: 'Inventario',
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Alinea el contenido.
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CartaNavegacion.accion(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.keyboard_return),
              label: const Text('VOLVER A INVENTARIO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2A0A0),
                foregroundColor: Colors.black,
              ),
            ),
          ), // Coloca el regreso arriba a la izquierda.
          const SizedBox(height: 40), // Separa navegación y formulario.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: FormularioDatos(
                claveFormulario: _clave,
                ancho: 1250,
                separacionFilas:
                    28, // Centra los campos y mantiene su alineación.
                campos: [
                  CampoFormularioDatos(
                    controlador: _codigo,
                    etiqueta: 'CÓDIGO DEL PRODUCTO:',
                    textoAyuda: 'Ej.: SP0-01223',
                    tipoTeclado: TextInputType.text,
                    validador: (valor) => valor == null || valor.trim().isEmpty
                        ? 'Ingresa el código del producto'
                        : null, // Exige un identificador alfanumérico.
                    habilitado: !_guardando,
                  ), // Conserva el código obligatorio.
                  CampoFormularioDatos(
                    controlador: _precio,
                    etiqueta: 'PRECIO DEL PRODUCTO NUEVO:',
                    textoAyuda: 'Precio',
                    tipoTeclado: TextInputType.number,
                    validador: _entero,
                    habilitado: !_guardando,
                  ), // Configura el precio.
                  CampoFormularioDatos(
                    controlador: _stock,
                    etiqueta: 'CANTIDAD INICIAL EN BODEGA:',
                    textoAyuda: 'Cantidad',
                    tipoTeclado: TextInputType.number,
                    validador: _entero,
                    habilitado: !_guardando,
                  ), // Configura las existencias iniciales.
                ], // Finaliza los campos.
              ),
            ),
          ), // Finaliza el formulario centrado.
          const SizedBox(height: 24), // Separa la categoría de los campos.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1250,
              ), // Alinea los catálogos con los campos.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final esCalidad in [false, true]) ...[
                    Text(
                      esCalidad
                          ? 'CALIDAD DEL PRODUCTO NUEVO:'
                          : 'CATEGORÍA DEL PRODUCTO NUEVO:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ), // Identifica cada catálogo.
                    const SizedBox(
                      height: 10,
                    ), // Separa el título del selector.
                    DropdownButtonFormField<Object>(
                      initialValue: esCalidad ? _calidad : _categoria,
                      isExpanded: true, // Respeta el ancho del formulario también en móvil.
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFD9D9D9),
                        hintText: esCalidad ? 'Calidad' : 'Categoría',
                      ),
                      items: [
                        for (final fila
                            in (esCalidad ? _calidades : _categorias).where(
                              (fila) => fila['id'] != null,
                            ))
                          DropdownMenuItem(
                            value: fila['id'],
                            child: Text(
                              fila[esCalidad ? 'nombre_calidad' : 'nombre_tipo']
                                      ?.toString() ??
                                  'Sin nombre',
                            ),
                          ),
                      ], // Usa las opciones reales de cada catálogo.
                      onChanged: _guardando
                          ? null
                          : (valor) => setState(() {
                              if (esCalidad) {
                                _calidad = valor;
                              } else {
                                _categoria = valor;
                              }
                            }), // Mantiene ambas selecciones independientes.
                    ),
                    const SizedBox(
                      height: 28,
                    ), // Conserva la separación de los campos.
                  ],
                  FormularioDatos(
                    ancho: 1250,
                    campos: [
                      CampoFormularioDatos(
                        controlador: _nombre,
                        etiqueta: 'CÓDIGO DE BARRA DEL PRODUCTO NUEVO:',
                        textoAyuda: 'Código de barra',
                        habilitado: !_guardando,
                      ), // Usa el dato admitido por el esquema actual.
                    ], // Deja el código de barras al final.
                  ),
                  if (_errorCategorias != null)
                    Text(
                      'No se pudieron cargar los catálogos: $_errorCategorias',
                    ), // Informa los errores de consulta.
                ],
              ),
            ),
          ), // Comparte los mismos márgenes que el formulario superior.
          const SizedBox(height: 30), // Separa la acción de registro.
          Align(
            alignment: Alignment.centerRight,
            child: CartaNavegacion.accion(
              onPressed: _guardando ? null : _registrar,
              icon: const Icon(Icons.download),
              label: Text(_guardando ? 'GUARDANDO...' : 'REGISTRAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD96363),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 18,
                ),
              ),
            ),
          ), // Usa la acción roja de Figma.
        ], // Finaliza el contenido.
      ),
    ),
  ); // Finaliza la página.
} // Finaliza el estado.
