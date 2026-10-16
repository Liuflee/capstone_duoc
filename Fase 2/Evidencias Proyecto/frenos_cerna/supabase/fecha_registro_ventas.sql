-- Conserva el día ingresado como YYYY-MM-DD, sin convertirlo a otro día por zona horaria.
BEGIN; -- Aplica la corrección completa sin dejar cambios parciales.
ALTER TABLE public.venta ADD COLUMN IF NOT EXISTS fecha_registro date; -- Las ventas sin fecha conocida conservan NULL.
DO $$ -- Admite tanto la columna nueva DATE como la versión anterior con hora.
DECLARE tipo_fecha text; -- Identifica el tipo actual antes de convertirlo.
BEGIN -- Comprueba el esquema existente.
  SELECT data_type INTO tipo_fecha FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'venta' AND column_name = 'fecha_registro'; -- Obtiene el tipo real de la columna.
  IF tipo_fecha = 'timestamp with time zone' THEN -- Corrige las fechas manuales que Supabase guardó a medianoche UTC.
    IF EXISTS (SELECT 1 FROM public.venta WHERE fecha_registro IS NOT NULL AND (fecha_registro AT TIME ZONE 'UTC')::time <> TIME '00:00:00') THEN -- Evita reinterpretar ventas que tienen una hora real de registro.
      RAISE EXCEPTION 'Hay ventas con hora de registro real. Revisa su conversión antes de ejecutar esta corrección de fechas manuales.'; -- Cancela la transacción si los datos requieren otra conversión.
    END IF; -- Finaliza la comprobación de las fechas manuales.
    ALTER TABLE public.venta ALTER COLUMN fecha_registro DROP DEFAULT; -- Retira el valor anterior antes de cambiar el tipo.
    ALTER TABLE public.venta ALTER COLUMN fecha_registro TYPE date USING (fecha_registro AT TIME ZONE 'UTC')::date; -- Conserva exactamente el día elegido manualmente, sin desplazarlo a la víspera en Chile.
  ELSIF tipo_fecha <> 'date' THEN -- Evita convertir silenciosamente un tipo diferente al comprobado.
    RAISE EXCEPTION 'El tipo de fecha_registro es %, se esperaba date o timestamp with time zone.', tipo_fecha; -- Exige revisar cualquier esquema no previsto.
  END IF; -- Permite volver a ejecutar el archivo cuando la columna ya es DATE.
END; $$; -- Finaliza la conversión comprobada.
ALTER TABLE public.venta ALTER COLUMN fecha_registro SET DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'America/Santiago')::date); -- Las ventas nuevas reciben el día actual de Chile al confirmar el pago.
COMMENT ON COLUMN public.venta.fecha_registro IS 'Día de la venta concretada en formato YYYY-MM-DD; NULL indica fecha histórica desconocida'; -- Documenta que esta columna representa un día y no un instante.
COMMIT; -- Conserva las fechas manuales y el valor automático para nuevas ventas.
