-- ==============================================================================
-- EDUNEX - CRM ESCOLAR & PLATAFORMA INTEGRAL DE GESTIÓN EDUCATIVA
-- MIGRACIÓN 02: TABLAS NÚCLEO (CUENTA FAMILIAR, FINANZAS, SERVICIOS Y ACADÉMICO)
-- ==============================================================================

-- ==============================================================================
-- 1. TIPOS ENUMERADOS DE ESTADOS
-- ==============================================================================

CREATE TYPE estado_cargo AS ENUM ('pendiente', 'parcial', 'pagado', 'anulado');
CREATE TYPE metodo_pago AS ENUM ('transferencia', 'tarjeta', 'efectivo', 'cheque', 'otro');
CREATE TYPE estado_pago AS ENUM ('en_revision', 'aprobado', 'rechazado', 'anulado');
CREATE TYPE tipo_servicio AS ENUM ('cuido', 'transporte', 'tienda', 'evento', 'colegiatura', 'matricula', 'otro');

-- ==============================================================================
-- 2. FAMILIAS Y TUTORES (NÚCLEO: CUENTA FAMILIAR ÚNICA)
-- ==============================================================================

CREATE TABLE familias (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    codigo_familia VARCHAR(30) NOT NULL,              -- Ej: "FAM-2026-001"
    nombre_familia VARCHAR(150) NOT NULL,             -- Ej: "Familia Pérez González"
    balance_pendiente NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    telefono_principal VARCHAR(30),
    email_principal VARCHAR(100),
    direccion TEXT,
    activo BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT uq_familia_colegio_codigo UNIQUE (colegio_id, codigo_familia)
);

COMMENT ON TABLE familias IS 'Cuentas familiares únicas que centralizan estudiantes, cobros y servicios';

CREATE TABLE tutores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    familia_id UUID NOT NULL REFERENCES familias(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES perfiles(id) ON DELETE SET NULL, -- Vinculado al usuario autenticado
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    parentesco VARCHAR(50) NOT NULL,                 -- Padre, Madre, Tutor Legal, Abuelo
    cedula_o_pasaporte VARCHAR(30),
    telefono VARCHAR(30),
    email VARCHAR(100),
    es_contacto_principal BOOLEAN DEFAULT false NOT NULL,
    autorizado_recoger BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 3. ESTRUCTURA ACADÉMICA Y ESTUDIANTES
-- ==============================================================================

CREATE TABLE grados (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    nombre VARCHAR(80) NOT NULL,                     -- Ej: "1ro de Primaria", "Maternal", "Kinder"
    nivel VARCHAR(50),                               -- Inicial, Primaria, Secundaria
    orden INT DEFAULT 1
);

CREATE TABLE secciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grado_id UUID NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
    nombre VARCHAR(30) NOT NULL,                     -- Ej: "A", "B", "Única"
    capacidad INT DEFAULT 25
);

CREATE TABLE estudiantes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    sucursal_id UUID REFERENCES sucursales(id) ON DELETE SET NULL,
    familia_id UUID NOT NULL REFERENCES familias(id) ON DELETE CASCADE,
    matricula VARCHAR(30) NOT NULL,                  -- Código de estudiante
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero VARCHAR(20),
    seccion_id UUID REFERENCES secciones(id) ON DELETE SET NULL,
    foto_url TEXT,
    condiciones_medicas TEXT,
    activo BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT uq_estudiante_colegio_matricula UNIQUE (colegio_id, matricula)
);

COMMENT ON TABLE estudiantes IS 'Expediente digital del estudiante vinculado a su cuenta familiar';

CREATE TABLE documentos_estudiante (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estudiante_id UUID NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    tipo VARCHAR(80) NOT NULL,                       -- Acta de nacimiento, Vacunas, Foto 2x2
    archivo_url TEXT NOT NULL,
    aprobado BOOLEAN DEFAULT false NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 4. MOTOR FINANCIERO CONSOLIDADO (CARGOS, PAGOS Y RECIBOS)
-- ==============================================================================

CREATE TABLE conceptos_cobro (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    nombre VARCHAR(120) NOT NULL,                    -- "Colegiatura Mensual", "Inscripción 2026-2027", etc.
    tipo tipo_servicio NOT NULL,
    monto_sugerido NUMERIC(10, 2) NOT NULL,
    activo BOOLEAN DEFAULT true NOT NULL
);

CREATE TABLE cargos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    familia_id UUID NOT NULL REFERENCES familias(id) ON DELETE CASCADE,
    estudiante_id UUID REFERENCES estudiantes(id) ON DELETE SET NULL,
    concepto_id UUID REFERENCES conceptos_cobro(id) ON DELETE SET NULL,
    descripcion VARCHAR(200) NOT NULL,
    monto NUMERIC(10, 2) NOT NULL,
    monto_pagado NUMERIC(10, 2) DEFAULT 0.00 NOT NULL,
    fecha_emision DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_vencimiento DATE NOT NULL,
    estado estado_cargo DEFAULT 'pendiente' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

COMMENT ON TABLE cargos IS 'Obligaciones financieras consolidadas en la cuenta familiar';

CREATE TABLE pagos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    familia_id UUID NOT NULL REFERENCES familias(id) ON DELETE CASCADE,
    monto_total NUMERIC(10, 2) NOT NULL,
    metodo metodo_pago DEFAULT 'transferencia' NOT NULL,
    referencia VARCHAR(100),                         -- Número de autorización o transferencia
    comprobante_url TEXT,                            -- Imagen del voucher bancario
    estado estado_pago DEFAULT 'aprobado' NOT NULL,
    recibido_por UUID REFERENCES perfiles(id) ON DELETE SET NULL,
    fecha_pago TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    notas TEXT
);

CREATE TABLE pagos_detalle (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pago_id UUID NOT NULL REFERENCES pagos(id) ON DELETE CASCADE,
    cargo_id UUID NOT NULL REFERENCES cargos(id) ON DELETE CASCADE,
    monto_aplicado NUMERIC(10, 2) NOT NULL
);

CREATE TABLE recibos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    pago_id UUID NOT NULL REFERENCES pagos(id) ON DELETE CASCADE,
    numero_recibo VARCHAR(50) NOT NULL,              -- Formato correlativo ej. "REC-2026-00045"
    fecha_emision TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    pdf_url TEXT,
    CONSTRAINT uq_colegio_numero_recibo UNIQUE (colegio_id, numero_recibo)
);

-- ==============================================================================
-- 5. SERVICIOS FACTURABLES: CUIDO Y TRANSPORTE
-- ==============================================================================

CREATE TABLE servicios_cuido (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,                    -- Ej: "Cuido Tarde (3:00 - 6:00 PM)"
    horario VARCHAR(60) NOT NULL,
    edad_min INT DEFAULT 2,
    edad_max INT DEFAULT 12,
    precio_mensual NUMERIC(10, 2) NOT NULL,
    cupo_maximo INT DEFAULT 30,
    activo BOOLEAN DEFAULT true NOT NULL
);

CREATE TABLE contrataciones_cuido (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estudiante_id UUID NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    servicio_id UUID NOT NULL REFERENCES servicios_cuido(id) ON DELETE CASCADE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    activo BOOLEAN DEFAULT true NOT NULL
);

CREATE TABLE rutas_transporte (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    nombre_ruta VARCHAR(100) NOT NULL,               -- Ej: "Ruta 1 - Naco / Piantini"
    tipo VARCHAR(50) DEFAULT 'propio',               -- propio o subcontratado
    chofer_nombre VARCHAR(100),
    chofer_telefono VARCHAR(30),
    precio_mensual NUMERIC(10, 2) NOT NULL,
    cupo_maximo INT DEFAULT 20,
    activo BOOLEAN DEFAULT true NOT NULL
);

CREATE TABLE asignaciones_transporte (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estudiante_id UUID NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    ruta_id UUID NOT NULL REFERENCES rutas_transporte(id) ON DELETE CASCADE,
    parada_direccion TEXT,
    horario_recogida VARCHAR(30),
    activo BOOLEAN DEFAULT true NOT NULL
);

-- ==============================================================================
-- 6. TIENDA DE UNIFORMES Y MATERIALES
-- ==============================================================================

CREATE TABLE productos_tienda (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    nombre VARCHAR(120) NOT NULL,                    -- "Polo Institucional", "Falda / Pantalón"
    categoria VARCHAR(60) NOT NULL,                  -- Uniforme, Libro, Accesorio
    talla_o_variante VARCHAR(30),                    -- 6, 8, 10, S, M, L
    precio NUMERIC(10, 2) NOT NULL,
    stock INT DEFAULT 0 NOT NULL,
    imagen_url TEXT,
    activo BOOLEAN DEFAULT true NOT NULL
);

CREATE TABLE pedidos_tienda (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    familia_id UUID NOT NULL REFERENCES familias(id) ON DELETE CASCADE,
    total NUMERIC(10, 2) NOT NULL,
    estado VARCHAR(30) DEFAULT 'pendiente' NOT NULL, -- pendiente, entregado, cancelado
    fecha_pedido TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 7. EVENTOS Y ACTIVIDADES
-- ==============================================================================

CREATE TABLE eventos_actividades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    titulo VARCHAR(150) NOT NULL,
    descripcion TEXT,
    fecha_evento DATE NOT NULL,
    hora VARCHAR(30),
    precio NUMERIC(10, 2) DEFAULT 0.00 NOT NULL,
    cupo_maximo INT,
    fecha_limite_inscripcion DATE,
    activo BOOLEAN DEFAULT true NOT NULL
);

CREATE TABLE inscripciones_eventos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    evento_id UUID NOT NULL REFERENCES eventos_actividades(id) ON DELETE CASCADE,
    estudiante_id UUID NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    cargo_id UUID REFERENCES cargos(id) ON DELETE SET NULL,
    fecha_inscripcion TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT uq_evento_estudiante UNIQUE (evento_id, estudiante_id)
);

-- ==============================================================================
-- 8. COMUNICACIONES Y CIRCULARES
-- ==============================================================================

CREATE TABLE comunicaciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    colegio_id UUID NOT NULL REFERENCES colegios(id) ON DELETE CASCADE,
    titulo VARCHAR(150) NOT NULL,
    contenido TEXT NOT NULL,
    prioridad VARCHAR(20) DEFAULT 'normal',          -- normal, urgente, informativa
    grado_id UUID REFERENCES grados(id) ON DELETE SET NULL, -- Null = todo el colegio
    publicado_por UUID REFERENCES perfiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 9. HABILITACIÓN DE RLS EN TODAS LAS NUEVAS TABLAS
-- ==============================================================================

ALTER TABLE familias ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutores ENABLE ROW LEVEL SECURITY;
ALTER TABLE grados ENABLE ROW LEVEL SECURITY;
ALTER TABLE secciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE estudiantes ENABLE ROW LEVEL SECURITY;
ALTER TABLE documentos_estudiante ENABLE ROW LEVEL SECURITY;
ALTER TABLE conceptos_cobro ENABLE ROW LEVEL SECURITY;
ALTER TABLE cargos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos_detalle ENABLE ROW LEVEL SECURITY;
ALTER TABLE recibos ENABLE ROW LEVEL SECURITY;
ALTER TABLE servicios_cuido ENABLE ROW LEVEL SECURITY;
ALTER TABLE contrataciones_cuido ENABLE ROW LEVEL SECURITY;
ALTER TABLE rutas_transporte ENABLE ROW LEVEL SECURITY;
ALTER TABLE asignaciones_transporte ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos_tienda ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos_tienda ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos_actividades ENABLE ROW LEVEL SECURITY;
ALTER TABLE inscripciones_eventos ENABLE ROW LEVEL SECURITY;
ALTER TABLE comunicaciones ENABLE ROW LEVEL SECURITY;

-- Políticas de aislamiento multi-tenant por colegio
CREATE POLICY "Acceso a familias por colegio" ON familias FOR ALL
    USING (colegio_id = get_auth_colegio_id() OR get_auth_user_role() = 'superadmin');

CREATE POLICY "Acceso a estudiantes por colegio" ON estudiantes FOR ALL
    USING (colegio_id = get_auth_colegio_id() OR get_auth_user_role() = 'superadmin');

CREATE POLICY "Acceso a cargos por colegio" ON cargos FOR ALL
    USING (colegio_id = get_auth_colegio_id() OR get_auth_user_role() = 'superadmin');

CREATE POLICY "Acceso a pagos por colegio" ON pagos FOR ALL
    USING (colegio_id = get_auth_colegio_id() OR get_auth_user_role() = 'superadmin');

CREATE POLICY "Acceso a servicios_cuido por colegio" ON servicios_cuido FOR ALL
    USING (colegio_id = get_auth_colegio_id() OR get_auth_user_role() = 'superadmin');

CREATE POLICY "Acceso a rutas_transporte por colegio" ON rutas_transporte FOR ALL
    USING (colegio_id = get_auth_colegio_id() OR get_auth_user_role() = 'superadmin');

CREATE POLICY "Acceso a productos_tienda por colegio" ON productos_tienda FOR ALL
    USING (colegio_id = get_auth_colegio_id() OR get_auth_user_role() = 'superadmin');

CREATE POLICY "Acceso a eventos por colegio" ON eventos_actividades FOR ALL
    USING (colegio_id = get_auth_colegio_id() OR get_auth_user_role() = 'superadmin');

CREATE POLICY "Acceso a comunicaciones por colegio" ON comunicaciones FOR ALL
    USING (colegio_id = get_auth_colegio_id() OR get_auth_user_role() = 'superadmin');

-- ==============================================================================
-- 10. DATOS SEMILLA PARA EL COLEGIO PILOTO (SEED DATA MVP)
-- ==============================================================================

-- Conceptos de Cobro iniciales
INSERT INTO conceptos_cobro (colegio_id, nombre, tipo, monto_sugerido)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Colegiatura Mensual', 'colegiatura', 7500.00),
    ('a0000000-0000-0000-0000-000000000001', 'Inscripción Anual', 'matricula', 12000.00),
    ('a0000000-0000-0000-0000-000000000001', 'Servicio Cuido Tarde', 'cuido', 4500.00),
    ('a0000000-0000-0000-0000-000000000001', 'Transporte Escolar Ruta Naco', 'transporte', 3800.00)
ON CONFLICT DO NOTHING;

-- Grados
INSERT INTO grados (id, colegio_id, nombre, nivel, orden)
VALUES
    ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Kínder', 'Inicial', 1),
    ('c0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Pre-Primario', 'Inicial', 2),
    ('c0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', '1ro de Primaria', 'Primaria', 3)
ON CONFLICT DO NOTHING;

-- Secciones
INSERT INTO secciones (id, grado_id, nombre, capacidad)
VALUES
    ('d0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'A', 25)
ON CONFLICT DO NOTHING;

-- Familia Piloto: Familia Pérez González
INSERT INTO familias (id, colegio_id, codigo_familia, nombre_familia, balance_pendiente, telefono_principal, email_principal)
VALUES (
    'e0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'FAM-2026-001',
    'Familia Pérez González',
    7500.00,
    '809-555-0150',
    'familia@edunex.edu'
) ON CONFLICT DO NOTHING;

-- Tutor de la familia
INSERT INTO tutores (familia_id, nombres, apellidos, parentesco, cedula_o_pasaporte, telefono, email, es_contacto_principal)
VALUES (
    'e0000000-0000-0000-0000-000000000001',
    'Roberto',
    'Pérez',
    'Padre',
    '001-1234567-8',
    '809-555-0150',
    'familia@edunex.edu',
    true
) ON CONFLICT DO NOTHING;

-- Dos hermanos estudiantes vinculados a la misma Cuenta Familiar
INSERT INTO estudiantes (id, colegio_id, sucursal_id, familia_id, matricula, nombres, apellidos, fecha_nacimiento, seccion_id)
VALUES
    ('f0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'EST-2026-01', 'Mateo', 'Pérez González', '2019-05-14', 'd0000000-0000-0000-0000-000000000001'),
    ('f0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'EST-2026-02', 'Sofía', 'Pérez González', '2021-08-20', 'd0000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

-- Servicios de Cuido
INSERT INTO servicios_cuido (colegio_id, nombre, horario, edad_min, edad_max, precio_mensual, cupo_maximo)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Cuido Mañana', '7:00–8:00 AM', 2, 5, 2000.00, 25),
    ('a0000000-0000-0000-0000-000000000001', 'Cuido Tarde', '3:00–6:00 PM', 3, 6, 4500.00, 30),
    ('a0000000-0000-0000-0000-000000000001', 'Cuido Extendido', '3:00–7:00 PM', 3, 10, 6000.00, 20),
    ('a0000000-0000-0000-0000-000000000001', 'Sábados Recreativos', '8:00 AM–12:00 PM', 4, 12, 2500.00, 30)
ON CONFLICT DO NOTHING;

-- Rutas de Transporte
INSERT INTO rutas_transporte (colegio_id, nombre_ruta, tipo, chofer_nombre, chofer_telefono, precio_mensual, cupo_maximo)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Ruta 1: Naco - Piantini', 'propio', 'Manuel Santos', '809-555-0188', 3800.00, 18),
    ('a0000000-0000-0000-0000-000000000001', 'Ruta 2: Bella Vista - Mirador', 'subcontratado', 'Transportes Escolar SRL', '809-555-0199', 4200.00, 22)
ON CONFLICT DO NOTHING;

-- Productos de Tienda Escolar
INSERT INTO productos_tienda (colegio_id, nombre, categoria, talla_o_variante, precio, stock)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Polo Institucional EDUNEX (Azul)', 'Uniforme', 'Talla 8', 650.00, 40),
    ('a0000000-0000-0000-0000-000000000001', 'Polo Institucional EDUNEX (Azul)', 'Uniforme', 'Talla 10', 650.00, 35),
    ('a0000000-0000-0000-0000-000000000001', 'Pantalón Escolar Caqui', 'Uniforme', 'Talla 8', 850.00, 30),
    ('a0000000-0000-0000-0000-000000000001', 'Mochila EDUNEX Ergonómica', 'Accesorio', 'Única', 1400.00, 25)
ON CONFLICT DO NOTHING;
