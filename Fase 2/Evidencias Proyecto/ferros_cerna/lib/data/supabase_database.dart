import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDatabase {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => _url.isNotEmpty && _publishableKey.isNotEmpty;

  static Future<void> initialize() async {
    if (_url.isEmpty && _publishableKey.isEmpty) {
      debugPrint(
        'Supabase no está configurado; se inicia la aplicación sin conexión.',
      );
      return;
    }

    if (!isConfigured) {
      throw StateError('Configura SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY.');
    }

    await Supabase.initialize(url: _url, publishableKey: _publishableKey);
  }

  static SupabaseClient get client {
    if (!isConfigured) {
      throw StateError(
        'Configura Supabase antes de acceder a la base de datos.',
      );
    }
    return Supabase.instance.client;
  }
}

abstract final class SupabaseTables {
  static const clientes = 'cliente';
  static const vehiculos = 'vehiculo_cliente';
  static const ventas = 'venta';
  static const marcasVehiculo = 'marca_vehiculo';
  static const modelosVehiculo = 'modelo_vehiculo';
  static const productos = 'producto';
  static const tiposProducto = 'tipo_producto';
  static const calidadesProducto = 'calidad_producto';
  static const servicios = 'servicio';
  static const detallesVentaProducto = 'detalle_venta_producto';
  static const detallesVentaServicio = 'detalle_venta_servicio';
}
