-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.cliente (
  rut integer NOT NULL,
  nombre character varying NOT NULL,
  fono integer NOT NULL,
  CONSTRAINT cliente_pkey PRIMARY KEY (rut)
);
CREATE TABLE public.vehiculo_cliente (
  patente character varying NOT NULL,
  kilometraje numeric NOT NULL,
  id_modelo integer NOT NULL,
  rut_cliente integer NOT NULL,
  CONSTRAINT vehiculo_cliente_pkey PRIMARY KEY (patente),
  CONSTRAINT vehiculo_cliente_rut_cliente_fkey FOREIGN KEY (rut_cliente) REFERENCES public.cliente(rut),
  CONSTRAINT vehiculo_cliente_id_modelo_fkey FOREIGN KEY (id_modelo) REFERENCES public.modelo_vehiculo(id)
);
CREATE TABLE public.venta (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  iva integer NOT NULL,
  rut_cliente integer NOT NULL,
  patente_vehiculo character varying,
  fecha_registro date DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'America/Santiago'::text))::date,
  CONSTRAINT venta_pkey PRIMARY KEY (id),
  CONSTRAINT venta_rut_cliente_fkey FOREIGN KEY (rut_cliente) REFERENCES public.cliente(rut),
  CONSTRAINT venta_patente_vehiculo_fkey FOREIGN KEY (patente_vehiculo) REFERENCES public.vehiculo_cliente(patente)
);
CREATE TABLE public.marca_vehiculo (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  marca character varying NOT NULL,
  CONSTRAINT marca_vehiculo_pkey PRIMARY KEY (id)
);
CREATE TABLE public.modelo_vehiculo (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  modelo character varying NOT NULL,
  id_marca integer NOT NULL,
  CONSTRAINT modelo_vehiculo_pkey PRIMARY KEY (id),
  CONSTRAINT modelo_vehiculo_id_marca_fkey FOREIGN KEY (id_marca) REFERENCES public.marca_vehiculo(id)
);
CREATE TABLE public.producto (
  codigo_producto text NOT NULL,
  cod_barra character varying,
  stock integer NOT NULL,
  medida character varying,
  calidad integer,
  tipo integer,
  precio integer NOT NULL,
  CONSTRAINT producto_pkey PRIMARY KEY (codigo_producto),
  CONSTRAINT producto_tipo_calidad_fkey FOREIGN KEY (tipo) REFERENCES public.tipo_calidad_producto(id_tipo),
  CONSTRAINT producto_tipo_calidad_fkey FOREIGN KEY (calidad) REFERENCES public.tipo_calidad_producto(id_calidad),
  CONSTRAINT producto_calidad_fkey FOREIGN KEY (calidad) REFERENCES public.calidad_producto(id),
  CONSTRAINT producto_tipo_fkey FOREIGN KEY (tipo) REFERENCES public.tipo_producto(id)
);
CREATE TABLE public.tipo_producto (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre_tipo character varying NOT NULL,
  CONSTRAINT tipo_producto_pkey PRIMARY KEY (id)
);
CREATE TABLE public.calidad_producto (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  nombre_calidad character varying NOT NULL,
  CONSTRAINT calidad_producto_pkey PRIMARY KEY (id)
);
CREATE TABLE public.servicio (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  descripcion character varying NOT NULL,
  costo integer NOT NULL,
  CONSTRAINT servicio_pkey PRIMARY KEY (id)
);
CREATE TABLE public.detalle_venta_producto (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_venta integer NOT NULL,
  codigo_producto text NOT NULL,
  total integer NOT NULL,
  CONSTRAINT detalle_venta_producto_pkey PRIMARY KEY (id),
  CONSTRAINT detalle_venta_producto_codigo_producto_fkey FOREIGN KEY (codigo_producto) REFERENCES public.producto(codigo_producto),
  CONSTRAINT detalle_venta_producto_id_venta_fkey FOREIGN KEY (id_venta) REFERENCES public.venta(id)
);
CREATE TABLE public.detalle_venta_servicio (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  id_venta integer NOT NULL,
  id_servicio integer NOT NULL,
  total integer NOT NULL,
  CONSTRAINT detalle_venta_servicio_pkey PRIMARY KEY (id),
  CONSTRAINT detalle_venta_servicio_id_servicio_fkey FOREIGN KEY (id_servicio) REFERENCES public.servicio(id),
  CONSTRAINT detalle_venta_servicio_id_venta_fkey FOREIGN KEY (id_venta) REFERENCES public.venta(id)
);
CREATE TABLE public.perfil_usuario (
  user_id uuid NOT NULL,
  nombre text NOT NULL,
  rol text NOT NULL DEFAULT 'empleado'::text CHECK (rol = ANY (ARRAY['administrador'::text, 'empleado'::text])),
  creado_en timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT perfil_usuario_pkey PRIMARY KEY (user_id),
  CONSTRAINT perfil_usuario_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.tipo_calidad_producto (
  id_tipo integer NOT NULL,
  id_calidad integer NOT NULL,
  CONSTRAINT tipo_calidad_producto_pkey PRIMARY KEY (id_tipo, id_calidad),
  CONSTRAINT tipo_calidad_producto_id_tipo_fkey FOREIGN KEY (id_tipo) REFERENCES public.tipo_producto(id),
  CONSTRAINT tipo_calidad_producto_id_calidad_fkey FOREIGN KEY (id_calidad) REFERENCES public.calidad_producto(id)
);
CREATE TABLE public.reserva_producto (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  codigo_producto text NOT NULL CHECK (length(btrim(codigo_producto)) > 0),
  rut_cliente integer NOT NULL,
  estado text NOT NULL DEFAULT 'reservado'::text CHECK (estado = ANY (ARRAY['reservado'::text, 'lista'::text])),
  fecha_registro timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT reserva_producto_pkey PRIMARY KEY (id),
  CONSTRAINT reserva_producto_rut_cliente_fkey FOREIGN KEY (rut_cliente) REFERENCES public.cliente(rut)
);