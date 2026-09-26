# Frenos Cerna

## Configuración de Supabase

1. Crea un proyecto en Supabase y abre su SQL Editor.
2. Ejecuta el esquema de `../Base de Datos/db-frenos-cerna_2026-09-12T23_09_07.637Z.sql`.
3. Copia `supabase.example.json` como `supabase.config.json` y reemplaza sus valores con la URL del proyecto y su publishable key.
4. Desde esta carpeta, inicia Flutter con:

```powershell
flutter run --dart-define-from-file=supabase.config.json
```

El archivo `supabase.config.json` está excluido de Git. No pongas una `service_role` key en la aplicación; activa RLS y define políticas para las tablas antes de usar datos reales. Sin configuración, la aplicación inicia sin conectarse.

El cliente y los nombres de las tablas están centralizados en `lib/data/supabase_database.dart`. Las pantallas actuales todavía usan datos de demostración y algunos campos visuales no existen en el esquema SQL (por ejemplo, nombre y cantidad para productos, y fecha/estado para ventas), por lo que aún no realizan lecturas ni escrituras en Supabase.

El esquema conserva `rut` y `fono` como enteros. Antes de cargar datos reales, considera cambiarlos a texto para conservar el formato del RUT chileno, el dígito verificador `K` y prefijos telefónicos.
