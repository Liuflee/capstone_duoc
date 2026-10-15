import 'package:flutter/material.dart';

class CampoFormulario extends StatefulWidget {
  final TextEditingController controller;
  final String etiqueta;
  final String? hint;
  final IconData icono;
  final TextInputType? tipoTeclado;
  final TextInputAction? accion;
  final String? Function(String?)? validador;
  final bool esContrasena;

  const CampoFormulario({
    super.key,
    required this.controller,
    required this.etiqueta,
    required this.icono,
    this.hint,
    this.tipoTeclado,
    this.accion,
    this.validador,
    this.esContrasena = false,
  });

  @override
  State<CampoFormulario> createState() => _CampoFormularioState();
}

class _CampoFormularioState extends State<CampoFormulario> {
  bool _ocultarContrasena = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.tipoTeclado,
      textInputAction: widget.accion,
      obscureText: widget.esContrasena && _ocultarContrasena,
      validator: widget.validador,
      autocorrect: !widget.esContrasena,
      enableSuggestions: !widget.esContrasena,
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        hintText: widget.hint,
        prefixIcon: Icon(widget.icono),
        suffixIcon: widget.esContrasena
            ? IconButton(
                tooltip: _ocultarContrasena
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () {
                  setState(() => _ocultarContrasena = !_ocultarContrasena);
                },
                icon: Icon(
                  _ocultarContrasena
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
          // Borde normal
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),

          // Borde cuando el campo está seleccionado
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 183, 58, 58),
              width: 2,
            ),
          ),
        filled: true,
        fillColor: Colors.white,
        floatingLabelStyle: const TextStyle(color: Color.fromARGB(255, 183, 58, 58)),
      ),
    );
  }
}
