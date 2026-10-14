// importaciones
import 'package:flutter/material.dart';
import 'package:frenos_cerna/shared/widgets/barra_superior.dart';
import 'package:frenos_cerna/shared/widgets/menu_lateral.dart';

// creamos la clase PaginaInicio que extiende StatelessWidget

class PaginaInicio extends StatelessWidget {

  // constructor de la clase PaginaInicio

  const PaginaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.grey[200], // color de fondo de la página

      // cuerpo de la pagina

      body: LayoutBuilder(

        builder:((context, constraints){

          final ancho = constraints.maxWidth;
          final alto = constraints.maxHeight;

          return Column( // le da la orrientacion a los elementos
            children: [

              // barra superior

              SizedBox(
                width: ancho,
                height: alto* 0.10,
                child: const BarraSuperior( // se llama el widget de barra superior
                  tituloPagina: 'Página Principal',
                ),
              ),

              // ZONA DE WINDGETS

              Expanded( // ocupa el espacio restante
                child: Row( // le da la orientacion a los elementos
                  children: [

                    // barra lateral
                    SizedBox(
                      width: ancho * 0.12, 
                      child: const MenuLateral(activo: 'Página Principal',)
                    ),
                    // contenido principal
                    Expanded( // asigna el resto del ancho
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text('CONTENIDO PRINCIPAL')
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          );
        }) 
      )
    );
  }

}