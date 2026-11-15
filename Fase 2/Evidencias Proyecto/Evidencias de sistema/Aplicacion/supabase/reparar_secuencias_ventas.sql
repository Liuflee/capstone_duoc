-- Ejecutar en el editor SQL de Supabase con una cuenta administradora.
-- Corrige contadores desactualizados después de importar registros con IDs explícitos.
BEGIN;
-- Evita nuevas inserciones mientras se sincronizan los ventas y detalles.
LOCK TABLE public.venta, public.detalle_venta_producto, public.detalle_venta_servicio IN ACCESS EXCLUSIVE MODE;
DO $$
DECLARE
  tabla text; -- Recorre los registros que generan su ID automáticamente.
  secuencia text; -- Conserva la secuencia real, sin suponer su nombre.
  maximo bigint; -- Conserva el mayor ID guardado.
  ultimo bigint; -- Evita retroceder una secuencia que ya esté más adelantada.
BEGIN
  FOREACH tabla IN ARRAY ARRAY['venta', 'detalle_venta_producto', 'detalle_venta_servicio'] LOOP
    secuencia := pg_get_serial_sequence(format('public.%I', tabla), 'id');
    IF secuencia IS NULL THEN
      RAISE EXCEPTION 'El catálogo % no tiene una secuencia automática para id.', tabla;
    END IF;
    EXECUTE format('SELECT COALESCE(MAX(id), 0) FROM public.%I', tabla) INTO maximo;
    EXECUTE format('SELECT last_value FROM %s', secuencia::regclass) INTO ultimo;
    -- El siguiente ID será mayor que los existentes y que el contador actual.
    PERFORM setval(secuencia::regclass, GREATEST(maximo, ultimo, 1), true);
  END LOOP;
END;
$$;
COMMIT;
