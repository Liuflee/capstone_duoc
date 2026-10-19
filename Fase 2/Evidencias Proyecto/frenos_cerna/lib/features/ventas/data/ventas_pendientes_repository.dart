import 'dart:convert'; // Codifica los borradores locales sin cambiar tablas.
import 'dart:math'; // Genera identificadores locales independientes.

import 'package:shared_preferences/shared_preferences.dart'; // Conserva los borradores entre sesiones.
import 'package:supabase_flutter/supabase_flutter.dart'; // Identifica errores que la base rechazó explícitamente.
import 'package:frenos_cerna/core/data/supabase_database.dart'; // Confirma únicamente las ventas pagadas.
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart'; // Reutiliza el formato del detalle de venta.

class ArticuloVentaPendiente {
  // Conserva una línea de producto antes del pago.
  final String codigo, nombre, categoria; // Identifica y describe el producto.
  final double precio; // Conserva el precio mostrado al preparar la venta.
  final int cantidad,
      stock; // Conserva unidades seleccionadas y disponibilidad consultada.
  const ArticuloVentaPendiente({
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.cantidad,
    required this.stock,
  }); // Configura una línea inmutable.
  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'nombre': nombre,
        'categoria': categoria,
        'precio': precio,
        'cantidad': cantidad,
        'stock': stock,
      }; // Conserva los datos necesarios para editar.
  factory ArticuloVentaPendiente.fromJson(Map<String, dynamic> datos) =>
      ArticuloVentaPendiente(
        codigo: datos['codigo'] as String,
        nombre: datos['nombre'] as String,
        categoria: datos['categoria'] as String,
        precio: (datos['precio'] as num).toDouble(),
        cantidad: datos['cantidad'] as int,
        stock: datos['stock'] as int,
      ); // Recupera la línea local.
} // Finaliza la línea de venta.

class VentaPendiente {
  // Representa una venta que todavía no existe en Supabase.
  final String id,
      rutCliente,
      nombreCliente,
      fonoCliente,
      patente; // Conserva las relaciones y los datos visibles.
  final List<ArticuloVentaPendiente>
      articulos; // Conserva unidades sin descontar existencias.
  final DateTime?
      fechaCreacion; // Conserva el día del borrador sin crear una venta en Supabase.
  final int revision; // Impide sobrescribir una edición más reciente.
  VentaPendiente({
    required this.id,
    required this.rutCliente,
    required this.nombreCliente,
    required this.fonoCliente,
    required this.patente,
    required List<ArticuloVentaPendiente> articulos,
    this.revision = 0,
    this.fechaCreacion, // Mantiene fecha desconocida para borradores anteriores.
  }) : articulos = List.unmodifiable(
          articulos,
        ); // Protege el borrador frente a cambios externos.
  double get total => articulos.fold(
        0,
        (suma, articulo) => suma + articulo.precio * articulo.cantidad,
      ); // Calcula el total mostrado antes del cierre.
  VentaRegistro get registro => VentaRegistro(
        id: id,
        rutCliente:
            rutCliente, // Conserva el cliente del borrador en la vista del historial.
        clienteNombre: nombreCliente,
        vehiculoNombre: patente.isEmpty ? 'Sin vehículo' : patente,
        productosResumen:
            articulos.map((articulo) => articulo.nombre).join(', '),
        total: total,
        fecha: 'Pendiente de pago',
        items: articulos
            .map(
              (articulo) => <String, dynamic>{
                'codigo': articulo.codigo,
                'nombre': '${articulo.nombre} × ${articulo.cantidad}',
                'total': articulo.precio * articulo.cantidad,
              },
            )
            .toList(),
      ); // Reutiliza exactamente el diseño del historial.
  Map<String, dynamic> toJson() => {
        'id': id,
        'rut_cliente': rutCliente,
        'nombre_cliente': nombreCliente,
        'fono_cliente': fonoCliente,
        'patente': patente,
        'articulos': articulos.map((articulo) => articulo.toJson()).toList(),
        'revision': revision,
        'fecha_creacion': fechaCreacion
            ?.toUtc()
            .toIso8601String(), // Persiste el día original al editar.
      }; // Serializa el borrador completo.
  factory VentaPendiente.fromJson(Map<String, dynamic> datos) => VentaPendiente(
        id: datos['id'] as String,
        rutCliente: datos['rut_cliente'] as String,
        nombreCliente: datos['nombre_cliente'] as String,
        fonoCliente: datos['fono_cliente'] as String,
        patente: datos['patente'] as String,
        articulos: (datos['articulos'] as List)
            .map(
              (fila) => ArticuloVentaPendiente.fromJson(
                  Map<String, dynamic>.from(fila)),
            )
            .toList(),
        revision: datos['revision'] as int,
        fechaCreacion:
            DateTime.tryParse(datos['fecha_creacion']?.toString() ?? '')
                ?.toLocal(), // Recupera el día sin inventar fechas anteriores.
      ); // Recupera el borrador sin consultar Supabase.
} // Finaliza el modelo local.

class VentasPendientesRepository {
  // Administra borradores persistentes y su confirmación.
  final String
      clave; // Separa las pendientes de cada usuario en este dispositivo.
  final Future<SharedPreferences> Function()
      preferencias; // Permite verificar la persistencia con almacenamiento controlado.
  final Future<String> Function(VentaPendiente)
      registrar; // Envía la venta solamente al confirmar el pago.
  Future<void>? _cola; // Crea la cola cuando comienza una operación local.
  final Map<String, Future<String>> _confirmaciones =
      {}; // Comparte una única confirmación por venta.
  final Map<String, String> _recibos =
      {}; // Conserva resultados confirmados si falla la escritura local posterior.
  static final Map<String, VentasPendientesRepository> _instancias =
      {}; // Mantiene una instancia por usuario.
  VentasPendientesRepository({
    required this.clave,
    Future<SharedPreferences> Function()? preferencias,
    Future<String> Function(VentaPendiente)? registrar,
  })  : preferencias = preferencias ?? SharedPreferences.getInstance,
        registrar = registrar ??
            _registrarEnBase; // Configura los límites entre almacenamiento local y remoto.
  static VentasPendientesRepository get instancia {
    // Conserva los borradores dentro de la cuenta actual.
    final usuario = SupabaseDatabase.isConfigured
        ? SupabaseDatabase.client.auth.currentUser?.id ?? 'local'
        : 'local'; // Evita mezclar cuentas del mismo equipo.
    return _instancias.putIfAbsent(
      usuario,
      () => VentasPendientesRepository(clave: 'ventas_pendientes_v1_$usuario'),
    ); // Reutiliza la cola y los bloqueos del usuario.
  } // Finaliza el acceso al repositorio.

  static String nuevoId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}'; // Genera una clave local sin utilizar el identificador de Supabase.
  Future<T> _exclusivo<T>(Future<T> Function() accion) {
    // Evita que dos operaciones sobrescriban el archivo de preferencias.
    final anterior =
        _cola; // Conserva la operación previa si todavía está activa.
    final resultado = anterior == null
        ? Future<T>.sync(accion)
        : anterior.then(
            (_) => accion(),
          ); // Inicia la primera operación en el contexto actual.
    final cola = resultado.then<void>(
      (_) {},
      onError: (Object error, StackTrace traza) {},
    ); // Mantiene la cola disponible después de un fallo.
    _cola = cola; // Permite que otras operaciones esperen esta escritura.
    cola.then((_) {
      if (identical(_cola, cola)) _cola = null;
    }); // Libera la cola cuando no quedan operaciones posteriores.
    return resultado; // Devuelve el resultado y propaga el error al solicitante.
  } // Finaliza la exclusión de escrituras.

  Future<List<Map<String, dynamic>>> _leer() async {
    // Recupera registros locales y comprobantes de cierre.
    final almacen =
        await preferencias(); // Obtiene el almacenamiento del dispositivo.
    final texto = almacen.getString(
      clave,
    ); // Recupera únicamente las ventas de este usuario.
    if (texto == null) {
      return []; // Inicia un catálogo vacío sin sobrescribir datos existentes.
    }
    return (jsonDecode(texto) as List)
        .map((fila) => Map<String, dynamic>.from(fila))
        .toList(); // Propaga datos dañados para evitar perderlos silenciosamente.
  } // Finaliza la lectura local.

  Future<void> _escribir(List<Map<String, dynamic>> filas) async {
    // Espera la persistencia antes de anunciar éxito.
    final almacen =
        await preferencias(); // Obtiene el almacenamiento del dispositivo.
    if (!await almacen.setString(clave, jsonEncode(filas))) {
      throw StateError(
        'No se pudo conservar la venta en este dispositivo.',
      ); // Informa fallos sin descartar el formulario.
    }
  } // Finaliza la escritura.

  Future<List<VentaPendiente>> obtenerTodas() => _exclusivo(() async {
        // Muestra únicamente ventas que aún no tienen un comprobante remoto.
        final filas =
            await _leer(); // Recupera también confirmaciones interrumpidas.
        return filas
            .where((fila) => fila['estado'] != 'confirmada')
            .map((fila) => VentaPendiente.fromJson(fila))
            .toList()
            .reversed
            .toList(); // Conserva pendientes de revisión para impedir reenvíos automáticos.
      }); // Finaliza el catálogo de pendientes.
  Future<void> guardar(VentaPendiente venta) => _exclusivo(() async {
        // Guarda o modifica únicamente una venta pendiente.
        if (int.tryParse(venta.rutCliente) == null ||
            venta.articulos.isEmpty ||
            venta.articulos.any(
              (articulo) =>
                  articulo.codigo.trim().isEmpty || articulo.cantidad <= 0,
            )) {
          throw ArgumentError(
            'La venta requiere cliente y artículos válidos.',
          ); // Valida el borrador antes de persistir.
        }
        final filas =
            await _leer(); // Conserva los demás borradores del usuario.
        final indice = filas.indexWhere(
          (fila) => fila['id'] == venta.id,
        ); // Localiza la venta editada.
        if (indice >= 0 &&
            (filas[indice]['estado'] != 'pendiente' ||
                filas[indice]['revision'] != venta.revision)) {
          throw StateError(
            'La venta cambió o su pago ya fue enviado. Vuelve a abrirla.',
          ); // Impide editar una venta cerrada o desactualizada.
        }
        final registro = {
          ...venta.toJson(),
          'revision': venta.revision + 1,
          'estado': 'pendiente',
          'fecha_creacion': indice < 0
              ? (venta.fechaCreacion ?? DateTime.now())
                  .toUtc()
                  .toIso8601String()
              : filas[indice][
                  'fecha_creacion'], // Conserva el día original al modificar el borrador.
        }; // Incrementa la versión después de guardar.
        if (indice < 0) {
          filas.add(registro);
        } else {
          filas[indice] = registro;
        } // Conserva la misma clave al editar.
        await _escribir(
            filas); // No ejecuta consultas ni escrituras en Supabase.
      }); // Finaliza el guardado local.
  Future<void> cancelar(String id) => _exclusivo(() async {
        // Solo elimina borradores cuyo pago no se ha enviado.
        if (_confirmaciones.containsKey(id) || _recibos.containsKey(id)) {
          throw StateError(
              'No se puede cancelar una venta cuyo pago fue enviado.');
        }
        final filas = await _leer();
        final indice = filas.indexWhere((fila) => fila['id'] == id);
        if (indice < 0) return;
        if (filas[indice]['estado'] != 'pendiente') {
          throw StateError(
              'No se puede cancelar una venta cuyo pago fue enviado o debe revisarse.');
        }
        filas.removeAt(indice);
        await _escribir(filas);
      }); // Finaliza la cancelación segura del borrador.
  Future<bool> requiereRevision(String id) => _exclusivo(
        () async => (await _leer()).any(
          (fila) => fila['id'] == id && fila['estado'] == 'enviando',
        ),
      ); // Detecta una confirmación cuyo resultado no se conoce.
  Future<void> recuperarTrasRevision(String id) => _exclusivo(() async {
        if (_confirmaciones.containsKey(id) || _recibos.containsKey(id)) {
          throw StateError(
            'La confirmación sigue activa o ya tiene un comprobante.',
          ); // Impide restablecer un pago conocido.
        }
        final filas = await _leer(); // Conserva las otras ventas.
        final registro = filas.firstWhere(
          (fila) => fila['id'] == id,
        ); // Recupera el borrador revisado por el usuario.
        if (registro['estado'] != 'enviando' || registro['id_venta'] != null) {
          throw StateError(
            'Solo puede recuperarse una confirmación pendiente de revisión.',
          ); // No reabre ventas cerradas.
        }
        registro['estado'] =
            'pendiente'; // Habilita la corrección tras la revisión explícita del historial.
        registro['revision'] = (registro['revision'] as num? ?? 0).toInt() +
            1; // Invalida copias abiertas antes de recuperar.
        registro.remove(
          'error_confirmacion',
        ); // Conserva los datos de la venta y limpia el error revisado.
        await _escribir(filas); // No registra nada en Supabase.
      });
  Future<String?> errorConfirmacion(String id) => _exclusivo(() async {
        final filas =
            await _leer(); // Recupera el motivo aunque se reinicie la aplicación.
        final registros = filas.where((fila) => fila['id'] == id);
        return registros.isEmpty
            ? null
            : registros.first['error_confirmacion']
                as String?; // No inventa el motivo de envíos antiguos.
      });
  Future<void> _conservarError(String id, String mensaje) => _exclusivo(
        () async {
          final filas =
              await _leer(); // Conserva el borrador y su estado de envío.
          filas.firstWhere((fila) => fila['id'] == id)['error_confirmacion'] =
              mensaje; // Registra el error original del servidor.
          await _escribir(
            filas,
          ); // Permite diagnosticarlo al volver a abrir la venta.
        },
      );
  Future<String> confirmarPago(String id) {
    // Evita confirmar dos veces desde el mismo dispositivo.
    final activa = _confirmaciones[id]; // Reutiliza una solicitud en curso.
    if (activa != null) return activa; // Impide duplicados por clic repetido.
    final resultado = _confirmar(
      id,
    ); // Inicia una única transición al historial.
    _confirmaciones[id] =
        resultado; // Bloquea nuevas solicitudes para esta venta.
    resultado.then<void>(
      (_) => _confirmaciones.remove(id),
      onError: (Object error, StackTrace traza) {
        _confirmaciones.remove(id);
      },
    ); // Libera el bloqueo al finalizar.
    return resultado; // Permite mostrar el resultado del pago.
  } // Finaliza la protección de confirmación.

  Future<String> _confirmar(String id) async {
    // Conserva un registro de envío antes de contactar al servidor.
    final fila = await _exclusivo(() async {
      // Valida el estado persistido.
      final filas = await _leer(); // Recupera el borrador actual.
      final registro = filas.firstWhere(
        (fila) => fila['id'] == id,
        orElse: () => throw StateError('La venta pendiente no existe.'),
      ); // Evita confirmar un registro inexistente.
      if (registro['estado'] == 'confirmada') {
        return registro; // Devuelve el comprobante sin repetir la inserción.
      }
      if (_recibos.containsKey(id)) {
        registro['estado'] = 'confirmada';
        registro['id_venta'] = _recibos[id];
        await _escribir(filas);
        return registro;
      } // Recupera una confirmación remota que no se pudo persistir.
      if (registro['estado'] == 'enviando') {
        throw StateError(
          'El resultado del pago requiere revisión. Comprueba el historial antes de volver a registrar esta venta.',
        ); // Impide duplicar ventas ante cortes de conexión o reinicios.
      }
      registro['estado'] =
          'enviando'; // Bloquea edición y reenvíos antes de la llamada remota.
      await _escribir(
        filas,
      ); // Conserva la intención aun si se cierra la aplicación.
      return registro; // Envía la última versión guardada.
    }); // Finaliza la preparación local.
    if (fila['estado'] == 'confirmada') {
      return fila['id_venta'] as String; // Reutiliza un cierre ya completado.
    }
    final String idRemoto; // Conserva el identificador real del historial.
    try {
      // Envía la venta mediante la transacción existente.
      idRemoto = await registrar(
        VentaPendiente.fromJson(fila),
      ); // El servidor verifica stock y registra los detalles.
    } on PostgrestException catch (error) {
      // Un rechazo explícito revierte la transacción en Supabase.
      if (!const {
        'P0001',
        '23503',
        '23502',
        '23505',
        '23514',
        '22P02',
        '22003',
        '42501',
        '40001',
        '40P01',
        '57014',
        '42883',
        '42804', // Una incompatibilidad de tipos revierte la transacción.
        'PGRST202', // Una función ausente no llega a ejecutarse.
        'PGRST203', // Una función ambigua no llega a ejecutarse.
        'PGRST204', // Una columna ausente rechaza la solicitud.
        'PGRST205', // Una tabla ausente rechaza la solicitud.
      }.contains(error.code)) {
        // Distingue rechazos de la transacción de errores inciertos del intermediario.
        await _conservarError(
          id,
          '${error.code}: ${error.message}',
        ); // Mantiene el diagnóstico sin habilitar otro envío.
        throw StateError(
          'No se pudo comprobar el resultado. Revisa el historial antes de volver a registrar la venta. Detalle: ${error.code}: ${error.message}',
        ); // Conserva el bloqueo cuando no se conoce el resultado remoto.
      } // Finaliza la comprobación del rechazo.
      await _exclusivo(() async {
        final filas = await _leer();
        final registro = filas.firstWhere(
          (fila) => fila['id'] == id,
        ); // Recupera el borrador rechazado.
        registro['estado'] =
            'pendiente'; // Permite corregir un rechazo explícito.
        registro['error_confirmacion'] =
            '${error.code}: ${error.message}'; // Conserva el motivo real.
        await _escribir(filas);
      }); // Permite corregir stock o datos y reintentar.
      rethrow; // Presenta el motivo del rechazo.
    } catch (error) {
      await _conservarError(
        id,
        error.toString(),
      ); // Conserva también errores de conexión.
      // Una desconexión podría ocurrir después de que el servidor guardó la venta.
      throw StateError(
        'No se pudo comprobar el resultado. Revisa el historial; el envío queda bloqueado para evitar una venta duplicada.',
      ); // Conserva el borrador y exige revisar el resultado.
    } // Finaliza la solicitud remota.
    _recibos[id] =
        idRemoto; // Impide repetir la transacción si falla el almacenamiento local.
    await _exclusivo(() async {
      // Confirma el cierre después de recibir respuesta.
      final filas = await _leer(); // Conserva los demás registros.
      final registro = filas.firstWhere(
        (fila) => fila['id'] == id,
      ); // Localiza la venta confirmada.
      registro['estado'] =
          'confirmada'; // Retira la venta del catálogo de pendientes.
      registro['id_venta'] =
          idRemoto; // Conserva el comprobante para impedir duplicados.
      await _escribir(filas); // Mantiene la confirmación después de reiniciar.
    }); // Finaliza la transición local.
    return idRemoto; // Permite abrir el detalle del historial real.
  } // Finaliza el cierre de venta.

  static Future<String> _registrarEnBase(VentaPendiente venta) async {
    // Utiliza la función existente sin modificar las tablas.
    final id = await SupabaseDatabase.client.rpc(
      'registrar_venta',
      params: {
        'p_rut_cliente': int.parse(venta.rutCliente),
        'p_patente_vehiculo': venta.patente,
        'p_iva': 19,
        'p_detalles': venta.articulos
            .map(
              (articulo) => {
                'codigo_producto': articulo.codigo,
                'cantidad': articulo.cantidad,
              },
            )
            .toList(),
      },
    ); // El stock se descuenta únicamente al confirmar el pago.
    return id.toString(); // Conserva el identificador asignado por la base.
  } // Finaliza el envío remoto.
} // Finaliza el repositorio de ventas pendientes.
