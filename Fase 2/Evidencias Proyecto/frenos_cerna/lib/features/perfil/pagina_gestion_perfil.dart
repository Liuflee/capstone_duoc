import 'package:flutter/material.dart'; // Construye las vistas de perfiles.
import 'package:frenos_cerna/features/perfil/data/perfiles_repository.dart'; // Conserva las operaciones reales de consulta y gestión.
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart'; // Reutiliza las barras y el menú.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart'; // Conserva las dimensiones de las acciones.
import 'package:frenos_cerna/shared/widgets/formulario_datos.dart'; // Reutiliza los campos del proyecto.
import 'package:frenos_cerna/shared/widgets/tabla_datos.dart'; // Reutiliza búsqueda y filtros de perfiles.

enum ModoPerfil {
  ver,
  crear,
  editar,
  eliminar,
} // Distingue funciones sin mezclar consulta y modificación.

extension RutaModoPerfil on ModoPerfil { // Conserva las rutas de Flutter en inglés.
  String get ruta => switch (this) { ModoPerfil.ver => 'view', ModoPerfil.crear => 'new', ModoPerfil.editar => 'edit', ModoPerfil.eliminar => 'remove' }; // Relaciona cada vista con su ruta.
} // Finaliza los nombres de navegación.

class PaginaSeleccionarPerfil extends StatefulWidget {
  // Selecciona al dueño o mecánico sobre el que se actuará.
  final TipoPerfil tipo; // Limita la lista a su sección.
  final ModoPerfil modo; // Conserva la acción elegida.
  final PerfilesRepository
  repositorio; // Permite probar las vistas sin datos reales.
  const PaginaSeleccionarPerfil({
    super.key,
    required this.tipo,
    required this.modo,
    this.repositorio = const PerfilesRepository(),
  }); // Configura el acceso.
  @override // Crea el catálogo de la sección.
  State<PaginaSeleccionarPerfil> createState() =>
      _PaginaSeleccionarPerfilState(); // Conserva la consulta al buscar.
} // Finaliza la selección pública.

class _PaginaSeleccionarPerfilState extends State<PaginaSeleccionarPerfil> {
  // Conserva la carga de perfiles.
  late Future<List<PerfilGestion>>
  _perfiles; // Consulta una sola vez por carga.
  @override // Inicia el catálogo.
  void initState() {
    super.initState();
    _perfiles = widget.repositorio.listar(widget.tipo);
  } // Recupera solamente perfiles visibles para la sesión.

  @override // Presenta el selector con tabla y acciones existentes.
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Seleccionar perfil ${widget.tipo.nombre.toLowerCase()}',
    activo: 'Perfil',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mantiene el ancho disponible para la tabla.
        Align(
          alignment: Alignment.centerLeft,
          child: CartaNavegacion.accion(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_return),
            label: const Text('VOLVER A PERFILES'),
          ),
        ), // Regresa al panel.
        const SizedBox(height: 24), // Separa las acciones de la tabla.
        Expanded(
          child: FutureBuilder<List<PerfilGestion>>(
            future: _perfiles,
            builder: (context, estado) {
              // Conserva la carga y los errores de permisos.
              if (estado.hasError) {
                return Column(
                  children: [
                    Text('No se pudieron cargar los perfiles: ${estado.error}'),
                    CartaNavegacion.accion(
                      onPressed: () => setState(
                        () =>
                            _perfiles = widget.repositorio.listar(widget.tipo),
                      ),
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                ); // Permite recuperar la consulta.
              }
              if (!estado.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                ); // Informa la carga.
              }
              return TablaDatos(
                nombresColumnas: const ['NOMBRE', 'TIPO', 'SELECCIONAR'],
                camposColumnas: const ['nombre', 'tipo', ''],
                anchosColumnas: const [5, 3, 2],
                mensajeSinDatos: 'No hay perfiles visibles en esta sección.',
                filas: estado.data!
                    .map(
                      (perfil) => <String, dynamic>{
                        'nombre': perfil.nombre,
                        'tipo': perfil.tipo.nombre,
                        'perfil': perfil,
                      },
                    )
                    .toList(),
                celdasPersonalizadas: {
                  2: (context, fila) => CartaNavegacion.accion(
                    tipoBoton: 'icon',
                    tooltip: 'Seleccionar perfil',
                    onPressed: () async {
                      // Abre la vista específica del registro.
                      final actualizado = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          settings: RouteSettings(
                            name:
                                '/profiles/${widget.tipo == TipoPerfil.dueno ? 'owner' : 'mechanic'}/${widget.modo.ruta}/details',
                          ),
                          builder: (context) => PaginaGestionPerfil(
                            tipo: widget.tipo,
                            modo: widget.modo,
                            perfil: fila['perfil'] as PerfilGestion,
                            repositorio: widget.repositorio,
                          ),
                        ),
                      ); // Conserva la clave real seleccionada.
                      if (actualizado == true && mounted) {
                        setState(
                          () => _perfiles = widget.repositorio.listar(
                            widget.tipo,
                          ),
                        ); // Refresca la lista después de editar o eliminar.
                      }
                    },
                    child: const Icon(Icons.search, size: 28),
                  ),
                },
              ); // Mantiene intacto el formato de acciones dentro de la tabla.
            },
          ),
        ), // Finaliza la consulta de perfiles.
      ],
    ),
  ); // Finaliza el selector.
} // Finaliza el estado del catálogo.

class PaginaGestionPerfil extends StatefulWidget {
  // Reutiliza el mismo diseño para ver, crear, editar y eliminar.
  final TipoPerfil tipo; // Define la sección de dueño o mecánico.
  final ModoPerfil modo; // Define qué campos y acciones están permitidos.
  final PerfilGestion?
  perfil; // Conserva el registro seleccionado; permanece vacío al crear.
  final bool miPerfil; // Solicita expresamente el usuario autenticado.
  final PerfilesRepository
  repositorio; // Permite verificar cada operación sin datos reales.
  const PaginaGestionPerfil({
    super.key,
    required this.tipo,
    required this.modo,
    this.perfil,
    this.miPerfil = false,
    this.repositorio = const PerfilesRepository(),
  }); // Configura la vista sin compartir controladores entre perfiles.
  @override // Crea el estado del formulario.
  State<PaginaGestionPerfil> createState() => _PaginaGestionPerfilState(); // Conserva los valores mientras se confirma una acción.
} // Finaliza la vista pública.

class _PaginaGestionPerfilState extends State<PaginaGestionPerfil> {
  // Administra solamente los campos del perfil.
  final _nombre =
      TextEditingController(); // Conserva el nombre editable o de consulta.
  final _correo = TextEditingController(); // Solicita el correo únicamente para una cuenta nueva.
  final _contrasena = TextEditingController(); // Solicita la contraseña sin almacenarla en el perfil.
  final _formulario =
      GlobalKey<FormState>(); // Valida los campos antes de guardar.
  PerfilGestion? _perfil,
      _actual; // Conserva el perfil consultado y la autorización de la sesión.
  bool
  _cargando = true,
  _guardando =
      false; // Evita mostrar valores incompletos o enviar acciones repetidas.
  String? _error; // Conserva errores de consulta o permisos.
  bool get _editable =>
      widget.modo == ModoPerfil.crear ||
      widget.modo ==
          ModoPerfil
              .editar; // Consulta y eliminación nunca permiten cambiar datos.
  @override // Recupera la identidad y los permisos al entrar.
  void initState() {
    super.initState();
    _cargar();
  } // Mantiene el perfil propio separado de la selección.

  Future<void> _cargar() async {
    // Carga el formulario sin rellenar la creación con datos ajenos.
    try {
      // Conserva la vista si falla la sesión.
      final actual = await widget.repositorio
          .obtenerActual(); // Verifica quién está operando.
      if (!mounted) return; // Evita actualizar una vista cerrada.
      setState(() {
        _actual = actual;
        _perfil = widget.miPerfil ? actual : widget.perfil;
        if (widget.modo != ModoPerfil.crear) {
          _nombre.text = _perfil?.nombre ?? '';
          _correo.text = _perfil?.correo ?? '';
        }
        _cargando = false;
        _error = null;
      }); // Deja nombre, correo y contraseña vacíos al crear.
    } catch (error) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = error.toString();
        });
      }
    } // Presenta errores reales de acceso.
  } // Finaliza la carga.

  @override // Libera los valores sensibles al salir.
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  } // No conserva contraseñas fuera del formulario.

  Future<void> _guardar() async {
    // Crea o edita exclusivamente cuando la vista lo permite.
    if (_guardando ||
        !_editable ||
        _actual?.tipo != TipoPerfil.dueno ||
        !_formulario.currentState!.validate()) {
      return; // Exige autorización y campos válidos.
    }
    setState(() => _guardando = true); // Bloquea dobles clics.
    try {
      // Mantiene el formulario ante errores del servidor.
      if (widget.modo == ModoPerfil.crear) {
        await widget.repositorio.crear(
          tipo: widget.tipo,
          nombre: _nombre.text,
          correo: _correo.text,
          contrasena: _contrasena.text,
        );
      } else {
        await widget.repositorio.editar(_perfil!, _nombre.text);
      } // No permite modificar desde Ver o Eliminar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.modo == ModoPerfil.crear
                  ? 'Perfil creado. La cuenta puede requerir confirmar su correo.'
                  : 'Perfil actualizado.',
            ),
          ),
        );
        Navigator.pop(context, true);
      } // Confirma únicamente después de una operación real.
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar el perfil: $error');
      }
    } // Conserva los datos para corregir.
    finally {
      if (mounted) setState(() => _guardando = false);
    } // Habilita las acciones al terminar.
  } // Finaliza el guardado.

  Future<void> _eliminar() async {
    // Solicita confirmación explícita desde la vista de eliminación.
    if (_guardando || _perfil == null || _actual?.tipo != TipoPerfil.dueno) {
      return; // Exige la sección y los permisos correctos.
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('ELIMINAR PERFIL'),
        content: Text(
          '¿Eliminar el perfil de ${_perfil!.nombre}? Esta acción retira su acceso a la aplicación.',
        ),
        actions: [
          CartaNavegacion.accion(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('CANCELAR'),
          ),
          CartaNavegacion.accion(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    ); // Permite revisar la persona elegida antes de retirar el acceso.
    if (confirmar != true || !mounted) return; // Cancela sin cambios.
    setState(() => _guardando = true); // Impide repetir la eliminación.
    try {
      await widget.repositorio.eliminar(_perfil!);
      if (mounted) Navigator.pop(context, true);
    } // Actualiza el catálogo al finalizar.
    catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo eliminar el perfil: $error');
      }
    } // Presenta errores sin ocultar el registro.
    finally {
      if (mounted) setState(() => _guardando = false);
    } // Restablece el formulario.
  } // Finaliza la eliminación.

  @override // Conserva un diseño común y limita las funciones según el modo.
  Widget build(BuildContext context) {
    // Presenta nombre y rol a partir de datos reales.
    final tipo =
        _perfil?.tipo ??
        widget.tipo; // Muestra el rol real también en Mi perfil.
    final titulo = widget.miPerfil
        ? 'Mi perfil'
        : (widget.modo == ModoPerfil.ver
                  ? 'Ver perfil '
                  : widget.modo == ModoPerfil.crear
                  ? 'Crear perfil '
                  : widget.modo == ModoPerfil.editar
                  ? 'Editar perfil '
                  : 'Eliminar perfil ') +
              tipo.nombre.toLowerCase(); // Distingue las cuatro vistas.
    return EstructuraPagina(
      titulo: titulo,
      activo: 'Perfil',
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Conserva ancho y alineación comunes.
                Align(
                  alignment: Alignment.centerLeft,
                  child: CartaNavegacion.accion(
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_return),
                    label: const Text('VOLVER A PERFILES'),
                  ),
                ), // Regresa sin realizar cambios.
                const SizedBox(height: 28), // Separa navegación y datos.
                if (_cargando)
                  const Center(child: CircularProgressIndicator())
                else if (_perfil == null && widget.modo != ModoPerfil.crear)
                  const Text(
                    'No hay un perfil disponible. Inicia sesión o selecciona una persona.',
                  )
                else ...[
                  // Evita mostrar datos ficticios.
                  Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFFBDBDBD),
                      child: Icon(
                        tipo == TipoPerfil.dueno
                            ? Icons.business_center_outlined
                            : Icons.build_outlined,
                        size: 42,
                        color: Colors.black,
                      ),
                    ),
                  ), // Distingue ambos tipos sin fotografías.
                  const SizedBox(height: 20), // Separa el icono del formulario.
                  Text(
                    tipo.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ), // Identifica el rol de la persona.
                  const SizedBox(height: 24), // Separa el rol de los campos.
                  FormularioDatos(
                    claveFormulario: _formulario,
                    campos: [
                      CampoFormularioDatos(
                        controlador: _nombre,
                        etiqueta: 'NOMBRE:',
                        textoAyuda: 'Nombre del perfil',
                        habilitado:
                            _editable &&
                            !_guardando &&
                            _actual?.tipo == TipoPerfil.dueno,
                        validador: (valor) => (valor ?? '').trim().isEmpty
                            ? 'Ingresa el nombre'
                            : null,
                      ),
                      if (widget.modo == ModoPerfil.crear) ...[
                        CampoFormularioDatos(
                          controlador: _correo,
                          etiqueta: 'CORREO:',
                          textoAyuda: 'Correo de la cuenta nueva',
                          tipoTeclado: TextInputType.emailAddress,
                          habilitado:
                              !_guardando && _actual?.tipo == TipoPerfil.dueno,
                          validador: (valor) =>
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch((valor ?? '').trim())
                              ? null
                              : 'Ingresa un correo válido',
                        ),
                        CampoFormularioDatos(
                          controlador: _contrasena,
                          etiqueta: 'CONTRASEÑA:',
                          textoAyuda: 'Al menos 6 caracteres',
                          esContrasena: true,
                          habilitado:
                              !_guardando && _actual?.tipo == TipoPerfil.dueno,
                          validador: (valor) => (valor ?? '').length >= 6
                              ? null
                              : 'Usa al menos 6 caracteres',
                        ),
                      ],
                      if (widget.modo != ModoPerfil.crear &&
                          _perfil?.correo != null)
                        CampoFormularioDatos(
                          controlador: _correo,
                          etiqueta: 'CORREO:',
                          habilitado: false,
                        ),
                    ],
                  ), // Mantiene campos vacíos al crear y datos de solo lectura al ver o eliminar.
                  const SizedBox(
                    height: 24,
                  ), // Separa los campos de las acciones.
                  if (_editable)
                    Align(
                      alignment: Alignment.centerRight,
                      child: CartaNavegacion.accion(
                        onPressed:
                            _guardando || _actual?.tipo != TipoPerfil.dueno
                            ? null
                            : _guardar,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          widget.modo == ModoPerfil.crear
                              ? 'CREAR PERFIL'
                              : 'GUARDAR CAMBIOS',
                        ),
                      ),
                    ), // Ofrece guardado únicamente en creación y edición.
                  if (widget.modo == ModoPerfil.eliminar)
                    Align(
                      alignment: Alignment.centerRight,
                      child: CartaNavegacion.accion(
                        onPressed:
                            _guardando ||
                                _actual?.tipo != TipoPerfil.dueno ||
                                _actual?.id == _perfil?.id
                            ? null
                            : _eliminar,
                        icon: const Icon(Icons.person_remove_outlined),
                        label: const Text('ELIMINAR PERFIL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD96363),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ), // Presenta la eliminación solo en su propia vista.
                  if (widget.modo != ModoPerfil.ver &&
                      _actual?.tipo != TipoPerfil.dueno)
                    const Text(
                      'Inicia sesión como dueño para administrar perfiles.',
                    ), // Explica las acciones deshabilitadas sin modificar permisos.
                ], // Finaliza los datos del perfil.
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text(_error!),
                  if (!_guardando)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CartaNavegacion.accion(
                        onPressed: _cargar,
                        child: const Text('REINTENTAR CARGA'),
                      ),
                    ),
                ], // Permite recuperar la vista ante errores de consulta.
              ],
            ),
          ),
        ),
      ),
    ); // Finaliza el marco compartido.
  } // Finaliza la construcción.
} // Finaliza el estado del perfil.
