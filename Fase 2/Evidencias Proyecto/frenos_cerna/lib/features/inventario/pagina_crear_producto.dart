// Importa Flutter, la conexión existente y los widgets compartidos.
import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

// Presenta el registro como página independiente.
class PaginaCrearProducto extends StatefulWidget {
  final Map<String, dynamic>? productoInicial; // Activa la edición con los datos existentes sin duplicar el formulario.
  final Future<Map<String, List<Map<String, dynamic>>>> Function()?
  cargarCatalogos; // Permite verificar la relación con datos controlados.
  const PaginaCrearProducto({
    super.key,
    this.cargarCatalogos,
    this.productoInicial, // Sin datos iniciales conserva el registro de un producto nuevo.
  }); // Crea el registro con la conexión habitual por defecto.
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
  bool _editandoCatalogo =
      false; // Bloquea cambios durante la creación de opciones.
  List<Map<String, dynamic>> _relacionesCalidad =
      []; // Vincula las calidades con las categorías permitidas.
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
    final producto =
        widget.productoInicial; // Conserva el registro que se va a editar.
    if (producto != null) {
      _codigo.text = producto['codigo_producto']
          .toString(); // Muestra su identificador real.
      _nombre.text =
          producto['cod_barra']?.toString() ??
          ''; // Precarga el código de barras sin nombres inventados.
      _precio.text = producto['precio']
          .toString(); // Precarga el precio existente.
      _stock.text = producto['stock']
          .toString(); // Precarga las existencias existentes.
      _categoria = producto['tipo']; // Selecciona su categoría.
      _calidad = producto['calidad']; // Selecciona su calidad.
      if (_categoria != null) {
        _categorias = [
          {
            'id': _categoria,
            'nombre_tipo': producto['nombre_tipo'] ?? 'Categoría actual',
          },
        ]; // Conserva la selección durante la carga.
      }
      if (_calidad != null) {
        _calidades = [
          {'id': _calidad, 'nombre_calidad': 'Calidad actual'},
        ]; // Conserva el ID hasta consultar el catálogo.
        _relacionesCalidad = [
          {'id_tipo': _categoria, 'id_calidad': _calidad},
        ]; // Mantiene la asociación existente.
      }
    }
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      if (widget.cargarCatalogos != null) {
        final catalogos = await widget.cargarCatalogos!(); // Obtiene los tres catálogos de una misma fuente.
        if (!mounted) return; // Evita actualizar un formulario cerrado.
        setState(() {
          _categorias =
              catalogos['categorias'] ??
              []; // Conserva las categorías recibidas.
          _calidades =
              catalogos['calidades'] ?? []; // Conserva las calidades recibidas.
          _relacionesCalidad =
              catalogos['relaciones'] ?? []; // Aplica las asociaciones reales.
        });
        return; // Evita mezclar la fuente controlada con Supabase.
      }
      final respuesta = await SupabaseDatabase.client
          .from(SupabaseTables.tiposProducto)
          .select();
      final calidades = await SupabaseDatabase.client
          .from(SupabaseTables.calidadesProducto)
          .select(); // Consulta las calidades existentes.
      final relaciones = await SupabaseDatabase.client
          .from('tipo_calidad_producto')
          .select('id_tipo, id_calidad'); // Consulta las asociaciones reales, sin ofrecer calidades de otras categorías.
      if (mounted) {
        _relacionesCalidad = List<Map<String, dynamic>>.from(
          relaciones,
        ); // Conserva las asociaciones existentes.
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

  Future<void> _agregarCatalogo({required bool esCalidad}) async {
    // Añade un registro desde el formulario del producto.
    if (_editandoCatalogo || (esCalidad && _categoria == null)) {
      return; // Evita solicitudes inválidas o repetidas.
    }
    setState(
      () => _editandoCatalogo = true,
    ); // Bloquea cambios de categoría durante la creación.
    final controlador =
        TextEditingController(); // Conserva el nombre escrito en el diálogo.
    final tipo = esCalidad
        ? 'CALIDAD'
        : 'CATEGORÍA'; // Describe el registro solicitado.
    final idCategoria = _categoria; // Conserva la relación de la calidad con la categoría elegida.
    try {
      // Mantiene el formulario ante cancelaciones y errores.
      final nombre = await showDialog<String>(
        // Solicita el nombre sin navegar a otra página.
        context: context, // Presenta el diálogo sobre el producto.
        builder: (dialogo) => AlertDialog(
          // Contiene únicamente los datos del nuevo registro.
          title: Text('AÑADIR $tipo'), // Identifica el catálogo.
          content: SizedBox(
            width: 360,
            child: FormularioDatos(
              campos: [
                CampoFormularioDatos(
                  controlador: controlador,
                  etiqueta: tipo,
                  textoAyuda: 'Nombre',
                ),
              ],
            ),
          ), // Reutiliza el formulario del proyecto.
          actions: [
            // Permite cancelar o revisar la creación.
            CartaNavegacion.accion(
              onPressed: () => Navigator.pop(dialogo),
              child: const Text('CANCELAR'),
            ), // Cancela sin guardar.
            CartaNavegacion.accion(
              onPressed: () {
                if (controlador.text.trim().isNotEmpty) {
                  Navigator.pop(dialogo, controlador.text.trim());
                }
              },
              child: const Text('CONTINUAR'),
            ), // Exige un nombre no vacío.
          ], // Finaliza las acciones del nombre.
        ), // Finaliza el diálogo de entrada.
      ); // Espera el nombre ingresado.
      if (nombre == null || !mounted) {
        return; // Conserva todos los datos si se cancela.
      }
      final confirmado = await showDialog<bool>(
        // Pide confirmación antes de escribir en la base.
        context: context, // Mantiene el producto debajo del diálogo.
        builder: (dialogo) => AlertDialog(
          // Presenta el nombre que se guardará.
          title: Text('CONFIRMAR $tipo'), // Identifica la operación.
          content: Text(
            '¿Confirmas añadir ${tipo.toLowerCase()} "$nombre"?',
          ), // Permite revisar el valor exacto.
          actions: [
            // Ofrece aceptar o cancelar explícitamente.
            CartaNavegacion.accion(
              onPressed: () => Navigator.pop(dialogo, false),
              child: const Text('CANCELAR'),
            ), // Descarta la creación.
            CartaNavegacion.accion(
              onPressed: () => Navigator.pop(dialogo, true),
              child: const Text('AÑADIR'),
            ), // Autoriza guardar el registro.
          ], // Finaliza las acciones de confirmación.
        ), // Finaliza la confirmación.
      ); // Espera la decisión.
      if (confirmado != true || !mounted) {
        return; // No realiza escrituras sin confirmar.
      }
      final columna = esCalidad
          ? 'nombre_calidad'
          : 'nombre_tipo'; // Identifica el nombre del catálogo.
      final Map<String, dynamic>
      registro; // Conserva la opción creada o reutilizada.
      if (esCalidad) {
        final respuesta = await SupabaseDatabase.client.rpc(
          'crear_calidad_categoria',
          params: {'p_id_tipo': idCategoria, 'p_nombre': nombre},
        ); // Crea la calidad y su relación de forma atómica.
        registro = Map<String, dynamic>.from(
          (respuesta as List).single as Map,
        ); // Recupera el identificador real.
      } else {
        final actuales = await SupabaseDatabase.client
            .from(SupabaseTables.tiposProducto)
            .select(); // Evita duplicados por espacios o mayúsculas.
        final coincidencias = actuales.where(
          (fila) =>
              fila[columna].toString().trim().toLowerCase() ==
              nombre.toLowerCase(),
        ); // Busca una categoría existente.
        registro = coincidencias.isNotEmpty
            ? Map<String, dynamic>.from(coincidencias.first)
            : await SupabaseDatabase.client
                  .from(SupabaseTables.tiposProducto)
                  .insert({columna: nombre})
                  .select()
                  .single(); // Deja que la base asigne el ID.
      }
      if (!mounted) return; // Evita actualizar una página cerrada.
      setState(() {
        // Selecciona inmediatamente el registro creado o encontrado.
        final lista = esCalidad
            ? _calidades
            : _categorias; // Elige el catálogo local correspondiente.
        lista.removeWhere(
          (fila) => fila['id'] == registro['id'],
        ); // Evita duplicarlo en el menú.
        lista.add(registro); // Incluye el registro confirmado.
        lista.sort(
          (a, b) => a[columna].toString().compareTo(b[columna].toString()),
        ); // Conserva el orden alfabético.
        if (esCalidad) {
          _relacionesCalidad.removeWhere(
            (fila) =>
                fila['id_tipo'] == idCategoria &&
                fila['id_calidad'] == registro['id'],
          ); // Evita repetir la asociación local.
          _relacionesCalidad.add({
            'id_tipo': idCategoria,
            'id_calidad': registro['id'],
          }); // Habilita la nueva calidad solo en la categoría elegida.
          _calidad = (registro['id'] as num).toInt();
        } else {
          _categoria = (registro['id'] as num).toInt();
          _calidad = null;
        } // Selecciona la clave y restablece la dependencia.
      }); // Conserva los demás datos del producto y del cliente.
    } catch (error) {
      // Muestra errores sin perder la información ingresada.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo añadir el registro: $error')),
        ); // Informa el fallo de guardado.
      }
    } finally {
      // Restablece la edición aun cuando se cancela.
      if (mounted) {
        setState(
          () => _editandoCatalogo = false,
        ); // Habilita nuevamente los selectores.
      }
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      ); // Espera a que termine la salida del diálogo.
      controlador
          .dispose(); // Libera el controlador después de retirar su campo.
    } // Finaliza la recuperación del estado.
  } // Finaliza la creación dentro del registro.

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
    if (_guardando || _editandoCatalogo || !_clave.currentState!.validate()) {
      return; // Evita registros inválidos.
    }
    setState(() => _guardando = true); // Indica el guardado.
    try {
      final datos = <String, dynamic>{
        'cod_barra': _nombre.text.trim().isEmpty
            ? null
            : _nombre.text.trim(), // Conserva la columna existente.
        'calidad':
            _calidad, // Guarda o limpia la calidad según la categoría elegida.
        'tipo': _categoria, // Conserva la categoría seleccionada.
        'precio': int.parse(_precio.text.trim()),
        'stock': int.parse(
          _stock.text.trim(),
        ), // Conserva precio y existencias.
      }; // Comparte los mismos campos entre registro y edición.
      if (widget.productoInicial == null) {
        await SupabaseDatabase.client.from(SupabaseTables.productos).insert({
          'codigo_producto': _codigo.text.trim(),
          ...datos,
        }); // Crea únicamente desde Añadir producto.
      } else {
        await SupabaseDatabase.client
            .from(SupabaseTables.productos)
            .update(datos)
            .eq('codigo_producto', widget.productoInicial!['codigo_producto'])
            .select('codigo_producto')
            .single(); // Actualiza el producto existente sin duplicarlo ni cambiar su clave.
      }
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
    titulo: widget.productoInicial == null
        ? 'Creación de producto'
        : 'Edición de producto',
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
                    habilitado: !_guardando && widget.productoInicial == null, // Conserva la clave utilizada por las ventas existentes.
                  ), // Conserva el código obligatorio.
                  CampoFormularioDatos(
                    controlador: _precio,
                    etiqueta: widget.productoInicial == null
                        ? 'PRECIO DEL PRODUCTO NUEVO:'
                        : 'PRECIO DEL PRODUCTO:',
                    textoAyuda: 'Precio',
                    tipoTeclado: TextInputType.number,
                    validador: _entero,
                    habilitado: !_guardando,
                  ), // Configura el precio.
                  CampoFormularioDatos(
                    controlador: _stock,
                    etiqueta: widget.productoInicial == null
                        ? 'CANTIDAD INICIAL EN BODEGA:'
                        : 'CANTIDAD EN BODEGA:',
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
                          ? (widget.productoInicial == null
                                ? 'CALIDAD DEL PRODUCTO NUEVO:'
                                : 'CALIDAD DEL PRODUCTO:')
                          : (widget.productoInicial == null
                                ? 'CATEGORÍA DEL PRODUCTO NUEVO:'
                                : 'CATEGORÍA DEL PRODUCTO:'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ), // Identifica cada catálogo.
                    const SizedBox(
                      height: 10,
                    ), // Separa el título del selector.
                    InputDecorator(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFD9D9D9),
                        enabled:
                            !_guardando &&
                            !_editandoCatalogo &&
                            (!esCalidad || _categoria != null),
                      ), // Conserva el diseño y el orden obligatorio.
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Object>(
                          value: esCalidad ? _calidad : _categoria, // Usa una selección controlada para restablecer la calidad al cambiar de categoría.
                          isExpanded: true,
                          menuMaxHeight:
                              300, // Permite desplazar catálogos extensos.
                          hint: Text(
                            esCalidad && _categoria == null
                                ? 'SELECCIONA PRIMERO UNA CATEGORÍA'
                                : esCalidad
                                ? 'Calidad'
                                : 'Categoría',
                          ),
                          items: [
                            for (final fila
                                in (esCalidad
                                    ? _calidades.where(
                                        (calidad) => _relacionesCalidad.any(
                                          (relacion) =>
                                              relacion['id_tipo'] ==
                                                  _categoria &&
                                              relacion['id_calidad'] ==
                                                  calidad['id'],
                                        ),
                                      )
                                    : _categorias))
                              DropdownMenuItem(
                                value: fila['id'],
                                child: Text(
                                  fila[esCalidad
                                              ? 'nombre_calidad'
                                              : 'nombre_tipo']
                                          ?.toString() ??
                                      'Sin nombre',
                                ),
                              ),
                            DropdownMenuItem(
                              value: -1,
                              child: Text(
                                esCalidad
                                    ? 'AÑADIR CALIDAD'
                                    : 'AÑADIR CATEGORÍA',
                              ),
                            ), // Abre el registro sin abandonar el producto.
                          ],
                          onChanged:
                              _guardando ||
                                  _editandoCatalogo ||
                                  (esCalidad && _categoria == null)
                              ? null
                              : (valor) {
                                  if (valor == -1) {
                                    _agregarCatalogo(esCalidad: esCalidad); // Pide nombre y confirmación antes de guardar.
                                  } else {
                                    setState(() {
                                      if (esCalidad) {
                                        _calidad = valor;
                                      } else {
                                        _categoria = valor;
                                        _calidad = null;
                                      }
                                    }); // Descarta la calidad de la categoría anterior.
                                  }
                                },
                        ),
                      ),
                    ), // Mantiene categoría y calidad dependientes.
                    const SizedBox(
                      height: 28,
                    ), // Conserva la separación de los campos.
                  ],
                  FormularioDatos(
                    ancho: 1250,
                    campos: [
                      CampoFormularioDatos(
                        controlador: _nombre,
                        etiqueta: widget.productoInicial == null
                            ? 'CÓDIGO DE BARRA DEL PRODUCTO NUEVO:'
                            : 'CÓDIGO DE BARRA DEL PRODUCTO:',
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
              onPressed: _guardando || _editandoCatalogo ? null : _registrar,
              icon: const Icon(Icons.download),
              label: Text(
                _guardando
                    ? 'GUARDANDO...'
                    : widget.productoInicial == null
                    ? 'REGISTRAR'
                    : 'GUARDAR CAMBIOS',
              ),
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
