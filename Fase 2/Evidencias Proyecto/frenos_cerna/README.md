# Frenos Cerna

## Configuración de Supabase

1. Crea un proyecto en Supabase y abre su SQL Editor.
2. Ejecuta el esquema de `../Base de Datos/db-frenos-cerna_2026-09-12T23_09_07.637Z.sql`.
3. Ejecuta `supabase/codigo_producto_alfanumerico.sql` para permitir los códigos de producto alfanuméricos que usa el formulario y sus ventas.
4. Ejecuta `supabase/registrar_venta.sql` en el SQL Editor. La función registra la venta, sus detalles y descuenta stock dentro de una transacción.
5. Ejecuta `supabase/autenticacion_perfiles.sql`. Crea un perfil para cada cuenta autenticada, asigna `empleado` al registrarse y aplica políticas RLS a las tablas usadas por la aplicación.
6. Ejecuta `supabase/reservas_producto.sql` para habilitar las reservas y su gestión.
7. Ejecuta `supabase/administrar_perfiles.sql`. Habilita la eliminación protegida del acceso de dueño/mecánico; no elimina la cuenta Auth ni los datos del negocio.
8. Ejecuta `supabase/eliminacion_logica_productos.sql` para habilitar la baja lógica de productos. Los productos quedan ocultos del inventario y de nuevas ventas, mientras sus referencias históricas se conservan.
9. Ejecuta `supabase/administrar_eliminaciones.sql` para aplicar bajas lógicas a clientes, vehículos y catálogos, y reservar las eliminaciones físicas al administrador en Supabase.
10. Copia `supabase.example.json` como `supabase.config.json`, reemplaza sus valores con la URL del proyecto y su publishable key, e inicia la aplicación:

```powershell
flutter run --dart-define-from-file=supabase.config.json
```

6. Registra la cuenta que será administradora y, si la confirmación por correo está habilitada, confírmala. Luego asígnale ese rol desde el SQL Editor, sustituyendo el correo:

```sql
UPDATE public.perfil_usuario AS p
SET rol = 'administrador'
FROM auth.users AS u
WHERE p.user_id = u.id
  AND u.email = 'admin@ejemplo.cl';
```

El formulario público nunca permite escoger el rol: las nuevas cuentas siempre quedan como `empleado`. La aplicación carga el perfil autenticado y el rol tipado para poder diferenciar las experiencias por perfil. Las autorizaciones de los datos se aplican también en Supabase mediante RLS; no se debe confiar solo en ocultar controles del frontend.

Para pruebas locales, la pantalla de acceso tiene un botón «Entrar en modo de prueba». Este modo no inicia sesión en Supabase ni habilita operaciones protegidas. Antes de distribuir la app, cambia `habilitarModoPrueba` a `false` en `lib/features/autenticacion/presentation/puerta_autenticacion.dart` para ocultar el botón.

El archivo `supabase.config.json` está excluido de Git. No pongas una `service_role` key en la aplicación. La aplicación mostrará el formulario de autenticación deshabilitado hasta configurar Supabase.

El cliente y los nombres de las tablas están centralizados en `lib/core/data/supabase_database.dart`. Clientes, vehículos, inventario y ventas se consultan desde Supabase; las altas y ediciones usan las columnas definidas en el esquema. El historial de ventas calcula los totales desde sus tablas de detalle.

El esquema no almacena nombre para los productos (se muestra el código de barra o el código), cantidad por línea de venta, fecha ni estado de venta. El importe de cada línea se guarda en `detalle_venta_producto.total`; el IVA se registra como porcentaje (19). Tampoco conserva el dígito verificador `K` del RUT ni ceros iniciales del teléfono porque `rut` y `fono` son enteros; para esos formatos, migra ambas columnas a texto antes de cargar datos reales.
