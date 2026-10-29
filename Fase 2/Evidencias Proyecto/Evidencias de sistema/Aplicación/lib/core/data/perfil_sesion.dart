import 'package:frenos_cerna/core/data/supabase_database.dart'; // Identifica la cuenta de la sesión activa.
import 'package:frenos_cerna/features/autenticacion/data/autenticacion_repository.dart'; // Reutiliza el perfil obtenido al iniciar sesión.

abstract final class PerfilSesion {
  static PerfilUsuario? _perfil; // Conserva el perfil solo en memoria.
  static String? _usuarioConsulta; // Evita compartir datos entre cuentas.
  static Future<PerfilUsuario?>?
  _consulta; // Comparte una consulta entre todas las barras.
  static String? get _usuarioActual => SupabaseDatabase.isConfigured
      ? SupabaseDatabase.client.auth.currentUser?.id
      : null; // Consulta la identidad autenticada.
  static PerfilUsuario? get actual {
    final id = _usuarioActual; // Comprueba la cuenta en cada acceso.
    if (_perfil?.id != id || id == null) {
      return null; // Nunca muestra el nombre de otra sesión.
    }
    return _perfil; // Entrega el nombre inmediatamente al navegar.
  }

  static void conservar(PerfilUsuario perfil) {
    if (perfil.id != _usuarioActual) {
      return; // Rechaza perfiles ajenos o de modo de prueba.
    }
    _perfil =
        perfil; // Aprovecha el perfil que ya cargó la puerta de autenticación.
  }

  static void limpiar() {
    _perfil = null; // Retira los datos de la sesión cerrada.
    _consulta = null; // Descarta la consulta compartida.
    _usuarioConsulta = null; // Retira la identidad anterior.
  }

  static Future<PerfilUsuario?> obtener() {
    final id = _usuarioActual; // Obtiene la cuenta vigente.
    if (id == null) {
      _perfil = null;
      _consulta = null;
      _usuarioConsulta = null; // Limpia los datos al salir de sesión.
      return Future.value(null);
    }
    if (actual != null) {
      return Future.value(actual); // Evita consultas y parpadeos al navegar.
    }
    if (_usuarioConsulta == id && _consulta != null) {
      return _consulta!; // Reutiliza una carga simultánea.
    }
    _usuarioConsulta = id; // Vincula la petición a su cuenta.
    final consulta = AutenticacionRepository()
        .obtenerPerfil(id)
        .then<PerfilUsuario?>((perfil) {
          conservar(
            perfil,
          ); // Guarda únicamente si sigue siendo la misma cuenta.
          return perfil.id == _usuarioActual
              ? perfil
              : null; // Descarta respuestas de una sesión anterior.
        });
    _consulta = consulta; // Comparte la petición en curso.
    consulta.then<void>(
      (_) {
        if (identical(_consulta, consulta)) _consulta = null;
      },
      onError: (Object error, StackTrace traza) {
        if (identical(_consulta, consulta)) _consulta = null;
      },
    ); // Permite reintentar una carga fallida.
    return consulta;
  }
}
