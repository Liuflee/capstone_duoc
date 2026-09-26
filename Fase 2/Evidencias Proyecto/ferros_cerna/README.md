# Frenos Cerna

## Configuración de Supabase

1. Crea un proyecto en Supabase y abre su SQL Editor.
2. Ejecuta el esquema de `../Base de Datos/db-frenos-cerna_2026-09-12T23_09_07.637Z.sql`.
3. Ejecuta `supabase/registrar_venta.sql` en el SQL Editor. La función registra la venta, sus detalles y descuenta stock dentro de una transacción.
4. Copia `supabase.example.json` como `supabase.config.json` y reemplaza sus valores con la URL del proyecto y su publishable key.
5. Desde esta carpeta, inicia Flutter con:

```powershell
flutter run --dart-define-from-file=supabase.config.json
```

El archivo `supabase.config.json` está excluido de Git. No pongas una `service_role` key en la aplicación; activa RLS y define políticas para las tablas y para la función RPC antes de usar datos reales. Sin configuración, la aplicación inicia sin conectarse.

El cliente y los nombres de las tablas están centralizados en `lib/data/supabase_database.dart`. Clientes, vehículos, inventario y ventas se consultan desde Supabase; las altas y ediciones usan las columnas definidas en el esquema. El historial de ventas calcula los totales desde sus tablas de detalle.

El esquema no almacena nombre para los productos (se muestra el código de barra o el código), cantidad por línea de venta, fecha ni estado de venta. El importe de cada línea se guarda en `detalle_venta_producto.total`; el IVA se registra como porcentaje (19). Tampoco conserva el dígito verificador `K` del RUT ni ceros iniciales del teléfono porque `rut` y `fono` son enteros; para esos formatos, migra ambas columnas a texto antes de cargar datos reales.
