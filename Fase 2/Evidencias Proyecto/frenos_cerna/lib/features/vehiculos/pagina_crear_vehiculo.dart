// Importa Flutter y las páginas necesarias para vincular clientes.
import 'package:flutter/material.dart';
import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/clientes/pagina_clientes.dart';
import 'package:frenos_cerna/features/clientes/pagina_crear_cliente.dart';
import 'package:frenos_cerna/features/clientes/presentation/selector_cliente.dart';
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

// Registra vehículos usando exclusivamente el esquema proporcionado.
class PaginaCrearVehiculo extends StatefulWidget {
  const PaginaCrearVehiculo({
    super.key,
  }); // Conserva una única instancia del formulario al navegar.
  @override // Crea el estado que mantiene los datos ingresados.
  State<PaginaCrearVehiculo> createState() => _PaginaCrearVehiculoState();
} // Finaliza la página pública.

class _PaginaCrearVehiculoState extends State<PaginaCrearVehiculo> {
  final _patente =
      TextEditingController(); // Conserva la patente al abrir otras vistas.
  final _kilometraje =
      TextEditingController(); // Conserva el kilometraje ingresado.
  final _clave = GlobalKey<FormState>(); // Valida los campos del vehículo.
  List<Map<String, dynamic>> _marcas =
      []; // Conserva el catálogo existente de marcas.
  List<Map<String, dynamic>> _modelos =
      []; // Conserva el catálogo existente de modelos.
  int? _marca; // Conserva la selección de marca.
  int? _modelo; // Conserva id_modelo al navegar a Crear cliente.
  Cliente? _cliente; // Conserva el cliente que se vinculará mediante su RUT.
  String? _errorCatalogos; // Informa problemas al recuperar modelos.
  bool _editandoCatalogo = false; // Impide crear dos entradas simultáneamente.
  bool _guardando = false; // Evita registros simultáneos.
  @override // Recupera los catálogos al entrar en el registro.
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final marcas = await SupabaseDatabase.client
          .from(SupabaseTables.marcasVehiculo)
          .select('id, marca')
          .order('marca'); // Consulta las marcas existentes.
      final modelos = await SupabaseDatabase.client
          .from(SupabaseTables.modelosVehiculo)
          .select('id, modelo, id_marca')
          .order('modelo'); // Consulta los modelos existentes.
      if (mounted) {
        setState(() {
          _marcas = List<Map<String, dynamic>>.from(marcas);
          _modelos = List<Map<String, dynamic>>.from(modelos);
          _errorCatalogos = null;
        }); // Actualiza los catálogos sin reiniciar el formulario.
      }
    } catch (error) {
      if (mounted) setState(() => _errorCatalogos = error.toString());
    } // Permite reintentar sin perder lo ingresado.
  } // Finaliza la carga.

  Widget _selectorCatalogo({required bool esModelo}) {
    // Construye un selector controlado por el estado de la página.
    final registros = esModelo
        ? _modelos.where((fila) => fila['id_marca'] == _marca).toList()
        : _marcas; // Limita los modelos a su marca.
    final etiqueta =
        esModelo ? 'MODELO' : 'MARCA'; // Identifica el catálogo solicitado.
    return InputDecorator(
      // Mantiene el borde de los campos existentes.
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
      ), // Conserva el título y el diseño.
      child: DropdownButtonHideUnderline(
        // Evita dibujar una segunda línea inferior.
        child: DropdownButton<int>(
          // Usa un valor controlado para no seleccionar la opción de añadir.
          value: esModelo
              ? _modelo
              : _marca, // Refleja únicamente una selección real.
          isExpanded: true, // Ajusta el menú al ancho del campo.
          menuMaxHeight: 300, // Permite desplazar los catálogos largos.
          hint: Text(
            esModelo && _marca == null
                ? 'SELECCIONA PRIMERO UNA MARCA'
                : 'SELECCIONAR',
          ), // Explica el orden obligatorio.
          items: [
            // Incluye los registros existentes y la creación local.
            for (final fila
                in registros) // Recorre solamente el catálogo correspondiente.
              DropdownMenuItem(
                value: (fila['id'] as num).toInt(),
                child: Text(fila[esModelo ? 'modelo' : 'marca'].toString()),
              ), // Identifica cada registro por su clave real.
            DropdownMenuItem(
              value: -1,
              child: Text(esModelo ? 'AÑADIR MODELO' : 'AÑADIR MARCA'),
            ), // Abre la creación sin cambiar de página.
            if (registros.isNotEmpty)
              DropdownMenuItem(
                value: -3,
                child: Text(esModelo
                    ? 'EDITAR NOMBRE DEL MODELO'
                    : 'EDITAR NOMBRE DE LA MARCA'),
              ),
          ], // Finaliza las opciones.
          onChanged:
              _guardando || _editandoCatalogo || (esModelo && _marca == null)
                  ? null
                  : (valor) {
                      // Bloquea modelos hasta seleccionar una marca.
                      if (valor == -1) {
                        // Distingue la acción de creación de una selección.
                        _agregarCatalogo(
                          esModelo: esModelo,
                        ); // Solicita nombre y confirmación antes de guardar.
                      } else if (valor == -3) {
                        _editarCatalogo(esModelo: esModelo);
                      } else {
                        // Aplica la selección existente.
                        setState(() {
                          // Actualiza los campos relacionados.
                          if (esModelo) {
                            _modelo = valor;
                          } else {
                            _marca = valor;
                            _modelo = null;
                          } // Descarta el modelo anterior cuando cambia la marca.
                        }); // Conserva patente, kilometraje y cliente.
                      } // Finaliza la selección.
                    }, // Finaliza la reacción al menú.
        ), // Finaliza el desplegable.
      ), // Finaliza el contenedor sin subrayado.
    ); // Finaliza el campo del catálogo.
  } // Finaliza el selector reutilizado.

  Future<void> _editarCatalogo({required bool esModelo}) async {
    final registros = esModelo
        ? _modelos.where((fila) => fila['id_marca'] == _marca).toList()
        : _marcas;
    if (_editandoCatalogo || registros.isEmpty) return;
    final columna = esModelo ? 'modelo' : 'marca';
    final registro = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogo) => SimpleDialog(
        title: Text('SELECCIONA ${esModelo ? 'MODELO' : 'MARCA'}'),
        children: [
          for (final fila in registros)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(dialogo, Map<String, dynamic>.from(fila)),
              child: Text(fila[columna].toString()),
            ),
        ],
      ),
    );
    if (registro == null || !mounted) return;
    final controlador =
        TextEditingController(text: registro[columna].toString());
    try {
      final nombre = await showDialog<String>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: Text('EDITAR ${esModelo ? 'MODELO' : 'MARCA'}'),
          content: TextField(controller: controlador, autofocus: true),
          actions: [
            CartaNavegacion.accion(
                onPressed: () => Navigator.pop(dialogo),
                child: const Text('CANCELAR')),
            CartaNavegacion.accion(
              onPressed: () {
                final texto = controlador.text.trim();
                if (texto.isNotEmpty) Navigator.pop(dialogo, texto);
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      );
      if (nombre == null || !mounted || nombre == registro[columna]) return;
      setState(() => _editandoCatalogo = true);
      await SupabaseDatabase.client
          .from(esModelo
              ? SupabaseTables.modelosVehiculo
              : SupabaseTables.marcasVehiculo)
          .update({columna: nombre}).eq('id', registro['id']);
      if (!mounted) return;
      setState(() {
        final fila = (esModelo ? _modelos : _marcas)
            .firstWhere((item) => item['id'] == registro['id']);
        fila[columna] = nombre;
        (esModelo ? _modelos : _marcas).sort(
            (a, b) => a[columna].toString().compareTo(b[columna].toString()));
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nombre actualizado.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo actualizar el nombre: $error')));
    } finally {
      controlador.dispose();
      if (mounted) setState(() => _editandoCatalogo = false);
    }
  }

  Future<void> _agregarCatalogo({required bool esModelo}) async {
    // Añade un registro desde el formulario del vehículo.
    if (_editandoCatalogo || (esModelo && _marca == null)) {
      return; // Evita solicitudes inválidas o repetidas.
    }
    setState(
      () => _editandoCatalogo = true,
    ); // Bloquea cambios de marca durante la creación.
    final controlador =
        TextEditingController(); // Conserva el nombre escrito en el diálogo.
    final tipo =
        esModelo ? 'MODELO' : 'MARCA'; // Describe el registro solicitado.
    final idMarca =
        _marca; // Conserva la relación del modelo con la marca elegida.
    try {
      // Mantiene el formulario ante cancelaciones y errores.
      final nombre = await showDialog<String>(
        // Solicita el nombre sin navegar a otra página.
        context: context, // Presenta el diálogo sobre el vehículo.
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
        context: context, // Mantiene el vehículo debajo del diálogo.
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
      final tabla = esModelo
          ? SupabaseTables.modelosVehiculo
          : SupabaseTables.marcasVehiculo; // Utiliza las tablas existentes.
      final columna = esModelo
          ? 'modelo'
          : 'marca'; // Utiliza el nombre real de cada columna.
      final actuales = await SupabaseDatabase.client
          .from(tabla)
          .select(); // Consulta los registros para evitar duplicados por mayúsculas o espacios.
      final coincidencias = actuales.where(
        (fila) =>
            fila[columna].toString().trim().toLowerCase() ==
                nombre.toLowerCase() &&
            (!esModelo || fila['id_marca'] == idMarca),
      ); // Compara modelos solamente dentro de su marca.
      final Map<String, dynamic>
          registro; // Conserva el registro existente o recién creado.
      if (coincidencias.isNotEmpty) {
        // Reutiliza una coincidencia existente.
        registro = Map<String, dynamic>.from(
          coincidencias.first,
        ); // Evita insertar un nombre repetido.
      } else {
        // Inserta únicamente cuando el nombre no existe.
        registro = await SupabaseDatabase.client
            .from(tabla)
            .insert({columna: nombre, if (esModelo) 'id_marca': idMarca})
            .select()
            .single(); // Guarda exclusivamente columnas del esquema proporcionado.
      } // Finaliza la resolución del registro.
      if (!mounted) return; // Evita actualizar una página cerrada.
      setState(() {
        // Selecciona inmediatamente el registro creado o encontrado.
        final lista = esModelo
            ? _modelos
            : _marcas; // Elige el catálogo local correspondiente.
        lista.removeWhere(
          (fila) => fila['id'] == registro['id'],
        ); // Evita duplicarlo en el menú.
        lista.add(registro); // Incluye el registro confirmado.
        lista.sort(
          (a, b) => a[columna].toString().compareTo(b[columna].toString()),
        ); // Conserva el orden alfabético.
        if (esModelo) {
          _modelo = (registro['id'] as num).toInt();
        } else {
          _marca = (registro['id'] as num).toInt();
          _modelo = null;
        } // Selecciona la clave y restablece la dependencia.
      }); // Conserva los demás datos del vehículo y del cliente.
    } catch (error) {
      // Muestra errores sin perder la información ingresada.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().contains('23505') &&
                      error.toString().contains('_pkey')
                  ? 'El contador de IDs del catálogo está desactualizado. Ejecuta supabase/reparar_secuencias_catalogos.sql en Supabase.'
                  : 'No se pudo añadir el registro: $error',
            ),
          ), // Distingue un contador desactualizado de un nombre existente.
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

  @override // Libera los recursos solo al cerrar el registro.
  void dispose() {
    _patente.dispose();
    _kilometraje.dispose();
    super.dispose();
  }

  Future<void> _vincularCliente() async {
    final existente = await showDialog<bool>(
      context: context,
      builder: (menu) => Dialog(
        insetPadding: EdgeInsets.fromLTRB(
          24 +
              (MediaQuery.sizeOf(menu).width >= 700
                  ? MediaQuery.sizeOf(menu).width * 0.12
                  : 0), // Excluye el menú lateral para coincidir con el eje del contenido.
          24,
          24,
          24, // Conserva los márgenes seguros en móvil y ventanas pequeñas.
        ),
        alignment: Alignment
            .center, // Presenta la selección en el centro horizontal del área de contenido.
        backgroundColor: Colors.white, // Usa el fondo blanco de las páginas.
        surfaceTintColor:
            Colors.transparent, // Evita el tinte rosado del tema Material.
        child: SizedBox(
          key: const ValueKey(
              'dialogo_vincular_cliente'), // Permite verificar el eje del diálogo sin incluir la barrera modal.
          width:
              440, // Mantiene un ancho cómodo y se adapta a las pantallas pequeñas.
          child: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(
                  24,
                ), // Separa las opciones del borde de pantalla.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'VINCULAR CON CLIENTE',
                      style: TextStyle(fontSize: 20),
                    ), // Identifica el paso de vinculación.
                    const SizedBox(
                      height: 20,
                    ), // Separa el título de las opciones.
                    CartaNavegacion.accion(
                      onPressed: () => Navigator.pop(menu, true),
                      icon: const Icon(Icons.person_search),
                      label: const Text('CLIENTE EXISTENTE'),
                    ), // Abre la búsqueda por nombre o RUT.
                    const SizedBox(height: 12), // Separa las dos opciones.
                    CartaNavegacion.accion(
                      onPressed: () => Navigator.pop(menu, false),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('NUEVO CLIENTE'),
                    ), // Abre el registro de clientes.
                  ],
                ), // Finaliza las opciones de vinculación.
              ),
            ), // Respeta el área segura dentro del diálogo.
          ), // Permite desplazar las opciones si el alto es reducido.
        ), // Limita el ancho de la ventana.
      ),
    ); // Espera la elección sin retirar esta página.
    if (existente == null || !mounted) {
      return; // Conserva el cliente anterior si se cancela.
    }
    final Cliente? seleccionado = existente
        ? await seleccionarClienteExistente(
            context,
          ) // Devuelve un cliente ya registrado.
        : await Navigator.push<Cliente>(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/clients/new'),
              builder: (context) =>
                  const PaginaCrearCliente(devolverClienteCreado: true),
            ),
          ); // Mantiene esta ruta debajo del registro.
    if (seleccionado != null && mounted) {
      setState(() => _cliente = seleccionado);
    } // Vincula el cliente devuelto sin modificar patente, kilometraje ni modelo.
  } // Finaliza la vinculación.

  Future<void> _registrar() async {
    if (_guardando || !_clave.currentState!.validate()) {
      return; // Evita guardar campos inválidos.
    }
    if (_modelo == null || _cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un modelo y vincula un cliente.'),
        ),
      ); // Exige las relaciones obligatorias del esquema.
      return; // Conserva los datos para completar la vinculación.
    } // Finaliza la validación de relaciones.
    setState(() => _guardando = true); // Bloquea registros duplicados.
    try {
      await SupabaseDatabase.client.from(SupabaseTables.vehiculos).insert({
        'patente':
            _patente.text.trim().toUpperCase(), // Guarda la clave de vehículo.
        'kilometraje': double.parse(
          _kilometraje.text.trim().replaceAll(',', '.'),
        ), // Guarda el kilometraje numérico.
        'id_modelo': _modelo, // Guarda la referencia al modelo seleccionado.
        'rut_cliente': int.parse(
          _cliente!.id,
        ), // Guarda el vínculo con el cliente elegido o recién creado.
      }); // Usa exactamente las cuatro columnas de vehiculo_cliente.
      if (mounted) {
        Navigator.pop(
          context,
          true,
        ); // Regresa y permite actualizar el listado.
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar el vehículo: $error')),
        );
      }
    } // Conserva el formulario ante errores.
    finally {
      if (mounted) setState(() => _guardando = false);
    } // Restablece las acciones.
  } // Finaliza el registro.

  @override // Construye el formulario y la sección de vinculación.
  Widget build(BuildContext context) => EstructuraPagina(
        titulo: 'Registro de vehículo',
        activo: 'Vehiculos',
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1000,
              ), // Mantiene un ancho cómodo en escritorio.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CartaNavegacion.accion(
                      onPressed:
                          _guardando ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.keyboard_return),
                      label: const Text('VOLVER A VEHÍCULOS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2A0A0),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ), // Conserva la navegación de regreso.
                  const SizedBox(
                    height: 32,
                  ), // Separa la navegación del formulario.
                  FormularioDatos(
                    claveFormulario: _clave,
                    ancho: 1000,
                    campos: [
                      CampoFormularioDatos(
                        controlador: _patente,
                        etiqueta: 'PATENTE:',
                        textoAyuda: 'Patente del vehículo',
                        habilitado: !_guardando,
                        validador: (valor) => (valor ?? '').trim().isEmpty
                            ? 'Ingresa la patente'
                            : null,
                      ), // Configura la clave obligatoria.
                      CampoFormularioDatos(
                        controlador: _kilometraje,
                        etiqueta: 'KILOMETRAJE:',
                        textoAyuda: 'Kilometraje actual',
                        tipoTeclado: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        habilitado: !_guardando,
                        validador: (valor) {
                          final numero = double.tryParse(
                            (valor ?? '').trim().replaceAll(',', '.'),
                          );
                          return numero == null ||
                                  !numero.isFinite ||
                                  numero < 0
                              ? 'Ingresa un kilometraje válido'
                              : null;
                        },
                      ), // Valida el valor numérico.
                    ],
                  ), // Finaliza los campos de texto.
                  const SizedBox(
                      height: 16), // Separa los catálogos de los campos.
                  _selectorCatalogo(
                    esModelo: false,
                  ), // Selecciona o añade la marca.
                  const SizedBox(height: 20), // Separa ambos catálogos.
                  _selectorCatalogo(
                    esModelo: true,
                  ), // Exige una marca antes de elegir modelo.
                  if (_errorCatalogos != null) ...[
                    Text(
                      'No se pudieron cargar marcas y modelos: $_errorCatalogos',
                    ),
                    CartaNavegacion.accion(
                      onPressed: _cargarCatalogos,
                      child: const Text('REINTENTAR CATÁLOGOS'),
                    ),
                  ], // Permite recuperar la carga sin borrar campos.
                  const SizedBox(
                    height: 36,
                  ), // Separa los datos del apartado de cliente.
                  const Text(
                    'CLIENTE VINCULADO',
                    style: TextStyle(fontSize: 22),
                  ), // Identifica la relación obligatoria.
                  const SizedBox(
                      height: 12), // Separa el título de la selección.
                  Text(
                    _cliente == null
                        ? 'Todavía no has seleccionado un cliente.'
                        : '${_cliente!.nombre} · RUT: ${_cliente!.id}',
                  ), // Confirma el cliente que se guardará.
                  const SizedBox(height: 16), // Separa el cliente de la acción.
                  CartaNavegacion.accion(
                    onPressed: _guardando ? null : _vincularCliente,
                    icon: const Icon(Icons.link),
                    label: Text(
                      _cliente == null
                          ? 'VINCULAR CON CLIENTE'
                          : 'CAMBIAR CLIENTE',
                    ),
                  ), // Permite elegir un cliente sin salir del registro.
                  const SizedBox(
                      height: 32), // Separa la vinculación del guardado.
                  Align(
                    alignment: Alignment.centerRight,
                    child: CartaNavegacion(
                      ancho: 240,
                      alto: 70,
                      texto: _guardando ? 'GUARDANDO...' : 'REGISTRAR VEHÍCULO',
                      icono: Icons.download,
                      color: const Color(0xFFB7B7B7),
                      alPresionar: _guardando ? null : _registrar,
                    ),
                  ), // Registra el vehículo y su cliente.
                ],
              ), // Finaliza el contenido.
            ),
          ),
        ),
      ); // Finaliza la página conservada durante la navegación.
} // Finaliza el estado de registro.
