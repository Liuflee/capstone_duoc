import 'package:frenos_cerna/core/data/supabase_database.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_pendientes_repository.dart';
import 'package:frenos_cerna/features/ventas/data/ventas_repository.dart';

import 'asistente_repository.dart';
import 'consulta_voz.dart';

const instruccionesCerna = '''
Eres Cerna, el asistente de voz de Frenos Cerna. Responde en español de Chile,
breve y claro. «Oye Cerna» y «Hey Cerna» son saludos de activación.
Usa las herramientas para obtener datos reales. Si falta un dato, o no se
entiende un código, patente, RUT o cantidad, pide que lo repitan. Conserva los
guiones y ceros iniciales de los códigos. No adivines montos ni precios.
Para preparar una venta pide los códigos y cantidades, y la patente del
vehículo o el RUT numérico del cliente sin dígito verificador. Si la persona
indica que es sin vehículo, pide el RUT. Usa preparar_venta_pendiente.
La app mostrará una confirmación que el usuario debe pulsar. Los precios y el
stock los obtiene la app. Solo anuncia que se guardó si la herramienta lo
confirma. Una venta pendiente queda en este dispositivo hasta confirmar su pago
desde el flujo normal.
''';

const herramientasCerna = [
  {
    'name': 'consultar_stock',
    'description': 'Consulta por código o lista stock bajo y agotado.',
    'parameters': {
      'type': 'OBJECT',
      'properties': {
        'modo': {
          'type': 'STRING',
          'enum': ['codigo', 'bajo', 'agotado'],
        },
        'codigo': {'type': 'STRING'},
      },
      'required': ['modo'],
    },
  },
  {
    'name': 'consultar_ventas',
    'description':
        'Obtiene total en CLP y cantidad de ventas pagadas del período.',
    'parameters': {
      'type': 'OBJECT',
      'properties': {
        'periodo': {
          'type': 'STRING',
          'enum': ['hoy', 'mes'],
        },
      },
      'required': ['periodo'],
    },
  },
  {
    'name': 'consultar_vehiculo',
    'description': 'Obtiene el kilometraje registrado o el historial de compras por patente, en páginas de cinco.',
    'parameters': {
      'type': 'OBJECT',
      'properties': {
        'patente': {'type': 'STRING'},
        'dato': {
          'type': 'STRING',
          'enum': ['kilometraje', 'historial'],
        },
        'pagina': {
          'type': 'INTEGER',
          'description':
              'Empieza en 1. Avanza si el usuario pide compras anteriores.',
        },
      },
      'required': ['patente', 'dato'],
    },
  },
  {
    'name': 'preparar_venta_pendiente',
    'description': 'Prepara una venta de productos y solicita confirmación en la pantalla.',
    'parameters': {
      'type': 'OBJECT',
      'properties': {
        'rut': {
          'type': 'STRING',
          'description': 'RUT numérico sin dígito verificador',
        },
        'patente': {'type': 'STRING'},
        'articulos': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'codigo': {'type': 'STRING'},
              'cantidad': {'type': 'INTEGER'},
            },
            'required': ['codigo', 'cantidad'],
          },
        },
      },
      'required': ['articulos'],
    },
  },
];

class AccionesCerna {
  AccionesCerna(this.usuario, this.confirmar);
  final String usuario;
  final Future<bool> Function(VentaPendiente, String) confirmar;
  final _repositorio = const AsistenteRepository();
  final _comprasEnCurso = <String, Future<Map<String, Object?>>>{};

  Future<Map<String, Object?>> ejecutar(
    String nombre,
    Map<String, dynamic> datos,
    String id,
    bool Function() vigente,
  ) async {
    try {
      _sesion(vigente);
      final respuesta = await switch (nombre) {
        'consultar_stock' => _stock(datos),
        'consultar_ventas' => _ventas(datos),
        'consultar_vehiculo' => _vehiculo(datos, vigente),
        'preparar_venta_pendiente' => _comprasEnCurso.putIfAbsent(
          id,
          () => _venta(datos, id, vigente),
        ),
        _ => Future.value(<String, Object?>{'error': 'Acción no disponible'}),
      };
      _sesion(vigente);
      return respuesta;
    } on FormatException catch (error) {
      return {'error': error.message};
    } catch (_) {
      return {
        'error': 'No se pudo completar la operación. Inténtalo de nuevo.',
      };
    }
  }

  void _sesion(bool Function() vigente) {
    if (!vigente() || SupabaseDatabase.client.auth.currentUser?.id != usuario) {
      throw StateError('Sesión finalizada');
    }
  }

  Future<Map<String, Object?>> _stock(Map<String, dynamic> datos) async {
    final modo = datos['modo'];
    if (modo == 'codigo') {
      final codigo = _codigo(datos['codigo']);
      final producto = await _repositorio.consultarCodigo(codigo, usuario);
      return {
        'encontrado': producto != null,
        if (producto != null) ...{
          'codigo': producto.codigo,
          'tipo': producto.tipo,
          'stock': producto.stock,
        },
      };
    }
    final consulta = switch (modo) {
      'bajo' => ConsultaVoz.stockBajo,
      'agotado' => ConsultaVoz.sinStock,
      _ => throw const FormatException(
        'Indica si buscas stock bajo o agotado.',
      ),
    };
    final productos = await _repositorio.consultar(consulta, usuario);
    return {
      'cantidad': productos.length,
      'primeros_productos': productos
          .take(10)
          .map((p) => {'codigo': p.codigo, 'tipo': p.tipo, 'stock': p.stock})
          .toList(),
    };
  }

  Future<Map<String, Object?>> _ventas(Map<String, dynamic> datos) async {
    final periodo = switch (datos['periodo']) {
      'hoy' => PeriodoVentasVoz.hoy,
      'mes' => PeriodoVentasVoz.mes,
      _ => throw const FormatException(
        'Indica si buscas ventas de hoy o del mes.',
      ),
    };
    final ventas = await _repositorio.consultarVentas(periodo, usuario);
    return {'cantidad': ventas.cantidad, 'total_clp': ventas.total};
  }

  Future<Map<String, Object?>> _vehiculo(
    Map<String, dynamic> datos,
    bool Function() vigente,
  ) async {
    final patente = _patente(datos['patente']);
    final vehiculo = await SupabaseDatabase.client
        .from(SupabaseTables.vehiculos)
        .select('patente, kilometraje')
        .eq('patente', patente)
        .maybeSingle();
    if (vehiculo == null) return {'encontrado': false, 'patente': patente};
    if (datos['dato'] == 'kilometraje') {
      return {'patente': patente, 'kilometraje': vehiculo['kilometraje']};
    }
    if (datos['dato'] != 'historial') {
      throw const FormatException(
        'Indica si buscas el kilometraje o las compras.',
      );
    }
    final pagina = datos['pagina'] ?? 1;
    if (pagina is! int || pagina < 1 || pagina > 100000) {
      throw const FormatException('Indica un número de página válido.');
    }
    _sesion(vigente);
    final ventas = await VentaRegistro.obtenerPorPatente(
      patente,
      limite: 6,
      desde: (pagina - 1) * 5,
    );
    return {
      'patente': patente,
      'pagina': pagina,
      'hay_mas': ventas.length > 5,
      'compras': ventas
          .take(5)
          .map(
            (v) => {
              'fecha': v.fecha,
              'total_clp': v.total,
              'detalle': v.productosResumen,
            },
          )
          .toList(),
    };
  }

  Future<Map<String, Object?>> _venta(
    Map<String, dynamic> datos,
    String id,
    bool Function() vigente,
  ) async {
    final rutDicho = datos['rut'];
    final rutIngresado =
        rutDicho is String && RegExp(r'^[0-9]{1,10}$').hasMatch(rutDicho)
        ? int.tryParse(rutDicho)
        : null;
    if (rutDicho != null && (rutIngresado == null || rutIngresado <= 0)) {
      throw const FormatException('Repite el RUT sin dígito verificador.');
    }

    final lineas = datos['articulos'];
    if (lineas is! List || lineas.isEmpty || lineas.length > 20) {
      throw const FormatException(
        'Indica hasta 20 productos con sus cantidades.',
      );
    }

    final patente = datos['patente'] == null ? '' : _patente(datos['patente']);
    final cliente = SupabaseDatabase.client;
    final borradores = VentasPendientesRepository.instancia;
    var rut = rutIngresado;
    if (patente.isNotEmpty) {
      final vehiculo = await cliente
          .from(SupabaseTables.vehiculos)
          .select('rut_cliente')
          .eq('patente', patente)
          .maybeSingle();
      _sesion(vigente);
      final propietario = int.tryParse(
        vehiculo?['rut_cliente']?.toString() ?? '',
      );
      if (propietario == null) {
        throw const FormatException(
          'No encontré un cliente vinculado a esa patente.',
        );
      }
      if (rut != null && rut != propietario) {
        throw const FormatException(
          'La patente no está vinculada a ese cliente.',
        );
      }
      rut = propietario;
    }
    if (rut == null) {
      throw const FormatException(
        'Indica la patente o el RUT del cliente sin dígito verificador.',
      );
    }
    final persona = await cliente
        .from(SupabaseTables.clientes)
        .select('nombre, fono')
        .eq('rut', rut)
        .maybeSingle();
    _sesion(vigente);
    if (persona == null) {
      throw const FormatException(
        'El RUT no corresponde a un cliente registrado.',
      );
    }

    final cantidades = <String, int>{};
    for (final linea in lineas) {
      if (linea is! Map)
        throw const FormatException('El artículo no es válido.');
      final codigo = _codigo(linea['codigo']);
      final cantidad = linea['cantidad'];
      if (cantidad is! int || cantidad <= 0) {
        throw const FormatException(
          'Cada producto requiere una cantidad entera positiva.',
        );
      }
      cantidades.update(
        codigo,
        (actual) => actual + cantidad,
        ifAbsent: () => cantidad,
      );
    }

    final articulos = <String, ArticuloVentaPendiente>{};
    for (final linea in cantidades.entries) {
      _sesion(vigente);
      final producto = await _repositorio.consultarCodigo(linea.key, usuario);
      if (producto == null) {
        throw FormatException('No encontré el producto ${linea.key}.');
      }
      _sesion(vigente);
      final detalle = await cliente
          .from(SupabaseTables.productos)
          .select('precio, cod_barra, stock')
          .eq('codigo_producto', producto.codigo)
          .single();
      final cantidad =
          linea.value + (articulos[producto.codigo]?.cantidad ?? 0);
      final stock = (detalle['stock'] as num).toInt();
      final precio = num.tryParse(detalle['precio'].toString());
      if (cantidad > stock ||
          precio == null ||
          !precio.isFinite ||
          precio < 0) {
        throw FormatException(
          'Revisa el stock o el precio de ${producto.codigo}.',
        );
      }
      final barra = detalle['cod_barra']?.toString().trim() ?? '';
      articulos[producto.codigo] = ArticuloVentaPendiente(
        codigo: producto.codigo,
        nombre: barra.isEmpty ? producto.codigo : barra,
        categoria: producto.tipo,
        precio: precio.toDouble(),
        cantidad: cantidad,
        stock: stock,
      );
    }

    final venta = VentaPendiente(
      id: VentasPendientesRepository.nuevoId(),
      rutCliente: rut.toString(),
      nombreCliente: persona['nombre']?.toString() ?? '',
      fonoCliente: persona['fono']?.toString() ?? '',
      patente: patente,
      articulos: articulos.values.toList(),
    );
    _sesion(vigente);
    if (!await confirmar(venta, id))
      return {'guardada': false, 'cancelada': true};
    _sesion(vigente);
    await borradores.guardar(venta);
    return {
      'guardada': true,
      'estado': 'pendiente de pago',
      'total_clp': venta.total,
    };
  }

  String _codigo(Object? valor) {
    final codigo = valor is String ? valor.trim() : '';
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(codigo)) {
      throw const FormatException(
        'Repite el código de producto, con sus guiones si corresponde.',
      );
    }
    return codigo;
  }

  String _patente(Object? valor) {
    final patente = valor is String
        ? valor.replaceAll(RegExp(r'[\s-]'), '').toUpperCase()
        : '';
    if (!RegExp(r'^[A-Z0-9]{5,8}$').hasMatch(patente)) {
      throw const FormatException(
        'Repite la patente letra por letra y número por número.',
      );
    }
    return patente;
  }
}
