import 'package:flutter/material.dart'; // Construye las secciones de perfiles.
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart'; // Reutiliza el marco compartido.
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart'; // Mantiene las cartas de acción del proyecto.
import 'package:frenos_cerna/features/perfil/data/perfiles_repository.dart'; // Reutiliza los roles y perfiles existentes.
import 'package:frenos_cerna/features/perfil/pagina_gestion_perfil.dart'; // Abre las vistas de consulta y administración.

class PaginaPerfil extends StatelessWidget {
  // Presenta los accesos a los perfiles sin modificar el login.
  final PerfilesRepository
  repositorio; // Permite comprobar la navegación con una fuente controlada.
  const PaginaPerfil({
    super.key,
    this.repositorio = const PerfilesRepository(),
  }); // Conserva el acceso existente a Perfil.
  void _abrir(BuildContext context, TipoPerfil tipo, ModoPerfil modo) {
    // Separa las rutas de ver, crear, editar y eliminar.
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          name:
              '/profiles/${tipo == TipoPerfil.dueno ? 'owner' : 'mechanic'}/${modo.ruta}',
        ),
        builder: (context) => modo == ModoPerfil.crear
            ? PaginaGestionPerfil(
                tipo: tipo,
                modo: modo,
                repositorio: repositorio,
              )
            : PaginaSeleccionarPerfil(
                tipo: tipo,
                modo: modo,
                repositorio: repositorio,
              ),
      ),
    ); // Selecciona una persona antes de consultar o modificar su perfil.
  } // Finaliza la navegación de cada sección.

  Widget _seccion(BuildContext context, TipoPerfil tipo) => Container(
    // Distingue visualmente dueño y mecánico.
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5),
      border: Border.all(color: const Color(0xFFBDBDBD)),
      borderRadius: BorderRadius.circular(12),
    ), // Conserva la paleta gris del proyecto.
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Organiza los accesos de la sección.
        Text(
          tipo.nombre,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ), // Identifica el tipo de perfil que se administra.
        const SizedBox(height: 20), // Separa el título de las tres acciones.
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Mantiene las acciones en una fila y las adapta al ancho disponible.
            for (final modo in [
              ModoPerfil.crear,
              ModoPerfil.editar,
              ModoPerfil.eliminar,
            ])
              CartaNavegacion(
                ancho: 240,
                alto: 140, // Duplica el alto de las tarjetas de administración de perfiles.
                color: const Color(0xFFBDBDBD),
                icono: modo == ModoPerfil.crear
                    ? Icons.person_add_alt_1
                    : modo == ModoPerfil.editar
                    ? Icons.edit_outlined
                    : Icons.person_remove_outlined,
                texto:
                    (modo == ModoPerfil.crear
                        ? 'CREAR PERFIL '
                        : modo == ModoPerfil.editar
                        ? 'EDITAR PERFIL '
                        : 'ELIMINAR PERFIL ') +
                    tipo.nombre,
                alPresionar: () => _abrir(context, tipo, modo),
              ), // Conserva el tamaño y las rutas de administración existentes.
          ],
        ), // Finaliza los accesos de la sección.
      ],
    ), // Finaliza la distribución.
  ); // Finaliza el bloque de un tipo de perfil.
  @override // Construye la página principal de perfiles.
  Widget build(BuildContext context) => EstructuraPagina(
    titulo: 'Perfiles',
    activo: 'Perfil',
    child: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Conserva ambas secciones dentro del marco de trabajo.
              Align(
                alignment: Alignment.centerLeft,
                child: CartaNavegacion.accion(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/profiles/me'),
                      builder: (context) => PaginaGestionPerfil(
                        tipo: TipoPerfil.mecanico,
                        modo: ModoPerfil.ver,
                        miPerfil: true,
                        repositorio: repositorio,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text('VER MI PERFIL'),
                ),
              ), // Abre el perfil de la sesión actual y nunca el de otra persona.
              const SizedBox(
                height: 24,
              ), // Separa el perfil personal de la administración.
              _seccion(
                context,
                TipoPerfil.dueno,
              ), // Presenta la primera fila de accesos.
              const SizedBox(height: 24), // Distingue las dos secciones.
              _seccion(
                context,
                TipoPerfil.mecanico,
              ), // Presenta la segunda fila de accesos.
            ],
          ),
        ),
      ),
    ),
  ); // Finaliza la página desplazable.
} // Finaliza la página de perfiles.
