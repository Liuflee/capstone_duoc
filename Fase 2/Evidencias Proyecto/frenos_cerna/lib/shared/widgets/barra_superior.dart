// importaciones

import 'package:flutter/material.dart';

// se crea la clase  barra superior

class BarraSuperior extends StatelessWidget  {

  final String tituloPagina; // recuperamos el nombre de la pagina donde esta siendo usada la barra superior
  final String nombreUsuario; // posiblecambio de logica

  // se crea el contructor de la clase
  const BarraSuperior({
    super.key,
    required this.tituloPagina,
    this.nombreUsuario = 'Leonardo'
    });

  @override
  Widget build(BuildContext context) {
    
    return Container(
      // estilos del contenedor
      width: double.infinity, // le asigna todo el ancho del contenedor padre
      padding: const EdgeInsets.symmetric(horizontal: 24), // hace que los elementos tengan un padding horizontal
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.red,
          width: 2,
        )
      ),


      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // esto centra el contenido

        children: [

          // logo y nombre empresa
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(Icons.car_repair,size: 40,),
                const SizedBox(width: 12,),
                const Flexible(
                  child: Text(
                    'Frenos Cerna',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                    ),
                    ),
                )
              ],
            ),
          ),

          // Titulo de la pagina
          Expanded(
            flex: 4,
            child: Center(
              child: Text(
                tituloPagina,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // usuario
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    nombreUsuario,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.settings_outlined, size: 30),
              ],
            ),
          ),
        ],
      ),
    );

  }
}