-- =====================================================
-- TRANSFORMAR COMPLETIONS EN TABLA FOLLOWS
-- Sistema unificado de seguimiento de hospitalización
-- =====================================================

-- 1. RENOMBRAR TABLA COMPLETIONS A FOLLOWS
-- =====================================================
ALTER TABLE completions RENAME TO follows;

-- 2. AGREGAR COLUMNAS ESPECÍFICAS PARA HOSPITALIZACIÓN
-- =====================================================
ALTER TABLE follows 
ADD COLUMN IF NOT EXISTS hospitalization_id UUID REFERENCES hospitalization(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS follow_type TEXT NOT NULL DEFAULT 'general', -- treatment, evolution, medication, vital_signs, etc.
ADD COLUMN IF NOT EXISTS medication_name TEXT,
ADD COLUMN IF NOT EXISTS medication_dosage TEXT,
ADD COLUMN IF NOT EXISTS administration_route TEXT,
ADD COLUMN IF NOT EXISTS scheduled_date DATE,
ADD COLUMN IF NOT EXISTS scheduled_time TIME,
ADD COLUMN IF NOT EXISTS frequency TEXT,
ADD COLUMN IF NOT EXISTS duration_days INTEGER,
ADD COLUMN IF NOT EXISTS vital_signs JSONB, -- {temperature: 38.5, heart_rate: 120, etc.}
ADD COLUMN IF NOT EXISTS observations TEXT,
ADD COLUMN IF NOT EXISTS recommendations TEXT,
ADD COLUMN IF NOT EXISTS next_evaluation_date DATE,
ADD COLUMN IF NOT EXISTS effectiveness_rating INTEGER CHECK (effectiveness_rating >= 1 AND effectiveness_rating <= 5),
ADD COLUMN IF NOT EXISTS side_effects TEXT,
ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal', -- low, normal, high, urgent
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'scheduled', -- scheduled, completed, cancelled, missed, overdue
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- 3. CREAR ÍNDICES PARA NUEVAS COLUMNAS
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_follows_hospitalization_id ON follows(hospitalization_id);
CREATE INDEX IF NOT EXISTS idx_follows_follow_type ON follows(follow_type);
CREATE INDEX IF NOT EXISTS idx_follows_scheduled_date ON follows(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_follows_status ON follows(status);
CREATE INDEX IF NOT EXISTS idx_follows_priority ON follows(priority);
CREATE INDEX IF NOT EXISTS idx_follows_medication_name ON follows(medication_name);

-- 4. CREAR VISTA PARA TRATAMIENTOS (MEDICAMENTOS)
-- =====================================================
CREATE OR REPLACE VIEW v_treatments AS
SELECT 
    f.id as treatment_id,
    f.patient_id,
    f.hospitalization_id,
    f.clinic_id,
    f.medication_name,
    f.medication_dosage as dosage,
    f.administration_route,
    f.scheduled_date,
    f.scheduled_time,
    f.frequency,
    f.duration_days,
    f.priority,
    f.status,
    f.completed_at,
    f.completed_by,
    f.completion_notes,
    f.effectiveness_rating,
    f.side_effects,
    
    -- Datos del paciente
    p.name as patient_name,
    p.history_number as patient_mrn,
    
    -- Metadatos
    f.created_at,
    f.updated_at
FROM follows f
LEFT JOIN patients p ON f.patient_id = p.id
WHERE f.follow_type = 'treatment'
ORDER BY f.scheduled_date, f.scheduled_time;

-- 5. CREAR VISTA PARA EVOLUCIÓN DEL PACIENTE
-- =====================================================
CREATE OR REPLACE VIEW v_patient_evolution AS
SELECT 
    f.id as evolution_id,
    f.patient_id,
    f.hospitalization_id,
    f.clinic_id,
    f.scheduled_date as evolution_date,
    f.scheduled_time as evolution_time,
    f.vital_signs,
    f.observations,
    f.recommendations,
    f.next_evaluation_date,
    f.completed_at,
    f.completed_by,
    f.completion_notes,
    
    -- Datos del paciente
    p.name as patient_name,
    p.history_number as patient_mrn,
    
    -- Metadatos
    f.created_at,
    f.updated_at
FROM follows f
LEFT JOIN patients p ON f.patient_id = p.id
WHERE f.follow_type = 'evolution'
ORDER BY f.scheduled_date DESC, f.scheduled_time DESC;

-- 6. CREAR VISTA PARA SIGNOS VITALES
-- =====================================================
CREATE OR REPLACE VIEW v_vital_signs AS
SELECT 
    f.id as vital_signs_id,
    f.patient_id,
    f.hospitalization_id,
    f.clinic_id,
    f.scheduled_date as measurement_date,
    f.scheduled_time as measurement_time,
    f.vital_signs,
    f.observations,
    f.completed_at,
    f.completed_by,
    
    -- Datos del paciente
    p.name as patient_name,
    p.history_number as patient_mrn,
    
    -- Metadatos
    f.created_at,
    f.updated_at
FROM follows f
LEFT JOIN patients p ON f.patient_id = p.id
WHERE f.follow_type = 'vital_signs'
ORDER BY f.scheduled_date DESC, f.scheduled_time DESC;

-- 7. CREAR VISTA INTEGRADA DE HOSPITALIZACIÓN COMPLETA
-- =====================================================
CREATE OR REPLACE VIEW v_hospitalization_complete AS
SELECT 
    h.id as hospitalization_id,
    h.patient_id,
    h.clinic_id,
    h.admission_date,
    h.discharge_date,
    h.status as hospitalization_status,
    h.priority as hospitalization_priority,
    
    -- Datos del paciente
    p.name as patient_name,
    p.history_number as patient_mrn,
    p.birth_date,
    p.sex,
    p.species_code,
    p.breed_id,
    
    -- Datos del propietario
    o.name as owner_name,
    o.phone as owner_phone,
    o.email as owner_email,
    
    -- Conteos de seguimientos
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'treatment') as total_treatments,
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'treatment' AND f.status = 'completed') as completed_treatments,
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'treatment' AND f.status = 'scheduled') as pending_treatments,
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'evolution') as evolution_entries,
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'vital_signs') as vital_signs_entries,
    
    -- Última evolución
    (SELECT f.scheduled_date FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'evolution' ORDER BY f.scheduled_date DESC LIMIT 1) as last_evolution_date,
    
    -- Metadatos
    h.created_at,
    h.updated_at
FROM hospitalization h
LEFT JOIN patients p ON h.patient_id = p.id
LEFT JOIN owners o ON p.owner_id = o.id
WHERE h.status = 'active';

-- 8. CREAR VISTA DE SEGUIMIENTOS DEL DÍA
-- =====================================================
CREATE OR REPLACE VIEW v_daily_follows AS
SELECT 
    f.id as follow_id,
    f.patient_id,
    f.hospitalization_id,
    f.clinic_id,
    f.follow_type,
    f.scheduled_date,
    f.scheduled_time,
    f.status,
    f.priority,
    f.medication_name,
    f.medication_dosage,
    f.administration_route,
    f.vital_signs,
    f.observations,
    
    -- Datos del paciente
    p.name as patient_name,
    p.history_number as patient_mrn,
    
    -- Metadatos
    f.created_at,
    f.updated_at
FROM follows f
LEFT JOIN patients p ON f.patient_id = p.id
WHERE f.scheduled_date = CURRENT_DATE
ORDER BY f.scheduled_time;

-- 9. CREAR FUNCIONES AUXILIARES
-- =====================================================

-- Función para obtener seguimientos del día
CREATE OR REPLACE FUNCTION get_follows_for_date(
    p_patient_id UUID,
    p_date DATE
) RETURNS TABLE (
    follow_id UUID,
    follow_type TEXT,
    medication_name TEXT,
    scheduled_time TIME,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.follow_type,
        f.medication_name,
        f.scheduled_time,
        f.status
    FROM follows f
    WHERE f.patient_id = p_patient_id 
    AND f.scheduled_date = p_date
    ORDER BY f.scheduled_time;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener evolución reciente
CREATE OR REPLACE FUNCTION get_recent_evolution(
    p_patient_id UUID,
    p_days INTEGER DEFAULT 7
) RETURNS TABLE (
    evolution_date DATE,
    follow_type TEXT,
    observations TEXT,
    completed_by_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.scheduled_date,
        f.follow_type,
        f.observations,
        cr.display_name
    FROM follows f
    LEFT JOIN clinic_roles cr ON f.completed_by = cr.user_id AND f.clinic_id = cr.clinic_id
    WHERE f.patient_id = p_patient_id 
    AND f.scheduled_date >= CURRENT_DATE - INTERVAL '1 day' * p_days
    ORDER BY f.scheduled_date DESC, f.scheduled_time DESC;
END;
$$ LANGUAGE plpgsql;

-- 10. ACTUALIZAR POLÍTICAS RLS
-- =====================================================

-- Renombrar políticas existentes
ALTER POLICY "Allow authenticated clinic members to delete completions" ON follows RENAME TO "Allow authenticated clinic members to delete follows";
ALTER POLICY "Allow authenticated clinic members to insert completions" ON follows RENAME TO "Allow authenticated clinic members to insert follows";
ALTER POLICY "Allow authenticated clinic members to update completions" ON follows RENAME TO "Allow authenticated clinic members to update follows";
ALTER POLICY "Allow authenticated clinic members to view completions" ON follows RENAME TO "Allow authenticated clinic members to view follows";
ALTER POLICY "Public read access to completions" ON follows RENAME TO "Public read access to follows";

-- 11. ACTUALIZAR ÍNDICES EXISTENTES
-- =====================================================
-- Los índices existentes se mantienen, solo se agregan los nuevos

-- 12. CREAR TRIGGER PARA ACTUALIZAR TIMESTAMP
-- =====================================================
CREATE OR REPLACE FUNCTION update_follows_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_follows_updated
    BEFORE UPDATE ON follows
    FOR EACH ROW
    EXECUTE FUNCTION update_follows_updated_at();

-- 13. COMENTARIOS EN TABLA Y VISTAS
-- =====================================================
COMMENT ON TABLE follows IS 'Tabla unificada para seguimiento de hospitalización: tratamientos, evoluciones, signos vitales y otros procesos';
COMMENT ON COLUMN follows.follow_type IS 'Tipo de seguimiento: treatment, evolution, vital_signs, medication, etc.';
COMMENT ON COLUMN follows.medication_name IS 'Nombre del medicamento (para follow_type = treatment)';
COMMENT ON COLUMN follows.vital_signs IS 'Signos vitales en formato JSON (para follow_type = vital_signs)';
COMMENT ON COLUMN follows.observations IS 'Observaciones generales del seguimiento';
COMMENT ON VIEW v_treatments IS 'Vista de tratamientos/medicamentos programados';
COMMENT ON VIEW v_patient_evolution IS 'Vista de evolución del paciente';
COMMENT ON VIEW v_vital_signs IS 'Vista de signos vitales';
COMMENT ON VIEW v_hospitalization_complete IS 'Vista integrada con toda la información de hospitalización';
COMMENT ON VIEW v_daily_follows IS 'Vista de seguimientos programados para el día actual';

-- 13. DATOS DE EJEMPLO (OPCIONAL)
-- =====================================================
-- INSERT INTO follows (clinic_id, patient_id, follow_type, medication_name, medication_dosage, administration_route, scheduled_date, scheduled_time, frequency, priority, status)
-- VALUES 
--     ('4c17fddf-24ab-4a8d-9343-4cc4f6a4a203', '61632e39-30f9-4ad3-92eb-860f2997f58e', 'treatment', 'Amoxicilina', '500mg', 'Oral', CURRENT_DATE, '08:00:00', 'Cada 8 horas', 'normal', 'scheduled');

-- =====================================================
-- TRANSFORMACIÓN COMPLETADA: COMPLETIONS → FOLLOWS
-- =====================================================
