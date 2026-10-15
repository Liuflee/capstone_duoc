import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/autenticacion/data/autenticacion_repository.dart';
import 'package:frenos_cerna/features/autenticacion/presentation/pagina_autenticacion.dart';
import 'package:frenos_cerna/features/inicio/pagina_inicio.dart';

class PuertaAutenticacion extends StatefulWidget {
  const PuertaAutenticacion({super.key});

  @override
  State<PuertaAutenticacion> createState() => _PuertaAutenticacionState();
}

class _PuertaAutenticacionState extends State<PuertaAutenticacion> {
  late final StreamSubscription<AuthState> _suscripcionAutenticacion;
  Session? _sesion;

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
      return const PaginaAutenticacion();
    }

    final usuario = _sesion?.user;
    if (usuario == null) return const PaginaAutenticacion();
    return _CargarPerfil(userId: usuario.id);
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
      backgroundColor: Colors.grey[200],
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
                  FilledButton(
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
