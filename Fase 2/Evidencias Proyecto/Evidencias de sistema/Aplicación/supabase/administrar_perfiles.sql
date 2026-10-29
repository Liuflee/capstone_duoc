-- Permite retirar perfiles desde las vistas de gestión sin cambiar las tablas del negocio ni el login.
CREATE OR REPLACE FUNCTION public.eliminar_perfil_administrado(p_user_id uuid, p_rol text) -- Recibe el perfil y la sección que el dueño confirmó.
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$ -- Ejecuta únicamente esta operación controlada en el servidor.
BEGIN -- Comprueba la identidad y protege la continuidad de acceso.
  IF auth.uid() IS NULL OR public.rol_actual() IS DISTINCT FROM 'administrador' THEN -- Exige un dueño autenticado.
    RAISE EXCEPTION 'Solo el dueño puede administrar perfiles.' USING ERRCODE = '42501'; -- Rechaza llamadas sin autorización.
  END IF; -- Finaliza el permiso del solicitante.
  IF p_user_id = auth.uid() THEN -- No permite retirar la propia sesión.
    RAISE EXCEPTION 'No puedes eliminar tu propio perfil.'; -- Conserva el acceso del solicitante.
  END IF; -- Finaliza la protección del perfil actual.
  IF p_rol IS NULL OR p_rol NOT IN ('administrador', 'empleado') THEN -- Acepta únicamente los roles existentes.
    RAISE EXCEPTION 'Tipo de perfil inválido.'; -- Impide operar sobre una sección desconocida.
  END IF; -- Finaliza la validación de sección.
  LOCK TABLE public.perfil_usuario IN SHARE ROW EXCLUSIVE MODE; -- Serializa cambios para proteger al último dueño.
  IF NOT EXISTS (SELECT 1 FROM public.perfil_usuario WHERE user_id = auth.uid() AND rol = 'administrador') THEN -- Revalida el rol después de esperar por cambios concurrentes.
    RAISE EXCEPTION 'El solicitante ya no tiene un perfil de dueño.' USING ERRCODE = '42501'; -- Rechaza una sesión cuyo acceso se retiró durante la solicitud.
  END IF; -- Finaliza la segunda comprobación del permiso.
  IF NOT EXISTS (SELECT 1 FROM public.perfil_usuario WHERE user_id = p_user_id AND rol = p_rol) THEN -- Comprueba la pertenencia actual del perfil.
    RAISE EXCEPTION 'El perfil ya no existe en la sección seleccionada.'; -- No anuncia la eliminación de un perfil inexistente.
  END IF; -- Finaliza la validación del registro.
  IF p_rol = 'administrador' AND (SELECT count(*) FROM public.perfil_usuario WHERE rol = 'administrador') <= 1 THEN -- Conserva al menos un dueño.
    RAISE EXCEPTION 'No se puede eliminar el último dueño.'; -- Evita dejar la aplicación sin administrador.
  END IF; -- Finaliza la protección de administración.
  DELETE FROM public.perfil_usuario WHERE user_id = p_user_id AND rol = p_rol; -- Retira el acceso del perfil confirmado, sin borrar la cuenta Auth ni los datos del negocio.
END; $$; -- Finaliza la operación protegida.
REVOKE ALL ON FUNCTION public.eliminar_perfil_administrado(uuid, text) FROM PUBLIC, anon; -- Evita que visitantes sin sesión puedan ejecutar la función.
GRANT EXECUTE ON FUNCTION public.eliminar_perfil_administrado(uuid, text) TO authenticated; -- La función comprueba el rol de cada solicitante.
