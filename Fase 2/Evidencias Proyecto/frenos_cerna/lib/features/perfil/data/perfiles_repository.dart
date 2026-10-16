import 'package:supabase_flutter/supabase_flutter.dart'; // Crea cuentas mediante un cliente independiente de la sesión actual.
import 'package:frenos_cerna/core/data/supabase_database.dart'; // Reutiliza los permisos existentes de perfil_usuario.

enum TipoPerfil {
  dueno,
  mecanico,
} // Relaciona las secciones solicitadas con los roles actuales.

extension DatosTipoPerfil on TipoPerfil {
  // Conserva los nombres del negocio sin cambiar los roles de autenticación.
  String get nombre => this == TipoPerfil.dueno
      ? 'DUEÑO'
      : 'MECÁNICO'; // Presenta el nombre de la sección.
  String get rol => this == TipoPerfil.dueno
      ? 'administrador'
      : 'empleado'; // Utiliza los valores admitidos por la tabla actual.
} // Finaliza la descripción del tipo.

class PerfilGestion {
  // Conserva los datos reales disponibles de un perfil.
  final String id, nombre; // Identifica al usuario y su nombre visible.
  final TipoPerfil tipo; // Distingue dueño y mecánico.
  final String?
  correo; // Muestra el correo propio cuando la sesión lo proporciona.
  const PerfilGestion({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.correo,
  }); // Configura el perfil sin contraseñas almacenadas.
  factory PerfilGestion.fromJson(
    Map<String, dynamic> datos, {
    String? correo,
  }) => PerfilGestion(
    id: datos['user_id'] as String,
    nombre: datos['nombre'] as String,
    tipo: datos['rol'] == 'administrador'
        ? TipoPerfil.dueno
        : TipoPerfil.mecanico,
    correo: correo,
  ); // Lee el esquema existente.
} // Finaliza el modelo de gestión.

class PerfilesRepository {
  // Consulta y administra perfiles respetando la sesión y las políticas existentes.
  const PerfilesRepository(); // Permite sustituir la fuente en pruebas.
  Future<PerfilGestion?> obtenerActual() async {
    // Recupera únicamente el perfil autenticado.
    if (!SupabaseDatabase.isConfigured ||
        SupabaseDatabase.client.auth.currentUser == null) {
      return null; // Permite revisar las vistas sin inventar usuarios.
    }
    final usuario = SupabaseDatabase
        .client
        .auth
        .currentUser!; // Conserva la identidad de la sesión actual.
    final datos = await SupabaseDatabase.client
        .from(SupabaseTables.perfiles)
        .select('user_id, nombre, rol')
        .eq('user_id', usuario.id)
        .single(); // Respeta las políticas de consulta existentes.
    return PerfilGestion.fromJson(
      datos,
      correo: usuario.email,
    ); // Obtiene el correo desde la propia sesión.
  } // Finaliza la consulta del usuario actual.

  Future<List<PerfilGestion>> listar(TipoPerfil tipo) async {
    // Recupera perfiles visibles de la sección solicitada.
    if (!SupabaseDatabase.isConfigured ||
        SupabaseDatabase.client.auth.currentUser == null) {
      return []; // Mantiene el modo de revisión sin consultas inválidas.
    }
    final filas = await SupabaseDatabase.client
        .from(SupabaseTables.perfiles)
        .select('user_id, nombre, rol')
        .eq('rol', tipo.rol)
        .order(
          'nombre',
        ); // RLS limita los perfiles que puede consultar cada usuario.
    return filas
        .map((fila) => PerfilGestion.fromJson(fila))
        .toList(); // Conserva las claves reales para ver, editar o eliminar.
  } // Finaliza la consulta por sección.

  Future<void> _exigirDueno() async {
    // Verifica autorización antes de cualquier cambio de perfiles.
    if ((await obtenerActual())?.tipo != TipoPerfil.dueno) {
      throw StateError(
        'Solo el dueño puede administrar perfiles.',
      ); // No confía únicamente en botones ocultos.
    }
  } // Finaliza la comprobación de sesión.

  Future<void> crear({
    required TipoPerfil tipo,
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    // Crea la cuenta sin reemplazar el inicio de sesión del dueño.
    await _exigirDueno(); // Exige el rol administrativo existente.
    if (nombre.trim().isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo.trim()) ||
        contrasena.length < 6) {
      throw ArgumentError(
        'Completa un nombre, correo y contraseña válidos.',
      ); // Valida antes de crear una cuenta.
    }
    final existentes = await SupabaseDatabase.client
        .from(SupabaseTables.perfiles)
        .select('user_id'); // Conserva las identidades existentes para no convertir una creación en un cambio de rol accidental.
    final identificadores = existentes.map((fila) => fila['user_id']).toSet(); // Comprueba el resultado de Auth sin consultar contraseñas ni correos ajenos.
    final registro = SupabaseClient(
      const String.fromEnvironment('SUPABASE_URL'),
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ); // Aísla el registro de la sesión principal sin claves administrativas.
    try {
      // Mantiene el cliente temporal solo durante la creación.
      final respuesta = await registro.auth.signUp(
        email: correo.trim(),
        password: contrasena,
        data: {'nombre': nombre.trim()},
      ); // Utiliza el mismo registro autorizado por Supabase.
      final usuario =
          respuesta.user; // Recupera el identificador de la cuenta creada.
      if (usuario == null) {
        throw StateError(
          'Supabase no devolvió la cuenta creada.',
        ); // Evita anunciar éxito sin registro real.
      }
      if (identificadores.contains(usuario.id)) {
        throw StateError(
          'La cuenta ya tiene un perfil. Utiliza la opción de editar.',
        ); // Impide reasignar el rol de una cuenta existente al intentar crearla otra vez.
      }
      await SupabaseDatabase.client
          .from(SupabaseTables.perfiles)
          .update({'nombre': nombre.trim(), 'rol': tipo.rol})
          .eq('user_id', usuario.id)
          .select('user_id')
          .single(); // El dueño asigna el rol mediante las políticas actuales, sin iniciar sesión como el nuevo usuario.
    } finally {
      await registro.dispose();
    } // Libera el cliente temporal y conserva la sesión del dueño.
  } // Finaliza la creación del perfil.

  Future<void> editar(PerfilGestion perfil, String nombre) async {
    // Modifica únicamente datos admitidos por el esquema existente.
    await _exigirDueno(); // Mantiene el mismo permiso que la política de actualización.
    if (nombre.trim().isEmpty) {
      throw ArgumentError(
        'Ingresa el nombre del perfil.',
      ); // Impide nombres vacíos.
    }
    await SupabaseDatabase.client
        .from(SupabaseTables.perfiles)
        .update({'nombre': nombre.trim()})
        .eq('user_id', perfil.id)
        .eq('rol', perfil.tipo.rol)
        .select('user_id')
        .single(); // Comprueba que el perfil siga perteneciendo a su sección.
  } // Finaliza la edición.

  Future<void> eliminar(PerfilGestion perfil) async {
    // Retira únicamente el perfil elegido, sin borrar ventas ni clientes.
    final actual =
        await obtenerActual(); // Conserva la identidad del solicitante.
    await _exigirDueno(); // Exige autorización también antes de llamar al servidor.
    if (actual?.id == perfil.id) {
      throw StateError(
        'No puedes eliminar tu propio perfil.',
      ); // Evita dejar la sesión actual sin acceso.
    }
    await SupabaseDatabase.client.rpc(
      'eliminar_perfil_administrado',
      params: {'p_user_id': perfil.id, 'p_rol': perfil.tipo.rol},
    ); // El servidor vuelve a comprobar permisos y protege al último dueño.
  } // Finaliza la eliminación solicitada para perfiles.
} // Finaliza el acceso a los perfiles.
