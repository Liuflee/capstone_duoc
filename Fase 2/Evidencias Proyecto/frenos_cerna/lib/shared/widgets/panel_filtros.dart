// Importa los controles visuales de Flutter.
import 'package:flutter/material.dart';

// Comparte el espacio reservado al desplazamiento para alinear controles y tabla.
const double margenDesplazamientoTabla = 14;

// Normaliza un texto convirtiéndolo a minúsculas y quitando los acentos.
// Permite comparar búsquedas y valores sin importar tildes ni mayúsculas.
String normalizarFiltro(String texto) {
  return texto
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');
} // Finaliza la normalización compartida por todas las páginas.

// Buscador reutilizable con fondo gris, lupa y botón para limpiar el texto.
// Reemplaza al antiguo BuscadorTabla y puede usarse dentro o fuera de una tabla.
class CampoBusqueda extends StatelessWidget {
  // Utiliza el controlador administrado y liberado por la página.
  final TextEditingController controlador;
  // Notifica el texto para que la página o el panel filtren los datos.
  final ValueChanged<String> alCambiar;
  // Permite personalizar la indicación según la página utilizada.
  final String textoAyuda;

  // Configura los datos del buscador desde quien lo utiliza.
  const CampoBusqueda({
    super.key, // Conserva la identidad del widget dentro de Flutter.
    required this.controlador, // Controlador del texto de búsqueda.
    required this.alCambiar, // Acción ejecutada al escribir.
    this.textoAyuda = 'BUSCAR', // Texto predeterminado del buscador.
  });

  @override // Implementa la construcción visual del widget.
  Widget build(BuildContext context) {
    return Container(
      height: 48, // Comparte la altura con los filtros del panel.
      color: Colors.grey[300], // Reproduce el fondo gris de la aplicación.
      padding: const EdgeInsets.only(
        left: 10,
      ), // Separa el texto del borde izquierdo.
      child: Row(
        children: [
          // Distribuye el campo, la lupa y la limpieza horizontalmente.
          Expanded(
            child: TextField(
              controller:
                  controlador, // Muestra el texto administrado por la página.
              onChanged: alCambiar, // Permite filtrar mientras se escribe.
              decoration: InputDecoration(
                hintText: textoAyuda, // Describe qué datos se pueden buscar.
                border: InputBorder.none, // Conserva el diseño sin borde.
              ), // Finaliza la decoración del campo.
            ), // Finaliza el campo editable.
          ), // Asigna al texto el espacio restante.
          const Icon(
            Icons.search,
            color: Colors.black,
          ), // Conserva la lupa negra.
          // Muestra la limpieza solamente cuando existe un texto escrito.
          ListenableBuilder(
            listenable: controlador, // Se reconstruye al cambiar el texto.
            builder: (context, _) => controlador.text.isEmpty
                ? const SizedBox.shrink() // No ocupa espacio sin texto.
                : IconButton(
                    tooltip: 'Limpiar búsqueda', // Describe la acción.
                    onPressed: () {
                      controlador.clear(); // Borra el texto visible.
                      alCambiar(''); // Notifica que la búsqueda quedó vacía.
                    }, // Ejecuta la limpieza de un solo toque.
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black,
                    ), // Muestra la cruz de limpieza.
                  ), // Finaliza el botón de limpieza.
          ), // Finaliza la zona que reacciona al texto.
        ], // Finaliza los elementos horizontales.
      ), // Finaliza la fila del buscador.
    ); // Finaliza el fondo del buscador.
  } // Finaliza la construcción visual.
} // Finaliza el widget reutilizable.

// Describe una categoría de filtrado y cómo obtener su valor en cada dato.
// La página define la categoría una sola vez y el panel calcula sus opciones.
class CategoriaFiltro<T> {
  // Identificador único dentro del panel.
  final String id;
  // Nombre visible del filtro en su chip, por ejemplo: ESTADO.
  final String etiqueta;
  // Extrae el valor de la categoría para un dato concreto.
  final String Function(T dato) valor;
  // Permite mostrar otro texto para valores técnicos o poco legibles.
  final Map<String, String>? etiquetas;
  final bool
  seleccionUnica; // Permite restringir una categoría a una sola opción.
  final List<String> opcionesFijas; // Mantiene opciones disponibles aunque todavía no tengan registros.

  // Define cada categoría desde la página que conoce sus datos.
  const CategoriaFiltro({
    required this.id, // Identifica la selección de esta categoría.
    required this.etiqueta, // Describe la categoría para el usuario.
    required this.valor, // Calcula el valor de cada dato.
    this.seleccionUnica =
        false, // Conserva la selección múltiple en los demás filtros.
    this.opcionesFijas = const [], // Por defecto conserva las opciones calculadas desde los datos.
    this.etiquetas, // Opcional: traduce valores técnicos a texto visible.
  }); // Finaliza el constructor de la categoría.
} // Finaliza el modelo de una categoría.

// Opción calculada directamente desde los datos de la página.
class _OpcionFiltro {
  // Valor normalizado que se compara al filtrar.
  final String valor;
  // Texto visible en el menú de la categoría.
  final String texto;
  // Cantidad de datos que tienen este valor; ayuda a decidir rápidamente.
  final int cantidad;

  // Construye cada opción a partir del conteo de los datos.
  _OpcionFiltro({
    required this.valor,
    required this.texto,
    required this.cantidad,
  }); // Finaliza la opción calculada.
} // Finaliza el modelo de una opción calculada.

// Panel de filtros inteligente y reutilizable.
// Combina un buscador general con categorías de selección múltiple cuyas
// opciones y cantidades se calculan solas desde los datos recibidos.
// La página entrega los datos y construye su contenido con los filtrados.
class PanelFiltros<T> extends StatefulWidget {
  // Datos completos recibidos desde la página (Supabase o locales).
  final List<T> datos;
  // Campos de texto que revisa el buscador general de una sola vez.
  final List<String Function(T dato)> camposBusqueda;
  // Categorías configuradas por la página, por ejemplo: estado y categoría.
  final List<CategoriaFiltro<T>> categorias;
  // Indica qué se puede buscar en el campo de texto.
  final String textoAyuda;
  // Construye el contenido de la página con los datos que pasan los filtros.
  final Widget Function(List<T> filtrados) child;

  // Configura el panel sin acoplarlo a ninguna tabla concreta.
  const PanelFiltros({
    super.key, // Conserva la identidad del widget dentro de Flutter.
    required this.datos, // Datos completos de la página.
    required this.camposBusqueda, // Campos que revisa el buscador.
    this.categorias =
        const [], // Las páginas sin categorías usan solo búsqueda.
    this.textoAyuda = 'BUSCAR', // Indicación predeterminada del buscador.
    required this.child, // Contenido que recibe los datos filtrados.
  });

  @override // Conserva el texto y las selecciones mientras se usa el panel.
  State<PanelFiltros<T>> createState() => _PanelFiltrosState<T>();
} // Finaliza la configuración pública del panel.

// Mantiene el estado de búsqueda y de selección múltiple por categoría.
class _PanelFiltrosState<T> extends State<PanelFiltros<T>> {
  // Conserva el texto del buscador general del panel.
  final TextEditingController _busqueda = TextEditingController();
  // Selección múltiple por categoría: identificador -> valores elegidos.
  final Map<String, Set<String>> _selecciones = {};

  @override // Libera el controlador cuando se elimina el panel.
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  } // Evita conservar recursos de un panel cerrado.

  // Calcula las opciones de una categoría directamente desde los datos.
  // Cada opción incluye su cantidad para mostrar cuántos datos coincide.
  List<_OpcionFiltro> _opcionesDe(CategoriaFiltro<T> categoria) {
    final conteos = <String, int>{}; // Cuenta los datos por valor.
    final textos = <String, String>{}; // Recuerda el texto visible original.
    for (final opcion in categoria.opcionesFijas) {
      final clave = normalizarFiltro(
        opcion,
      ); // Usa la misma comparación que las filas.
      conteos[clave] = 0; // Muestra estados sin ventas con su conteo real.
      textos[clave] =
          categoria.etiquetas?[opcion] ??
          opcion; // Conserva la etiqueta configurada.
    }
    for (final dato in widget.datos) {
      final valor = categoria.valor(dato);
      if (valor.trim().isEmpty) {
        continue; // Ignora datos sin valor de categoría.
      } // Descarta valores vacíos antes de calcular las opciones.
      final clave = normalizarFiltro(
        valor,
      ); // Compara sin tildes ni mayúsculas.
      conteos[clave] = (conteos[clave] ?? 0) + 1; // Suma una coincidencia más.
      // Muestra la traducción personalizada cuando la página la define.
      textos[clave] = categoria.etiquetas?[valor] ?? valor;
    } // Finaliza el conteo de los datos.
    final opciones = [
      for (final entrada in conteos.entries)
        _OpcionFiltro(
          valor: entrada.key,
          texto: textos[entrada.key]!,
          cantidad: entrada.value,
        ),
    ]; // Convierte el conteo en opciones ordenadas.
    // Ordena por cantidad y luego por texto para una lectura rápida.
    opciones.sort(
      (a, b) => b.cantidad != a.cantidad
          ? b.cantidad.compareTo(a.cantidad)
          : a.texto.toLowerCase().compareTo(b.texto.toLowerCase()),
    ); // Finaliza el orden de las opciones.
    return opciones; // Entrega las opciones calculadas.
  } // Finaliza el cálculo de opciones.

  // Entrega solamente los valores elegidos que todavía existen en los datos.
  Set<String> _seleccionValida(CategoriaFiltro<T> categoria) {
    final elegidos = _selecciones[categoria.id] ?? const <String>{};
    if (categoria.seleccionUnica) {
      final opciones = _opcionesDe(
        categoria,
      ); // Incluye los estados aunque tengan cero registros.
      final validos = opciones.where(
        (opcion) => elegidos.contains(opcion.valor),
      ); // Conserva una única elección válida.
      if (validos.isNotEmpty) {
        return {validos.first.valor}; // Nunca combina ambos estados.
      }
      if (categoria.opcionesFijas.isNotEmpty) {
        return {
          normalizarFiltro(categoria.opcionesFijas.first),
        }; // Usa ventas cerradas al iniciar o limpiar.
      }
      return opciones.isEmpty
          ? <String>{}
          : {
              opciones.first.valor,
            }; // Mantiene una selección si hay opciones disponibles.
    }
    if (elegidos.isEmpty) return elegidos; // Una categoría vacía no filtra.
    final disponibles = _opcionesDe(categoria)
        .map((opcion) => opcion.valor)
        .toSet();
    return elegidos.intersection(
      disponibles,
    ); // Descarta valores que desaparecieron.
  } // Finaliza la revisión de la selección.

  // Aplica el buscador general y todas las categorías a la vez.
  // Las categorías se combinan con Y y las opciones de una misma categoría con O.
  List<T> get _filtrados {
    final consulta = normalizarFiltro(
      _busqueda.text.trim(),
    ); // Normaliza el texto buscado.
    return widget.datos.where((dato) {
      // Revisa el texto en todos los campos indicados por la página.
      if (consulta.isNotEmpty &&
          !widget.camposBusqueda.any(
            (campo) => normalizarFiltro(campo(dato)).contains(consulta),
          )) {
        return false; // Excluye los datos sin coincidencia de texto.
      } // Finaliza la comprobación del buscador.
      // Revisa cada categoría con opciones seleccionadas.
      for (final categoria in widget.categorias) {
        final elegidos = _seleccionValida(categoria);
        if (elegidos.isEmpty) continue; // Sin selección no restringe nada.
        if (!elegidos.contains(normalizarFiltro(categoria.valor(dato)))) {
          return false; // Excluye los datos de otras categorías.
        } // Finaliza la comprobación individual.
      } // Finaliza el recorrido de categorías.
      return true; // El dato supera todos los filtros del panel.
    }).toList(); // Entrega solamente los datos filtrados.
  } // Finaliza el filtrado combinado.

  // Detecta si existe algún filtro activo para ofrecer la limpieza.
  bool get _hayFiltroActivo =>
      _busqueda.text.trim().isNotEmpty ||
      _selecciones.values.any((valores) => valores.isNotEmpty);

  // Restablece el buscador y todas las categorías de una sola vez.
  void _limpiarTodo() {
    setState(() {
      _busqueda.clear(); // Borra el texto del buscador.
      _selecciones.clear(); // Vacía todas las categorías.
    }); // Actualiza el contenido con todos los datos.
  } // Finaliza la limpieza general.

  @override // Implementa la construcción visual del panel.
  Widget build(BuildContext context) {
    // Comprueba que los identificadores de categoría no se repitan.
    assert(
      widget.categorias.map((categoria) => categoria.id).toSet().length ==
          widget.categorias.length,
    ); // Exige identificadores únicos por panel.

    // Oculta las categorías con menos de dos opciones: no aportan decisiones.
    final categoriasVisibles = [
      for (final categoria in widget.categorias)
        if (_opcionesDe(categoria).length > 1) categoria,
    ]; // Finaliza las categorías que sí se muestran.

    final filtrados = _filtrados; // Calcula una sola vez los datos filtrados.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primera fila: buscador general, contador de resultados y limpieza.

        // Primera fila: buscador ocupando todo el ancho disponible.
        Padding(
          padding: const EdgeInsets.only(
            right: margenDesplazamientoTabla,
          ), // Iguala el borde derecho visible de la tabla.
          child: CampoBusqueda(
            controlador: _busqueda,
            textoAyuda: widget.textoAyuda,
            alCambiar: (_) => setState(() {}),
          ), // Conserva el diseño y la búsqueda del panel.
        ),

        const SizedBox(height: 12),

        // Segunda fila: filtros a la izquierda y resultados a la derecha.
        Padding(
          padding: const EdgeInsets.only(
            right: margenDesplazamientoTabla,
          ), // Alinea filtros y contador con los extremos de la tabla.
          child: LayoutBuilder(
            builder: (context, limites) {
              final chips = Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final categoria in categoriasVisibles)
                    _ChipCategoria<T>(
                      categoria: categoria,
                      opciones: _opcionesDe(categoria),
                      elegidos: _seleccionValida(categoria),
                      alCambiar: (nuevos) =>
                          setState(() => _selecciones[categoria.id] = nuevos),
                    ),
                ],
              ); // Las fichas se acomodan solas en pantallas angostas.

              final contador = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${filtrados.length} DE ${widget.datos.length}',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),

                  if (_hayFiltroActivo) ...[
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: _limpiarTodo,
                      icon: const Icon(
                        Icons.filter_alt_off,
                        size: 18,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'LIMPIAR',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ],
              ); // Mantiene el contador y la limpieza juntos.

              // En pantallas angostas el contador baja debajo de las fichas:
              // así ninguna ficha queda estrangulada ni desborda.
              if (limites.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [chips, const SizedBox(height: 10), contador],
                );
              } // Finaliza la distribución apilada.

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Los chips ocupan el espacio disponible a la izquierda.
                  Expanded(child: chips),

                  const SizedBox(width: 12),

                  // Contador y limpieza permanecen al extremo derecho.
                  contador,
                ],
              ); // Finaliza la distribución de escritorio.
            },
          ), // Conserva la distribución adaptable de filtros y contador.
        ), // Aplica el margen solo a los controles.

        const SizedBox(height: 20),
        // Separa los filtros del contenido.

        // Contenido de la página construido con los datos ya filtrados.
        Expanded(
          child: widget.child(
            filtrados,
          ), // Entrega los datos que superan todos los filtros.
        ), // Ocupa el espacio restante del panel.
      ], // Finaliza las secciones del panel.
    ); // Finaliza la columna del panel.
  } // Finaliza la construcción visual.
} // Finaliza el widget del panel.

// Chip reutilizable que representa una categoría con selección múltiple.
// Al pulsarlo despliega sus opciones calculadas con cantidades y un reinicio.
class _ChipCategoria<T> extends StatefulWidget {
  // Categoría que describe el chip en su menú.
  final CategoriaFiltro<T> categoria;
  // Opciones calculadas desde los datos, ordenadas por cantidad.
  final List<_OpcionFiltro> opciones;
  // Valores elegidos (normalizados) que se reflejan con casillas marcadas.
  final Set<String> elegidos;
  // Entrega la nueva selección de la categoría al panel.
  final ValueChanged<Set<String>> alCambiar;

  // Configura el chip con la información ya calculada por el panel.
  const _ChipCategoria({
    super.key,
    required this.categoria,
    required this.opciones,
    required this.elegidos,
    required this.alCambiar,
  });

  @override // Conserva el control del menú entre reconstrucciones.
  State<_ChipCategoria<T>> createState() => _ChipCategoriaState<T>();
} // Finaliza la configuración del chip.

// Mantiene el menú abierto mientras la persona elige varias opciones.
class _ChipCategoriaState<T> extends State<_ChipCategoria<T>> {
  // Controla explícitamente la apertura y el cierre del menú superpuesto.
  final MenuController _controladorMenu = MenuController();

  @override // Alterna el menú y repinta la flecha del chip.
  Widget build(BuildContext context) {
    final activo =
        widget.elegidos.isNotEmpty; // Detecta la categoría seleccionada.
    // Color del texto según el fondo del chip.
    final Color colorTexto = activo ? Colors.white : Colors.black;

    return MenuAnchor(
      controller: _controladorMenu, // Conserva el control del menú abierto.
      crossAxisUnconstrained: false, // Ajusta el ancho del menú al chip.
      consumeOutsideTap: true, // Cierra al pulsar fuera sin tocar la tabla.
      onOpen: () => setState(() {}), // Actualiza la flecha al desplegar.
      onClose: () => setState(() {}), // Actualiza la flecha al contraer.
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.zero,
        ), // Elimina márgenes internos del desplegable.
        alignment: Alignment.bottomLeft, // Alinea el menú debajo del chip.
        backgroundColor: WidgetStatePropertyAll(
          Colors.grey[300],
        ), // Conserva el fondo gris de la aplicación.
        fixedSize: const WidgetStatePropertyAll(
          Size(280, double.infinity),
        ), // Ancho constante y alto libre para desplazar las opciones.
        maximumSize: const WidgetStatePropertyAll(
          Size(280, 320),
        ), // Limita la altura cuando existen muchas opciones.
      ), // Finaliza el diseño del desplegable.
      menuChildren: [
        // Mantiene el menú abierto para elegir varias opciones seguidas.
        for (final opcion
            in widget.opciones) // Recorre las opciones calculadas.
          MenuItemButton(
            closeOnActivate: false, // No cierra el menú al marcar una casilla.
            onPressed: () {
              if (widget.categoria.seleccionUnica) {
                widget.alCambiar({opcion.valor}); // Sustituye la selección anterior y no desmarca la única elegida.
                return; // Evita aplicar la alternancia múltiple.
              }
              // Alterna el valor: lo agrega si falta y lo quita si existe.
              final nuevos = Set<String>.from(widget.elegidos);
              if (!nuevos.remove(opcion.valor)) {
                nuevos.add(opcion.valor);
              } // Finaliza la alternancia del valor.
              widget.alCambiar(nuevos); // Entrega la selección actualizada.
            }, // Ejecuta la alternancia sin cerrar el menú.
            child: Row(
              children: [
                Icon(
                  widget.elegidos.contains(opcion.valor)
                      ? (widget.categoria.seleccionUnica
                            ? Icons.radio_button_checked
                            : Icons.check_box)
                      : (widget.categoria.seleccionUnica
                            ? Icons.radio_button_unchecked
                            : Icons.check_box_outline_blank), // Marca las opciones elegidas.
                  size: 20,
                  color: Colors.black,
                ), // Refleja la casilla de la opción.
                const SizedBox(width: 8), // Separa la casilla del texto.
                Expanded(
                  child: Text(
                    opcion.texto
                        .toUpperCase(), // Muestra la opción en mayúsculas.
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                  ), // Finaliza el texto de la opción.
                ), // Ajusta textos largos al ancho del menú.
                Text(
                  '${opcion.cantidad}', // Indica cuántos datos tiene esta opción.
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13,
                    color: Colors.grey[700],
                  ), // Mantiene la fuente de la aplicación.
                ), // Finaliza la cantidad de la opción.
              ], // Finaliza los elementos de la opción.
            ), // Finaliza la opción seleccionable.
          ), // Finaliza cada opción del menú.
        // Solo los filtros múltiples permiten mostrar todas las opciones juntas.
        if (!widget.categoria.seleccionUnica)
          MenuItemButton(
            onPressed: () =>
                widget.alCambiar(<String>{}), // Vacía esta categoría.
            child: Row(
              children: [
                const Icon(
                  Icons.restart_alt,
                  size: 20,
                  color: Colors.black,
                ), // Identifica el reinicio de la categoría.
                const SizedBox(width: 8), // Separa el icono del texto.
                const Expanded(
                  child: Text(
                    'TODAS',
                    style: TextStyle(fontFamily: 'Courier', fontSize: 14),
                  ), // Describe el reinicio completo.
                ), // Ajusta el texto al ancho del menú.
              ], // Finaliza los elementos del reinicio.
            ), // Finaliza el contenido del reinicio.
          ), // Finaliza la opción de reinicio.
      ], // Finaliza las opciones del menú.

      builder: (context, controlador, child) => InkWell(
        onTap: () {
          // Permite alternar la apertura del menú del chip.
          if (controlador.isOpen) {
            controlador.close(); // Contrae el menú al volver a pulsar.
          } else {
            controlador.open(); // Despliega las opciones bajo el chip.
          } // Finaliza la alternancia del menú.
        }, // Finaliza la acción del chip.
        child: Tooltip(
          message:
              widget.categoria.etiqueta, // Describe el chip al pasar el cursor.
          child: Container(
            height: 40, // Comparte la altura con el buscador del panel.
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ), // Separa el texto de los bordes.
            decoration: BoxDecoration(
              color: activo
                  ? const Color(0xFFB74545)
                  : Colors.grey[300], // Rojo activo y gris inactivo.
              borderRadius: BorderRadius.circular(
                8,
              ), // Suaviza los bordes del chip.
            ), // Finaliza el fondo del chip.
            child: Row(
              mainAxisSize: MainAxisSize.min, // El chip ocupa solo su texto.
              children: [
                Text(
                  activo
                      ? '${widget.categoria.etiqueta.toUpperCase()} (${widget.elegidos.length})' // Muestra cuántos valores están elegidos.
                      : widget.categoria.etiqueta
                            .toUpperCase(), // Muestra la categoría completa.
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13,
                    color: colorTexto,
                  ), // Mantiene la fuente de la aplicación.
                ), // Finaliza el texto visible del chip.
                Icon(
                  controlador.isOpen
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: colorTexto, // Comparte el color del texto del chip.
                ), // Indica si se puede contraer o desplegar.
              ], // Finaliza los elementos del chip.
            ), // Finaliza el fondo del chip.
          ), // Finaliza el contenido pulsable del chip.
        ), // Finaliza la ayuda accesible del chip.
      ), // Finaliza el botón que alterna el menú.
    ); // Finaliza el menú superpuesto del chip.
  } // Finaliza la construcción visual.
} // Finaliza el widget del chip.
