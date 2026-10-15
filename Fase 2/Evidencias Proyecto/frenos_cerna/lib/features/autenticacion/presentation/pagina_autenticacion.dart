import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/autenticacion/data/autenticacion_repository.dart';
import 'package:frenos_cerna/shared/widgets/campo_formulario.dart';

class PaginaAutenticacion extends StatefulWidget {
  final VoidCallback? onEntrarModoPrueba;

  const PaginaAutenticacion({super.key, this.onEntrarModoPrueba});

  @override
  State<PaginaAutenticacion> createState() => _PaginaAutenticacionState();
}

class _PaginaAutenticacionState extends State<PaginaAutenticacion> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmarContrasena = TextEditingController();
  final _repository = const AutenticacionRepository();

  bool _esRegistro = false;
  bool _procesando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmarContrasena.dispose();
    super.dispose();
  }

  String? _validarCorreo(String? valor) {
    final correo = valor?.trim() ?? '';
    if (correo.isEmpty || !correo.contains('@') || !correo.contains('.')) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validarContrasena(String? valor) {
    if ((valor ?? '').length < 6) {
      return 'Usa al menos 6 caracteres';
    }
    return null;
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!_formulario.currentState!.validate()) return;
    if (!SupabaseDatabase.isConfigured) {
      setState(() => _error = 'Configura Supabase para usar la autenticación.');
      return;
    }

    setState(() {
      _procesando = true;
      _error = null;
    });

    try {
      if (_esRegistro) {
        final sesionIniciada = await _repository.registrar(
          nombre: _nombre.text,
          correo: _correo.text,
          contrasena: _contrasena.text,
        );
        if (!mounted) return;
        if (sesionIniciada) {
          return;
        }
        setState(() {
          _esRegistro = false;
          _error = null;
        });
        _mostrarAviso(
          'Cuenta creada. Revisa tu correo para confirmar la dirección y luego inicia sesión.',
        );
      } else {
        await _repository.iniciarSesion(
          correo: _correo.text,
          contrasena: _contrasena.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo completar la solicitud: $error');
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _cambiarModo() {
    setState(() {
      _esRegistro = !_esRegistro;
      _error = null;
      _formulario.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_frenos_cerna.png',
                    width: anchoPantalla < 400 ? 92 : 112,
                    height: anchoPantalla < 400 ? 92 : 112,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Frenos Cerna',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _esRegistro
                        ? 'Crea tu cuenta de empleado'
                        : 'Ingresa a tu cuenta',
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formulario,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!SupabaseDatabase.isConfigured) ...[
                              const Text(
                                'La autenticación aún no está configurada. '
                                'Agrega las credenciales de Supabase para continuar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_esRegistro) ...[
                              CampoFormulario(
                                controller: _nombre,
                                etiqueta: 'Nombre',
                                icono: Icons.person_outline,
                                accion: TextInputAction.next,
                                validador: (valor) {
                                  if ((valor ?? '').trim().isEmpty) {
                                    return 'Ingresa tu nombre';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            CampoFormulario(
                              controller: _correo,
                              etiqueta: 'Correo electrónico',
                              icono: Icons.email_outlined,
                              tipoTeclado: TextInputType.emailAddress,
                              accion: TextInputAction.next,
                              validador: _validarCorreo,
                            ),
                            const SizedBox(height: 16),
                            CampoFormulario(
                              controller: _contrasena,
                              etiqueta: 'Contraseña',
                              icono: Icons.lock_outline,
                              accion: _esRegistro
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              esContrasena: true,
                              validador: _validarContrasena,
                            ),
                            if (_esRegistro) ...[
                              const SizedBox(height: 16),
                              CampoFormulario(
                                controller: _confirmarContrasena,
                                etiqueta: 'Confirmar contraseña',
                                icono: Icons.lock_outline,
                                accion: TextInputAction.done,
                                esContrasena: true,
                                validador: (valor) {
                                  if (valor != _contrasena.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed:
                                    _procesando ||
                                        !SupabaseDatabase.isConfigured
                                    ? null
                                    : _enviar,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red[800],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _procesando
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _esRegistro
                                            ? 'Crear cuenta'
                                            : 'Iniciar sesión',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _procesando ? null : _cambiarModo,
                              child: Text(
                                _esRegistro
                                    ? '¿Ya tienes cuenta? Inicia sesión'
                                    : '¿No tienes cuenta? Regístrate',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red[800]),
                              ),
                            ),
                            if (widget.onEntrarModoPrueba != null) ...[
                              const Divider(height: 28),
                              OutlinedButton.icon(
                                onPressed: _procesando
                                    ? null
                                    : widget.onEntrarModoPrueba,
                                icon: const Icon(Icons.science_outlined),
                                label: const Text('Entrar en modo de prueba'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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
