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
  v_codigo_producto integer;
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
    v_codigo_producto := (v_detalle ->> 'codigo_producto')::integer;
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