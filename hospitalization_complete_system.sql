-- =====================================================
-- SISTEMA COMPLETO DE HOSPITALIZACIÓN
-- =====================================================

-- 1. CREAR TABLA DE MEDICAMENTOS/TRATAMIENTOS
-- =====================================================
CREATE TABLE IF NOT EXISTS treatments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    hospitalization_id UUID REFERENCES hospitalization(id) ON DELETE CASCADE,
    
    -- Información del medicamento
    medication_name TEXT NOT NULL,
    presentation TEXT NOT NULL, -- Tableta, Inyección, Pomada, etc.
    dosage TEXT NOT NULL, -- 10mg, 2ml, etc.
    administration_route TEXT NOT NULL, -- Oral, IV, IM, Subcutánea, etc.
    
    -- Programación
    scheduled_date DATE NOT NULL,
    scheduled_time TIME NOT NULL,
    frequency TEXT, -- Cada 8 horas, Diario, etc.
    duration_days INTEGER, -- Duración del tratamiento en días
    
    -- Responsable
    responsible_doctor_id UUID,
    
    -- Estado
    status TEXT NOT NULL DEFAULT 'scheduled', -- scheduled, completed, cancelled, missed
    priority TEXT NOT NULL DEFAULT 'normal', -- low, normal, high, urgent
    
    -- Metadatos
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_by UUID
);

-- Índices para treatments
CREATE INDEX IF NOT EXISTS idx_treatments_patient_id ON treatments(patient_id);
CREATE INDEX IF NOT EXISTS idx_treatments_hospitalization_id ON treatments(hospitalization_id);
CREATE INDEX IF NOT EXISTS idx_treatments_scheduled_date ON treatments(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_treatments_status ON treatments(status);
CREATE INDEX IF NOT EXISTS idx_treatments_clinic_id ON treatments(clinic_id);

-- 2. EXPANDIR TABLA COMPLETIONS PARA MEDICAMENTOS
-- =====================================================
-- La tabla completions ya existe, pero vamos a agregar campos específicos para medicamentos
ALTER TABLE completions 
ADD COLUMN IF NOT EXISTS medication_name TEXT,
ADD COLUMN IF NOT EXISTS dosage_administered TEXT,
ADD COLUMN IF NOT EXISTS administration_route TEXT,
ADD COLUMN IF NOT EXISTS administered_by UUID,
ADD COLUMN IF NOT EXISTS administration_notes TEXT,
ADD COLUMN IF NOT EXISTS side_effects TEXT,
ADD COLUMN IF NOT EXISTS effectiveness_rating INTEGER CHECK (effectiveness_rating >= 1 AND effectiveness_rating <= 5);

-- 3. CREAR TABLA DE EVOLUCIÓN DEL PACIENTE
-- =====================================================
CREATE TABLE IF NOT EXISTS patient_evolution (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    hospitalization_id UUID REFERENCES hospitalization(id) ON DELETE CASCADE,
    
    -- Información de la evolución
    evolution_date DATE NOT NULL DEFAULT CURRENT_DATE,
    evolution_time TIME NOT NULL DEFAULT CURRENT_TIME,
    evolution_type TEXT NOT NULL, -- vital_signs, medication_response, general_condition, etc.
    
    -- Datos específicos (JSON flexible)
    vital_signs JSONB, -- {temperature: 38.5, heart_rate: 120, etc.}
    observations TEXT,
    recommendations TEXT,
    next_evaluation_date DATE,
    
    -- Responsable
    recorded_by UUID NOT NULL,
    
    -- Metadatos
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Índices para patient_evolution
CREATE INDEX IF NOT EXISTS idx_patient_evolution_patient_id ON patient_evolution(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_evolution_hospitalization_id ON patient_evolution(hospitalization_id);
CREATE INDEX IF NOT EXISTS idx_patient_evolution_date ON patient_evolution(evolution_date);
CREATE INDEX IF NOT EXISTS idx_patient_evolution_type ON patient_evolution(evolution_type);
CREATE INDEX IF NOT EXISTS idx_patient_evolution_clinic_id ON patient_evolution(clinic_id);

-- 4. CREAR VISTA INTEGRADA DE HOSPITALIZACIÓN COMPLETA
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
    
    -- Conteos
    (SELECT COUNT(*) FROM treatments t WHERE t.hospitalization_id = h.id) as total_treatments,
    (SELECT COUNT(*) FROM treatments t WHERE t.hospitalization_id = h.id AND t.status = 'completed') as completed_treatments,
    (SELECT COUNT(*) FROM treatments t WHERE t.hospitalization_id = h.id AND t.status = 'scheduled') as pending_treatments,
    (SELECT COUNT(*) FROM patient_evolution pe WHERE pe.hospitalization_id = h.id) as evolution_entries,
    (SELECT COUNT(*) FROM completions c WHERE c.patient_id = h.patient_id AND c.completion_type = 'medication') as medication_completions,
    
    -- Última evolución
    (SELECT pe.evolution_date FROM patient_evolution pe WHERE pe.hospitalization_id = h.id ORDER BY pe.evolution_date DESC LIMIT 1) as last_evolution_date,
    
    -- Metadatos
    h.created_at,
    h.updated_at
FROM hospitalization h
LEFT JOIN patients p ON h.patient_id = p.id
LEFT JOIN owners o ON p.owner_id = o.id
WHERE h.status = 'active';

-- 5. CREAR VISTA DE TRATAMIENTOS PROGRAMADOS
-- =====================================================
CREATE OR REPLACE VIEW v_treatments_schedule AS
SELECT 
    t.id as treatment_id,
    t.patient_id,
    t.hospitalization_id,
    t.clinic_id,
    
    -- Información del medicamento
    t.medication_name,
    t.presentation,
    t.dosage,
    t.administration_route,
    t.scheduled_date,
    t.scheduled_time,
    t.frequency,
    t.duration_days,
    t.status,
    t.priority,
    
    -- Responsable
    cr.display_name as responsible_doctor,
    cr.email as doctor_email,
    
    -- Datos del paciente
    p.name as patient_name,
    p.history_number as patient_mrn,
    
    -- Metadatos
    t.created_at,
    t.updated_at
FROM treatments t
LEFT JOIN patients p ON t.patient_id = p.id
LEFT JOIN clinic_roles cr ON t.responsible_doctor_id = cr.user_id AND t.clinic_id = cr.clinic_id
ORDER BY t.scheduled_date, t.scheduled_time;

-- 6. CREAR VISTA DE EVOLUCIÓN DEL PACIENTE
-- =====================================================
CREATE OR REPLACE VIEW v_patient_evolution AS
SELECT 
    pe.id as evolution_id,
    pe.patient_id,
    pe.hospitalization_id,
    pe.clinic_id,
    pe.evolution_date,
    pe.evolution_time,
    pe.evolution_type,
    pe.vital_signs,
    pe.observations,
    pe.recommendations,
    pe.next_evaluation_date,
    
    -- Responsable
    cr.display_name as recorded_by_name,
    cr.email as recorded_by_email,
    
    -- Datos del paciente
    p.name as patient_name,
    p.history_number as patient_mrn,
    
    -- Metadatos
    pe.created_at,
    pe.updated_at
FROM patient_evolution pe
LEFT JOIN patients p ON pe.patient_id = p.id
LEFT JOIN clinic_roles cr ON pe.recorded_by = cr.user_id AND pe.clinic_id = cr.clinic_id
ORDER BY pe.evolution_date DESC, pe.evolution_time DESC;

-- 7. CREAR VISTA DE COMPLETIONES DE MEDICAMENTOS
-- =====================================================
CREATE OR REPLACE VIEW v_medication_completions AS
SELECT 
    c.id as completion_id,
    c.patient_id,
    c.hospitalization_id,
    c.clinic_id,
    c.completed_at,
    c.completed_by,
    c.completion_status,
    c.completion_notes,
    
    -- Datos específicos del medicamento
    c.medication_name,
    c.dosage_administered,
    c.administration_route,
    c.administration_notes,
    c.side_effects,
    c.effectiveness_rating,
    
    -- Responsable
    cr.display_name as completed_by_name,
    cr.email as completed_by_email,
    
    -- Datos del paciente
    p.name as patient_name,
    p.history_number as patient_mrn,
    
    -- Metadatos
    c.created_at,
    c.updated_at
FROM completions c
LEFT JOIN patients p ON c.patient_id = p.id
LEFT JOIN clinic_roles cr ON c.completed_by = cr.user_id AND c.clinic_id = cr.clinic_id
WHERE c.completion_type = 'medication'
ORDER BY c.completed_at DESC;

-- 8. CREAR FUNCIONES AUXILIARES
-- =====================================================

-- Función para obtener tratamientos del día
CREATE OR REPLACE FUNCTION get_treatments_for_date(
    p_patient_id UUID,
    p_date DATE
) RETURNS TABLE (
    treatment_id UUID,
    medication_name TEXT,
    dosage TEXT,
    scheduled_time TIME,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.medication_name,
        t.dosage,
        t.scheduled_time,
        t.status
    FROM treatments t
    WHERE t.patient_id = p_patient_id 
    AND t.scheduled_date = p_date
    ORDER BY t.scheduled_time;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener evolución reciente
CREATE OR REPLACE FUNCTION get_recent_evolution(
    p_patient_id UUID,
    p_days INTEGER DEFAULT 7
) RETURNS TABLE (
    evolution_date DATE,
    evolution_type TEXT,
    observations TEXT,
    recorded_by_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pe.evolution_date,
        pe.evolution_type,
        pe.observations,
        cr.display_name
    FROM patient_evolution pe
    LEFT JOIN clinic_roles cr ON pe.recorded_by = cr.user_id AND pe.clinic_id = cr.clinic_id
    WHERE pe.patient_id = p_patient_id 
    AND pe.evolution_date >= CURRENT_DATE - INTERVAL '1 day' * p_days
    ORDER BY pe.evolution_date DESC, pe.evolution_time DESC;
END;
$$ LANGUAGE plpgsql;

-- 9. CREAR TRIGGERS PARA ACTUALIZAR TIMESTAMPS
-- =====================================================

-- Trigger para treatments
CREATE OR REPLACE FUNCTION update_treatments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_treatments_updated
    BEFORE UPDATE ON treatments
    FOR EACH ROW
    EXECUTE FUNCTION update_treatments_updated_at();

-- Trigger para patient_evolution
CREATE OR REPLACE FUNCTION update_patient_evolution_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_patient_evolution_updated
    BEFORE UPDATE ON patient_evolution
    FOR EACH ROW
    EXECUTE FUNCTION update_patient_evolution_updated_at();

-- 10. CREAR POLÍTICAS RLS
-- =====================================================

-- Políticas para treatments
ALTER TABLE treatments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated clinic members to view treatments" ON treatments
    FOR SELECT TO authenticated
    USING (is_member_of(clinic_id));

CREATE POLICY "Allow authenticated clinic members to insert treatments" ON treatments
    FOR INSERT TO authenticated
    WITH CHECK (is_member_of(clinic_id));

CREATE POLICY "Allow authenticated clinic members to update treatments" ON treatments
    FOR UPDATE TO authenticated
    USING (is_member_of(clinic_id))
    WITH CHECK (is_member_of(clinic_id));

CREATE POLICY "Allow authenticated clinic members to delete treatments" ON treatments
    FOR DELETE TO authenticated
    USING (is_member_of(clinic_id));

-- Políticas para patient_evolution
ALTER TABLE patient_evolution ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated clinic members to view patient evolution" ON patient_evolution
    FOR SELECT TO authenticated
    USING (is_member_of(clinic_id));

CREATE POLICY "Allow authenticated clinic members to insert patient evolution" ON patient_evolution
    FOR INSERT TO authenticated
    WITH CHECK (is_member_of(clinic_id));

CREATE POLICY "Allow authenticated clinic members to update patient evolution" ON patient_evolution
    FOR UPDATE TO authenticated
    USING (is_member_of(clinic_id))
    WITH CHECK (is_member_of(clinic_id));

CREATE POLICY "Allow authenticated clinic members to delete patient evolution" ON patient_evolution
    FOR DELETE TO authenticated
    USING (is_member_of(clinic_id));

-- 11. COMENTARIOS EN TABLAS
-- =====================================================
COMMENT ON TABLE treatments IS 'Tabla de medicamentos y tratamientos programados para pacientes hospitalizados';
COMMENT ON TABLE patient_evolution IS 'Tabla de evolución y seguimiento del estado de pacientes hospitalizados';
COMMENT ON VIEW v_hospitalization_complete IS 'Vista integrada con toda la información de hospitalización';
COMMENT ON VIEW v_treatments_schedule IS 'Vista de tratamientos programados con información del paciente y doctor';
COMMENT ON VIEW v_patient_evolution IS 'Vista de evolución del paciente con información del responsable';
COMMENT ON VIEW v_medication_completions IS 'Vista de administración de medicamentos completada';

-- 12. DATOS DE EJEMPLO (OPCIONAL)
-- =====================================================
-- INSERT INTO treatments (clinic_id, patient_id, medication_name, presentation, dosage, administration_route, scheduled_date, scheduled_time, frequency, responsible_doctor_id)
-- VALUES 
--     ('4c17fddf-24ab-4a8d-9343-4cc4f6a4a203', '61632e39-30f9-4ad3-92eb-860f2997f58e', 'Amoxicilina', 'Cápsula', '500mg', 'Oral', CURRENT_DATE, '08:00:00', 'Cada 8 horas', '7b6a5c4d-2e1f-3a8b-9c0d-1e2f3a4b5c6d');

-- =====================================================
-- SISTEMA COMPLETO DE HOSPITALIZACIÓN CREADO
-- =====================================================
