// Importa los controles visuales de Flutter.
import 'package:flutter/material.dart';
// Reutiliza el marco común de las páginas.
import 'package:frenos_cerna/shared/widgets/estructura_pagina.dart';

// Conserva las preferencias visuales únicamente durante la sesión actual.
class PreferenciasVisuales extends ChangeNotifier {
  static final instancia =
      PreferenciasVisuales._(); // Comparte los ajustes entre páginas.
  PreferenciasVisuales._(); // Evita crear ajustes independientes.
  double brillo = 1; // Usa el brillo original por defecto.
  double texto = 1; // Usa la escala de texto original por defecto.
  double saturacion = 1; // Usa los colores originales por defecto.
  void actualizar({
    double? nuevoBrillo,
    double? nuevoTexto,
    double? nuevaSaturacion,
  }) {
    brillo = nuevoBrillo ?? brillo;
    texto = nuevoTexto ?? texto;
    saturacion =
        nuevaSaturacion ?? saturacion; // Actualiza solo los valores indicados.
    notifyListeners(); // Aplica los cambios a la aplicación.
  } // Finaliza la actualización.

  List<double> get matriz {
    final inversa = 1 - saturacion; // Calcula la contribución del gris.
    final rojo = 0.2126 * inversa;
    final verde = 0.7152 * inversa;
    final azul = 0.0722 * inversa; // Usa la luminancia de cada canal.
    return [
      brillo * (rojo + saturacion),
      brillo * verde,
      brillo * azul,
      0,
      0,
      brillo * rojo,
      brillo * (verde + saturacion),
      brillo * azul,
      0,
      0,
      brillo * rojo,
      brillo * verde,
      brillo * (azul + saturacion),
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]; // Mantiene el canal de transparencia sin cambios.
  } // Finaliza la transformación de color.
} // Finaliza el estado compartido de preferencias.

// Presenta los tres ajustes de Opciones con la alineación del prototipo.
class PaginaOpciones extends StatelessWidget {
  const PaginaOpciones({super.key}); // Crea la página de opciones.
  @override // Construye los controles de preferencias.
  Widget build(BuildContext context) {
    final preferencias =
        PreferenciasVisuales.instancia; // Obtiene los valores actuales.
    return EstructuraPagina(
      titulo: 'Opciones',
      activo: 'Opciones',
      child: AnimatedBuilder(
        animation: preferencias, // Actualiza las posiciones de los controles al cambiar sus valores.
        builder: (context, child) => SingleChildScrollView(
          child: Align(
            alignment:
                Alignment.topCenter, // Alinea los ajustes en la parte superior.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .stretch, // Iguala el ancho de los ajustes.
                children: [
                  const SizedBox(
                    height: 24,
                  ), // Separa el contenido de la barra.
                  const Text(
                    'Brillo',
                    style: TextStyle(fontSize: 24),
                  ), // Conserva el primer ajuste de Figma.
                  Slider(
                    value: preferencias.brillo,
                    min: 0.65,
                    max: 1.15,
                    activeColor: const Color(0xFFBF2020),
                    onChanged: (valor) =>
                        preferencias.actualizar(nuevoBrillo: valor),
                  ), // Ajusta el brillo sin afectar al dispositivo.
                  const SizedBox(
                    height: 36,
                  ), // Mantiene la separación entre ajustes.
                  const Text(
                    'Tamaño de texto',
                    style: TextStyle(fontSize: 24),
                  ), // Conserva el segundo ajuste.
                  Slider(
                    value: preferencias.texto,
                    min: 0.8,
                    max: 1.3,
                    activeColor: const Color(0xFFBF2020),
                    onChanged: (valor) =>
                        preferencias.actualizar(nuevoTexto: valor),
                  ), // Ajusta el texto de la aplicación.
                  const SizedBox(
                    height: 36,
                  ), // Mantiene la separación entre ajustes.
                  const Text(
                    'Saturación de color',
                    style: TextStyle(fontSize: 24),
                  ), // Conserva el tercer ajuste.
                  Slider(
                    value: preferencias.saturacion,
                    min: 0,
                    max: 1.5,
                    activeColor: const Color(0xFFBF2020),
                    onChanged: (valor) =>
                        preferencias.actualizar(nuevaSaturacion: valor),
                  ), // Ajusta la intensidad de los colores.
                ], // Finaliza los ajustes.
              ),
            ), // Limita el ancho al diseño de escritorio.
          ),
        ), // Permite desplazar los ajustes en Android.
      ),
    ); // Finaliza la página.
  } // Finaliza la construcción.
} // Finaliza la página de opciones.
