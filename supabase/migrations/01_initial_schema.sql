-- ==============================================================================
-- EDUNEX - CRM ESCOLAR & PLATAFORMA INTEGRAL DE GESTIÓN EDUCATIVA
-- MIGRACIÓN 01: ESQUEMA BASE MULTI-TENANT, AUTENTICACIÓN Y ROLES
-- ==============================================================================

-- 1. Habilitar extensión UUID para generación de identificadores únicos
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TIPOS ENUMERADOS (ROLES Y ESTADOS)
-- ==============================================================================

-- Roles de acceso del sistema según la propuesta estratégica de EDUNEX
CREATE TYPE user_role AS ENUM (
    'superadmin',            -- Administrador de la plataforma EDUNEX SaaS
    'admin_colegio',         -- Director / Propietario del colegio
    'caja_finanzas',         -- Encargado de cobros, recibos y caja
    'admisiones',            -- Registro y matrícula de nuevos alumnos
    'coordinador_academico', -- Coordinación de grados, secciones y profesores
    'docente',               -- Profesores (asistencia, observaciones)
    'responsable_cuido',     -- Encargado del servicio de cuido / guardería
    'responsable_transporte',-- Encargado de rutas y transporte escolar
    'tienda_inventario',     -- Encargado de uniformes y materiales
    'tutor_familiar'         -- Padre, madre o tutor con cuenta familiar
);

-- Estado de suscripción de la institución educativa
CREATE TYPE subscription_status AS ENUM (
    'trial',      -- Período de prueba / piloto (primeros 5 colegios)
    'active',     -- Suscripción activa y al día
    'past_due',   -- Pago pendiente
    'suspended'   -- Suspendido por falta de pago
);

-- ==============================================================================
-- 3. TABLAS NÚCLEO MULTI-TENANT (COLEGIOS Y SUCURSALES)
-- ==============================================================================

-- Tabla principal de instituciones (Tenants)
CREATE TABLE colegios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(150) NOT NULL,
    rnc VARCHAR(20),                          -- Registro Nacional de Contribuyentes (Rep. Dom.)
    siglas VARCHAR(20),
    telefono VARCHAR(30),
    email_contacto VARCHAR(100),
    direccion TEXT,
    logo_url TEXT,
    estado_suscripcion subscription_status DEFAULT 'trial',
    max_estudiantes INT DEFAULT 300,          -- Orientado a colegios pequeños/medianos (50-300)
    configuracion JSONB DEFAULT '{}'::jsonb,  -- Parámetros personalizados del colegio
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

COMMENT ON TABLE colegios IS 'Instituciones educativas clientes de EDUNEX SaaS (Tenants)';

-- Tabla de Sucursales (Soporte multi-sucursal según la propuesta comercial)
CREATE TABLE sucursales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,            -- Ej: "Sede Principal", "Campus Norte"
    telefono VARCHAR(30),
    direccion TEXT,
    es_principal BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

COMMENT ON TABLE sucursales IS 'Sedes o recintos pertenecientes a un colegio';

-- ==============================================================================
-- 4. TABLA DE PERFILES DE USUARIO (VINCULADA A auth.users DE SUPABASE)
-- ==============================================================================

CREATE TABLE perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    colegio_id UUID REFERENCES colegios(id) ON DELETE SET NULL,
    sucursal_id UUID REFERENCES sucursales(id) ON DELETE SET NULL,
    email VARCHAR(150) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(30),
    rol user_role DEFAULT 'tutor_familiar' NOT NULL,
    avatar_url TEXT,
    activo BOOLEAN DEFAULT true NOT NULL,
    ultimo_acceso TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

COMMENT ON TABLE perfiles IS 'Datos extendidos de los usuarios registrados en Supabase Auth';

-- Índice para acelerar consultas multi-tenant por colegio
CREATE INDEX idx_perfiles_colegio ON perfiles(colegio_id);
CREATE INDEX idx_perfiles_rol ON perfiles(rol);

-- ==============================================================================
-- 5. FUNCIONES AUXILIARES PARA ROW LEVEL SECURITY (RLS)
-- ==============================================================================

-- Función para obtener el colegio_id del usuario autenticado
CREATE OR REPLACE FUNCTION get_auth_colegio_id()
RETURNS UUID AS $$
    SELECT colegio_id FROM perfiles WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Función para obtener el rol del usuario autenticado
CREATE OR REPLACE FUNCTION get_auth_user_role()
RETURNS user_role AS $$
    SELECT rol FROM perfiles WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ==============================================================================
-- 6. POLÍTICAS DE SEGURIDAD A NIVEL DE FILA (RLS)
-- ==============================================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE colegios ENABLE ROW LEVEL SECURITY;
ALTER TABLE sucursales ENABLE ROW LEVEL SECURITY;
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;

-- Políticas para 'colegios'
CREATE POLICY "Superadmin tiene acceso total a colegios"
    ON colegios FOR ALL
    USING (get_auth_user_role() = 'superadmin');

CREATE POLICY "Usuarios pueden ver su propio colegio"
    ON colegios FOR SELECT
    USING (id = get_auth_colegio_id());

CREATE POLICY "Admin del colegio puede actualizar su colegio"
    ON colegios FOR UPDATE
    USING (id = get_auth_colegio_id() AND get_auth_user_role() = 'admin_colegio');

-- Políticas para 'sucursales'
CREATE POLICY "Usuarios ven las sucursales de su colegio"
    ON sucursales FOR SELECT
    USING (colegio_id = get_auth_colegio_id() OR get_auth_user_role() = 'superadmin');

CREATE POLICY "Admin del colegio gestiona sus sucursales"
    ON sucursales FOR ALL
    USING (colegio_id = get_auth_colegio_id() AND get_auth_user_role() IN ('admin_colegio', 'superadmin'));

-- Políticas para 'perfiles'
CREATE POLICY "Usuarios pueden ver y editar su propio perfil"
    ON perfiles FOR ALL
    USING (id = auth.uid());

CREATE POLICY "Administradores pueden ver perfiles de su colegio"
    ON perfiles FOR SELECT
    USING (
        (colegio_id = get_auth_colegio_id() AND get_auth_user_role() IN ('admin_colegio', 'caja_finanzas', 'admisiones'))
        OR get_auth_user_role() = 'superadmin'
    );

CREATE POLICY "Admin del colegio puede crear y modificar perfiles de su colegio"
    ON perfiles FOR INSERT
    WITH CHECK (
        (colegio_id = get_auth_colegio_id() AND get_auth_user_role() = 'admin_colegio')
        OR get_auth_user_role() = 'superadmin'
    );

-- ==============================================================================
-- 7. TRIGGER AUTOMÁTICO AL REGISTRAR UN USUARIO EN SUPABASE AUTH
-- ==============================================================================

-- Sincroniza automáticamente nuevos registros en auth.users con la tabla perfiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
    default_colegio_id UUID;
BEGIN
    -- Si viene en los metadatos de auth el colegio_id, se asocia
    default_colegio_id := (NEW.raw_user_meta_data->>'colegio_id')::uuid;

    INSERT INTO public.perfiles (
        id,
        email,
        nombres,
        apellidos,
        rol,
        colegio_id
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'nombres', 'Usuario'),
        COALESCE(NEW.raw_user_meta_data->>'apellidos', 'EDUNEX'),
        COALESCE((NEW.raw_user_meta_data->>'rol')::user_role, 'tutor_familiar'),
        default_colegio_id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Disparador en auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 8. DATOS SEMILLA PARA PRUEBAS Y PILOTO (SEED DATA)
-- ==============================================================================

-- Insertar colegio piloto para validación inicial
INSERT INTO colegios (id, nombre, rnc, siglas, telefono, email_contacto, direccion, estado_suscripcion)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'Colegio Bilingüe EDUNEX Piloto',
    '131-00000-1',
    'CBEDUNEX',
    '809-555-0199',
    'contacto@edunexpiloto.edu.do',
    'Av. 27 de Febrero #123, Distrito Nacional, Santo Domingo',
    'trial'
) ON CONFLICT (id) DO NOTHING;

-- Insertar sucursal principal
INSERT INTO sucursales (id, colegio_id, nombre, telefono, direccion, es_principal)
VALUES (
    'b0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'Campus Principal Santo Domingo',
    '809-555-0199',
    'Av. 27 de Febrero #123, Distrito Nacional, Santo Domingo',
    true
) ON CONFLICT (id) DO NOTHING;
