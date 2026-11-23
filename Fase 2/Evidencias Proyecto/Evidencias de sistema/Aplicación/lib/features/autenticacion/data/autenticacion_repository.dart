import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RolUsuario {
  administrador,
  empleado;

  static RolUsuario desdeBaseDeDatos(String valor) {
    return switch (valor) {
      'administrador' => RolUsuario.administrador,
      'empleado' => RolUsuario.empleado,
      _ => throw FormatException('Rol de usuario no reconocido: $valor'),
    };
  }

  String get etiqueta => switch (this) {
    RolUsuario.administrador => 'Administrador',
    RolUsuario.empleado => 'Empleado',
  };
}

class PerfilUsuario {
  final String id;
  final String nombre;
  final RolUsuario rol;

  const PerfilUsuario({
    required this.id,
    required this.nombre,
    required this.rol,
  });

  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    return PerfilUsuario(
      id: json['user_id'] as String,
      nombre: json['nombre'] as String,
      rol: RolUsuario.desdeBaseDeDatos(json['rol'] as String),
    );
  }
}

class AutenticacionRepository {
  const AutenticacionRepository();

  SupabaseClient get _client => SupabaseDatabase.client;

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    await _client.auth.signInWithPassword(
      email: correo.trim(),
      password: contrasena,
    );
  }

  Future<bool> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final respuesta = await _client.auth.signUp(
      email: correo.trim(),
      password: contrasena,
      data: {'nombre': nombre.trim()},
    );
    return respuesta.session != null;
  }

  Future<PerfilUsuario> obtenerPerfil(String userId) async {
    final resultado = await _client
        .from(SupabaseTables.perfiles)
        .select('user_id, nombre, rol')
        .eq('user_id', userId)
        .single();

    return PerfilUsuario.fromJson(Map<String, dynamic>.from(resultado));
  }
}
