-- Ejecutar después de autenticacion_perfiles.sql y eliminacion_logica_productos.sql.
-- Las tablas maestras conservan sus referencias e historial mediante baja lógica.
BEGIN;

ALTER TABLE public.cliente ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true;
ALTER TABLE public.vehiculo_cliente ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true;
ALTER TABLE public.marca_vehiculo ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true;
ALTER TABLE public.modelo_vehiculo ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true;
ALTER TABLE public.tipo_producto ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true;
ALTER TABLE public.calidad_producto ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true;
ALTER TABLE public.servicio ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true;

-- La política anterior permitía DELETE a cualquier empleado. Separa permisos CRUD.
DO $$
DECLARE tabla text;
  tablas text[] := ARRAY[
    'cliente', 'vehiculo_cliente', 'venta', 'marca_vehiculo', 'modelo_vehiculo',
    'producto', 'tipo_producto', 'calidad_producto', 'servicio',
    'detalle_venta_producto', 'detalle_venta_servicio'
  ];
BEGIN
  FOREACH tabla IN ARRAY tablas LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tabla);
    EXECUTE format('DROP POLICY IF EXISTS empleados_y_administradores ON public.%I', tabla);
    EXECUTE format('DROP POLICY IF EXISTS empleados_consultar ON public.%I', tabla);
    EXECUTE format('DROP POLICY IF EXISTS empleados_insertar ON public.%I', tabla);
    EXECUTE format('DROP POLICY IF EXISTS empleados_actualizar ON public.%I', tabla);
    EXECUTE format('DROP POLICY IF EXISTS solo_administrador_eliminar ON public.%I', tabla);
    EXECUTE format('CREATE POLICY empleados_consultar ON public.%I FOR SELECT TO authenticated USING ((SELECT public.rol_actual()) IN (''administrador'', ''empleado''))', tabla);
    EXECUTE format('CREATE POLICY empleados_insertar ON public.%I FOR INSERT TO authenticated WITH CHECK ((SELECT public.rol_actual()) IN (''administrador'', ''empleado''))', tabla);
    EXECUTE format('CREATE POLICY empleados_actualizar ON public.%I FOR UPDATE TO authenticated USING ((SELECT public.rol_actual()) IN (''administrador'', ''empleado'')) WITH CHECK ((SELECT public.rol_actual()) IN (''administrador'', ''empleado''))', tabla);
    EXECUTE format('CREATE POLICY solo_administrador_eliminar ON public.%I FOR DELETE TO authenticated USING ((SELECT public.rol_actual()) = ''administrador'')', tabla);
  END LOOP;
END;
$$;

-- La relación de categoría y calidad se instala mediante una migración opcional.
DO $$
BEGIN
  IF to_regclass('public.tipo_calidad_producto') IS NOT NULL THEN
    ALTER TABLE public.tipo_calidad_producto ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS empleados_y_administradores ON public.tipo_calidad_producto;
    DROP POLICY IF EXISTS empleados_consultar ON public.tipo_calidad_producto;
    DROP POLICY IF EXISTS empleados_insertar ON public.tipo_calidad_producto;
    DROP POLICY IF EXISTS solo_administrador_eliminar ON public.tipo_calidad_producto;
    CREATE POLICY empleados_consultar ON public.tipo_calidad_producto FOR SELECT TO authenticated USING ((SELECT public.rol_actual()) IN ('administrador', 'empleado'));
    CREATE POLICY empleados_insertar ON public.tipo_calidad_producto FOR INSERT TO authenticated WITH CHECK ((SELECT public.rol_actual()) IN ('administrador', 'empleado'));
    CREATE POLICY solo_administrador_eliminar ON public.tipo_calidad_producto FOR DELETE TO authenticated USING ((SELECT public.rol_actual()) = 'administrador');
  END IF;
END;
$$;

-- La tabla de reservas se instala como una migración opcional del proyecto.
DO $$
BEGIN
  IF to_regclass('public.reserva_producto') IS NOT NULL THEN
    GRANT DELETE ON public.reserva_producto TO authenticated;
    DROP POLICY IF EXISTS solo_administrador_eliminar ON public.reserva_producto;
    EXECUTE 'CREATE POLICY solo_administrador_eliminar ON public.reserva_producto FOR DELETE TO authenticated USING ((SELECT public.rol_actual()) = ''administrador'')';
  END IF;
END;
$$;

-- Evita que un empleado convierta una baja lógica en una actualización ordinaria.
CREATE OR REPLACE FUNCTION public.proteger_baja_logica_administrador()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
BEGIN
  IF OLD.activo IS TRUE AND NEW.activo IS FALSE
     AND (SELECT public.rol_actual()) IS DISTINCT FROM 'administrador' THEN
    RAISE EXCEPTION 'Solo un administrador puede eliminar registros.' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.proteger_baja_logica_administrador() FROM PUBLIC, anon, authenticated;
DO $$
DECLARE tabla text;
  tablas text[] := ARRAY[
    'cliente', 'vehiculo_cliente', 'marca_vehiculo', 'modelo_vehiculo',
    'producto', 'tipo_producto', 'calidad_producto', 'servicio'
  ];
BEGIN
  FOREACH tabla IN ARRAY tablas LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS proteger_baja_logica ON public.%I', tabla);
    EXECUTE format('CREATE TRIGGER proteger_baja_logica BEFORE UPDATE OF activo ON public.%I FOR EACH ROW EXECUTE FUNCTION public.proteger_baja_logica_administrador()', tabla);
  END LOOP;
END;
$$;

COMMIT;
