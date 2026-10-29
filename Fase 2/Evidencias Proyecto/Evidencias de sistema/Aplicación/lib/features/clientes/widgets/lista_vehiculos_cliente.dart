import 'package:flutter/material.dart';
import 'package:frenos_cerna/features/vehiculos/pagina_vehiculos.dart';
import 'package:frenos_cerna/shared/widgets/carta_navegacion.dart';

class ListaVehiculosCliente extends StatelessWidget {
  final List<HistorialVehiculo> vehiculos;
  final bool cargando;
  final String? error;
  final VoidCallback alReintentar;
  final ValueChanged<HistorialVehiculo> alAbrir;

  const ListaVehiculosCliente({
    super.key,
    required this.vehiculos,
    required this.cargando,
    required this.error,
    required this.alReintentar,
    required this.alAbrir,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'VEHÍCULOS DEL CLIENTE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            cargando
                ? 'Cargando...'
                : error != null
                ? 'No disponibles'
                : '${vehiculos.length} ${vehiculos.length == 1 ? 'vehículo' : 'vehículos'}',
            style: const TextStyle(color: Color(0xFF616161)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (cargando)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (error != null)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No se pudieron cargar los vehículos: $error'),
              const SizedBox(height: 8),
              CartaNavegacion.accion(
                onPressed: alReintentar,
                child: const Text('REINTENTAR'),
              ),
            ],
          ),
        )
      else if (vehiculos.isEmpty)
        const Text('Este cliente aún no tiene vehículos registrados.')
      else
        for (final vehiculo in vehiculos)
          LayoutBuilder(
            builder: (context, limites) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: limites.maxWidth < 520
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _informacionVehiculo(vehiculo),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _botonDetalle(vehiculo),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _informacionVehiculo(vehiculo)),
                          const SizedBox(width: 12),
                          _botonDetalle(vehiculo),
                        ],
                      ),
              ),
            ),
          ),
    ],
  );

  Widget _informacionVehiculo(HistorialVehiculo vehiculo) => Row(
    children: [
      const CircleAvatar(
        backgroundColor: Color(0xFFFF6D6D),
        foregroundColor: Colors.black,
        child: Icon(Icons.directions_car_outlined),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehiculo.vehiculoNombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'Patente: ${vehiculo.id} · Kilometraje: ${vehiculo.total.toStringAsFixed(0)} km',
              style: const TextStyle(color: Color(0xFF616161)),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _botonDetalle(HistorialVehiculo vehiculo) =>
      CartaNavegacion.accion(
        tipoBoton: 'icon',
        tooltip: 'Ver detalle de ${vehiculo.id}',
        onPressed: () => alAbrir(vehiculo),
        child: const Icon(Icons.search),
      );
}
