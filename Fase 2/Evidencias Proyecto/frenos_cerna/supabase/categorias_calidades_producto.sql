-- Ejecutar después de reparar_secuencias_catalogos.sql y autenticacion_perfiles.sql.
-- Una calidad puede utilizarse en varias categorías, pero solo cuando se vincula explícitamente.
BEGIN;
CREATE TABLE IF NOT EXISTS public.tipo_calidad_producto (
  id_tipo integer NOT NULL REFERENCES public.tipo_producto(id), -- Categoría existente.
  id_calidad integer NOT NULL REFERENCES public.calidad_producto(id), -- Calidad existente.
  PRIMARY KEY (id_tipo, id_calidad) -- Impide repetir la misma asociación.
);
-- Conserva todas las combinaciones que ya están utilizadas por los productos.
INSERT INTO public.tipo_calidad_producto (id_tipo, id_calidad)
SELECT DISTINCT tipo, calidad FROM public.producto
WHERE tipo IS NOT NULL AND calidad IS NOT NULL
ON CONFLICT DO NOTHING;
-- No asigna calidades sin uso a categorías inventadas: se vinculan desde el selector al añadirlas.
ALTER TABLE public.tipo_calidad_producto ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS empleados_y_administradores ON public.tipo_calidad_producto;
CREATE POLICY empleados_y_administradores ON public.tipo_calidad_producto
FOR ALL TO authenticated
USING ((SELECT public.rol_actual()) IN ('administrador', 'empleado'))
WITH CHECK ((SELECT public.rol_actual()) IN ('administrador', 'empleado'));
REVOKE ALL ON public.tipo_calidad_producto FROM PUBLIC, anon;
GRANT SELECT, INSERT ON public.tipo_calidad_producto TO authenticated;
-- También protege los cambios realizados fuera del formulario.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.producto'::regclass AND conname = 'producto_tipo_calidad_fkey') THEN
    ALTER TABLE public.producto ADD CONSTRAINT producto_tipo_calidad_fkey
      FOREIGN KEY (tipo, calidad) REFERENCES public.tipo_calidad_producto(id_tipo, id_calidad);
  END IF;
END;
$$;
-- Crea o reutiliza una calidad y la vincula dentro de una única transacción.
CREATE OR REPLACE FUNCTION public.crear_calidad_categoria(p_id_tipo integer, p_nombre text)
RETURNS TABLE(id integer, nombre_calidad varchar)
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE
  v_id integer; -- ID real de la calidad seleccionada o creada.
  v_nombre text := btrim(p_nombre); -- Elimina espacios externos.
BEGIN
  IF v_nombre IS NULL OR v_nombre = '' THEN
    RAISE EXCEPTION 'Ingresa el nombre de la calidad.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tipo_producto t WHERE t.id = p_id_tipo) THEN
    RAISE EXCEPTION 'Selecciona primero una categoría existente.';
  END IF;
  -- Serializa esta creación para evitar duplicados concurrentes del mismo nombre.
  PERFORM pg_advisory_xact_lock(417203901);
  SELECT c.id INTO v_id FROM public.calidad_producto c
  WHERE lower(btrim(c.nombre_calidad)) = lower(v_nombre) ORDER BY c.id LIMIT 1;
  IF v_id IS NULL THEN
    INSERT INTO public.calidad_producto(nombre_calidad) VALUES (v_nombre) RETURNING calidad_producto.id INTO v_id;
  END IF;
  INSERT INTO public.tipo_calidad_producto(id_tipo, id_calidad) VALUES (p_id_tipo, v_id) ON CONFLICT DO NOTHING;
  RETURN QUERY SELECT c.id, c.nombre_calidad FROM public.calidad_producto c WHERE c.id = v_id;
END;
$$;
REVOKE ALL ON FUNCTION public.crear_calidad_categoria(integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.crear_calidad_categoria(integer, text) TO authenticated;
COMMIT;
