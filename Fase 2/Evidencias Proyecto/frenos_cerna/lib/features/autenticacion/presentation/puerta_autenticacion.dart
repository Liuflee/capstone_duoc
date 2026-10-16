// Importa las cartas que conservan las acciones de la página.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/autenticacion/data/autenticacion_repository.dart';
import 'package:frenos_cerna/features/autenticacion/presentation/pagina_autenticacion.dart';
import 'package:frenos_cerna/features/inicio/pagina_inicio.dart';

// Desactiva este interruptor antes de distribuir la aplicación.
const bool habilitarModoPrueba = true;

class PuertaAutenticacion extends StatefulWidget {
  const PuertaAutenticacion({super.key});

  @override
  State<PuertaAutenticacion> createState() => _PuertaAutenticacionState();
}

class _PuertaAutenticacionState extends State<PuertaAutenticacion> {
  late final StreamSubscription<AuthState> _suscripcionAutenticacion;
  Session? _sesion;
  bool _modoPrueba = false;

  @override
  void initState() {
    super.initState();
    if (!SupabaseDatabase.isConfigured) return;

    final autenticacion = SupabaseDatabase.client.auth;
    _sesion = autenticacion.currentSession;
    _suscripcionAutenticacion = autenticacion.onAuthStateChange.listen((
      estado,
    ) {
      if (!mounted) return;
      setState(() => _sesion = estado.session);
    });
  }

  @override
  void dispose() {
    if (SupabaseDatabase.isConfigured) {
      _suscripcionAutenticacion.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseDatabase.isConfigured) {
      if (_modoPrueba) return _paginaPrueba();
      return PaginaAutenticacion(
        onEntrarModoPrueba: habilitarModoPrueba
            ? () => setState(() => _modoPrueba = true)
            : null,
      );
    }

    if (_modoPrueba) return _paginaPrueba();

    final usuario = _sesion?.user;
    if (usuario == null) {
      return PaginaAutenticacion(
        onEntrarModoPrueba: habilitarModoPrueba
            ? () => setState(() => _modoPrueba = true)
            : null,
      );
    }
    return _CargarPerfil(userId: usuario.id);
  }

  Widget _paginaPrueba() {
    return PaginaInicio(
      perfilUsuario: const PerfilUsuario(
        id: 'modo-prueba',
        nombre: 'Modo de prueba',
        rol: RolUsuario.empleado,
      ),
      modoPrueba: true,
      onSalirModoPrueba: () => setState(() => _modoPrueba = false),
    );
  }
}

class _CargarPerfil extends StatefulWidget {
  final String userId;

  const _CargarPerfil({required this.userId});

  @override
  State<_CargarPerfil> createState() => _CargarPerfilState();
}

class _CargarPerfilState extends State<_CargarPerfil> {
  late Future<PerfilUsuario> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = const AutenticacionRepository().obtenerPerfil(widget.userId);
  }

  @override
  void didUpdateWidget(covariant _CargarPerfil oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _perfil = const AutenticacionRepository().obtenerPerfil(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PerfilUsuario>(
      future: _perfil,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorPerfil(
            mensaje: 'No se pudo cargar el perfil: ${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return PaginaInicio(perfilUsuario: snapshot.data);
      },
    );
  }
}

class _ErrorPerfil extends StatelessWidget {
  final String mensaje;

  const _ErrorPerfil({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(mensaje, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  CartaNavegacion.accion(
                    // Conserva las medidas y la función de la acción original.
                    tipoBoton: 'filled',

                    onPressed: () => SupabaseDatabase.client.auth.signOut(
                      scope: SignOutScope.local,
                    ),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
