import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frenos_cerna/features/asistente/asistente_repository.dart';
import 'package:frenos_cerna/features/asistente/consulta_voz.dart';

void main() {
  late SupabaseClient cliente;
  late List<http.Request> consultas;
  late Object Function(http.Request) responder;
  setUp(() async {
    consultas = [];
    responder = (_) => <dynamic>[];
    final transporte = MockClient((peticion) async {
      if (peticion.url.path == '/auth/v1/token') {
        final payload = base64Url
            .encode(
              utf8.encode(
                jsonEncode({
                  'sub': '11111111-1111-1111-1111-111111111111',
                  'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
                }),
              ),
            )
            .replaceAll('=', '');
        return http.Response(
          jsonEncode({
            'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.firma',
            'token_type': 'bearer',
            'refresh_token': 'prueba',
            'expires_in': 3600,
            'user': {
              'id': '11111111-1111-1111-1111-111111111111',
              'aud': 'authenticated',
              'email': 'prueba@example.invalid',
            },
          }),
          200,
          headers: {'content-type': 'application/json'}, request: peticion,
        );
      }
      consultas.add(peticion);
      return http.Response(
        jsonEncode(responder(peticion)),
        200,
        headers: {'content-type': 'application/json'}, request: peticion,
      );
    });
    cliente = SupabaseClient(
      'https://prueba.supabase.co',
      'publica',
      httpClient: transporte,
    );
    await cliente.auth.signInWithPassword(
      email: 'prueba@example.invalid',
      password: 'solo-prueba',
    );
  });
  tearDown(() async => cliente.dispose());

  test(
    'Consulta productos con la sesión, sin alterar códigos ni escribir datos',
    () async {
      responder = (_) => [
        {'codigo_producto': 'ABC-001', 'stock': 7, 'precio': 1500},
      ];
      final resultado = await AsistenteRepository(cliente: cliente)
          .consultar(ConsultaVoz.interpretar('Stock del producto ABC-001'));
      expect(resultado.filas.single, ['ABC-001', '7', '1500']);
      expect(consultas.single.method, 'GET');
      expect(consultas.single.url.path, '/rest/v1/producto');
      expect(
        consultas.single.url.queryParameters['codigo_producto'],
        'eq.ABC-001',
      );
      expect(consultas.single.headers['Authorization'], startsWith('Bearer '));
    },
  );
  test(
    'Stock bajo filtra por cinco unidades y avisa al limitar resultados',
    () async {
      responder = (_) => List.generate(
        51,
        (i) => {'codigo_producto': '$i', 'stock': 2, 'precio': 10},
      );
      final resultado = await AsistenteRepository(cliente: cliente)
          .consultar(ConsultaVoz.interpretar('Stock bajo'));
      expect(consultas.single.url.queryParameters['stock'], 'lte.5');
      expect(resultado.filas.length, 50);
      expect(resultado.resumen, contains('primeros 50'));
    },
  );
  test(
    'Ventas pagina y suma productos y servicios, con límites de fecha',
    () async {
      var pagina = 0;
      responder = (_) {
        pagina++;
        return List.generate(
          pagina == 1 ? 500 : 1,
          (i) => {
            'id': i,
            'detalle_venta_producto': [
              {'total': 100},
            ],
            'detalle_venta_servicio': [
              {'total': 25},
            ],
          },
        );
      };
      final resultado = await AsistenteRepository(cliente: cliente).consultar(
        ConsultaVoz.interpretar('Ventas de hoy', ahora: DateTime(2026, 11, 11)),
      );
      expect(consultas.length, 2);
      expect(resultado.resumen, contains('501 ventas, total CLP 62625'));
      expect(
        consultas.first.url.queryParametersAll['fecha_registro']!.length,
        2,
      );
      expect(consultas.every((p) => p.method == 'GET'), isTrue);
    },
  );
  test('Rechaza una consulta cuando no existe una sesión', () async {
    final sinSesion = SupabaseClient('https://prueba.supabase.co', 'publica');
    try {
      await expectLater(
        AsistenteRepository(cliente: sinSesion)
            .consultar(ConsultaVoz.interpretar('Stock bajo')),
        throwsStateError,
      );
    } finally {
      await sinSesion.dispose();
    }
    expect(consultas, isEmpty);
  });
}
