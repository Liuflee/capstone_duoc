-- Convierte el identificador y sus referencias sin modificar los códigos existentes.
BEGIN;
-- Bloquea escrituras durante la conversión para mantener las referencias consistentes.
LOCK TABLE public.producto, public.detalle_venta_producto IN ACCESS EXCLUSIVE MODE;
-- Conserva el nombre y las reglas originales de cada clave foránea involucrada.
CREATE TEMP TABLE referencias_codigo_producto ON COMMIT DROP AS
SELECT conrelid::regclass::text AS tabla, conname AS nombre, pg_get_constraintdef(oid) AS definicion
FROM pg_constraint
WHERE contype = 'f' AND confrelid = 'public.producto'::regclass;
DO $$
DECLARE referencia record;
BEGIN
  FOR referencia IN SELECT * FROM referencias_codigo_producto LOOP
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', referencia.tabla, referencia.nombre);
  END LOOP;
END;
$$;
-- Ambos extremos de la relación deben aceptar códigos como SP0-01223.
ALTER TABLE public.producto ALTER COLUMN codigo_producto TYPE text USING codigo_producto::text;
ALTER TABLE public.detalle_venta_producto ALTER COLUMN codigo_producto TYPE text USING codigo_producto::text;
DO $$
DECLARE referencia record;
BEGIN
  FOR referencia IN SELECT * FROM referencias_codigo_producto LOOP
    EXECUTE format('ALTER TABLE %s ADD CONSTRAINT %I %s', referencia.tabla, referencia.nombre, referencia.definicion);
  END LOOP;
END;
$$;
-- Actualiza también el registro transaccional de ventas para aceptar el nuevo identificador.
CREATE OR REPLACE FUNCTION public.registrar_venta(
  p_rut_cliente integer,
  p_patente_vehiculo text,
  p_detalles jsonb,
  p_iva integer DEFAULT 19
)
RETURNS integer
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_id_venta integer;
  v_codigo_producto text;
  v_cantidad integer;
  v_precio integer;
  v_stock integer;
  v_detalle jsonb;
BEGIN
  IF jsonb_typeof(p_detalles) <> 'array' OR jsonb_array_length(p_detalles) = 0 THEN
    RAISE EXCEPTION 'La venta debe incluir al menos un producto.';
  END IF;

  INSERT INTO public.venta (iva, rut_cliente, patente_vehiculo)
  VALUES (p_iva, p_rut_cliente, NULLIF(p_patente_vehiculo, ''))
  RETURNING id INTO v_id_venta;

  FOR v_detalle IN SELECT value FROM jsonb_array_elements(p_detalles)
  LOOP
    v_codigo_producto := v_detalle ->> 'codigo_producto';
    v_cantidad := (v_detalle ->> 'cantidad')::integer;

    IF v_cantidad <= 0 THEN
      RAISE EXCEPTION 'La cantidad debe ser mayor que cero.';
    END IF;

    SELECT precio, stock
      INTO v_precio, v_stock
      FROM public.producto
      WHERE codigo_producto = v_codigo_producto
      FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'No existe el producto %.', v_codigo_producto;
    END IF;
    IF v_stock < v_cantidad THEN
      RAISE EXCEPTION 'Stock insuficiente para el producto %.', v_codigo_producto;
    END IF;

    UPDATE public.producto
      SET stock = stock - v_cantidad
      WHERE codigo_producto = v_codigo_producto;

    INSERT INTO public.detalle_venta_producto (
      id_venta,
      codigo_producto,
      total
    )
    VALUES (
      v_id_venta,
      v_codigo_producto,
      v_precio * v_cantidad
    );
  END LOOP;

  RETURN v_id_venta;
END;
$$;
COMMIT;
