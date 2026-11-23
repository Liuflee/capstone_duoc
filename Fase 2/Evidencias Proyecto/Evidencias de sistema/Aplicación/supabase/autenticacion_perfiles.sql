CREATE TABLE IF NOT EXISTS public.perfil_usuario (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  nombre text NOT NULL,
  rol text NOT NULL DEFAULT 'empleado'
    CHECK (rol IN ('administrador', 'empleado')),
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.crear_perfil_usuario()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.perfil_usuario (user_id, nombre, rol)
  VALUES (
    NEW.id,
    COALESCE(
      NULLIF(BTRIM(NEW.raw_user_meta_data ->> 'nombre'), ''),
      NULLIF(SPLIT_PART(COALESCE(NEW.email, ''), '@', 1), ''),
      'Usuario'
    ),
    'empleado'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS crear_perfil_despues_de_registro ON auth.users;
CREATE TRIGGER crear_perfil_despues_de_registro
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.crear_perfil_usuario();

INSERT INTO public.perfil_usuario (user_id, nombre, rol)
SELECT
  u.id,
  COALESCE(
    NULLIF(BTRIM(u.raw_user_meta_data ->> 'nombre'), ''),
    NULLIF(SPLIT_PART(COALESCE(u.email, ''), '@', 1), ''),
    'Usuario'
  ),
  'empleado'
FROM auth.users AS u
ON CONFLICT (user_id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.rol_actual()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT p.rol
  FROM public.perfil_usuario AS p
  WHERE p.user_id = (SELECT auth.uid())
$$;

REVOKE ALL ON FUNCTION public.rol_actual() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rol_actual() TO authenticated;
REVOKE ALL ON FUNCTION public.crear_perfil_usuario() FROM PUBLIC, anon,
  authenticated;

ALTER TABLE public.perfil_usuario ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS perfil_usuario_consultar ON public.perfil_usuario;
CREATE POLICY perfil_usuario_consultar
  ON public.perfil_usuario
  FOR SELECT
  TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR (SELECT public.rol_actual()) = 'administrador'
  );

DROP POLICY IF EXISTS perfil_usuario_administrar ON public.perfil_usuario;
CREATE POLICY perfil_usuario_administrar
  ON public.perfil_usuario
  FOR UPDATE
  TO authenticated
  USING ((SELECT public.rol_actual()) = 'administrador')
  WITH CHECK ((SELECT public.rol_actual()) = 'administrador');

REVOKE ALL ON public.perfil_usuario FROM anon;
GRANT SELECT, UPDATE ON public.perfil_usuario TO authenticated;

DO $$
DECLARE
  tabla text;
  tablas text[] := ARRAY[
    'cliente',
    'vehiculo_cliente',
    'venta',
    'marca_vehiculo',
    'modelo_vehiculo',
    'producto',
    'tipo_producto',
    'calidad_producto',
    'servicio',
    'detalle_venta_producto',
    'detalle_venta_servicio'
  ];
BEGIN
  FOREACH tabla IN ARRAY tablas
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tabla);
    EXECUTE format(
      'DROP POLICY IF EXISTS empleados_y_administradores ON public.%I',
      tabla
    );
    EXECUTE format(
      'CREATE POLICY empleados_y_administradores ON public.%I '
      'FOR ALL TO authenticated '
      'USING ((SELECT public.rol_actual()) IN (''administrador'', ''empleado'')) '
      'WITH CHECK ((SELECT public.rol_actual()) IN (''administrador'', ''empleado''))',
      tabla
    );
  END LOOP;
END;
$$;

DO $$
BEGIN
  IF to_regprocedure(
    'public.registrar_venta(integer,text,jsonb,integer)'
  ) IS NOT NULL THEN
    EXECUTE
      'REVOKE EXECUTE ON FUNCTION '
      'public.registrar_venta(integer, text, jsonb, integer) '
      'FROM PUBLIC, anon';
    EXECUTE
      'GRANT EXECUTE ON FUNCTION '
      'public.registrar_venta(integer, text, jsonb, integer) '
      'TO authenticated';
  END IF;
END;
$$;
