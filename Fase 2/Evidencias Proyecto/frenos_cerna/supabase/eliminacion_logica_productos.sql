-- Ejecutar en Supabase para habilitar la eliminación lógica desde Inventario.
-- Las claves foráneas y los detalles de ventas históricas se conservan.
BEGIN;

ALTER TABLE public.producto
  ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true;

-- Los productos existentes permanecen disponibles tras agregar la columna.
UPDATE public.producto
SET activo = true
WHERE activo IS NULL;

COMMIT;
