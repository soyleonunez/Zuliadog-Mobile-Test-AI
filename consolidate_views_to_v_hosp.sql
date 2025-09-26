-- =====================================================
-- CONSOLIDAR VISTAS PÚBLICAS EN V_HOSP
-- Eliminar vistas innecesarias y consolidar en v_hosp
-- =====================================================

-- 1. ELIMINAR VISTAS INNECESARIAS
-- =====================================================
DROP VIEW IF EXISTS v_treatments CASCADE;
DROP VIEW IF EXISTS v_patient_evolution CASCADE;
DROP VIEW IF EXISTS v_vital_signs CASCADE;
DROP VIEW IF EXISTS v_hospitalization_complete CASCADE;
DROP VIEW IF EXISTS v_daily_follows CASCADE;
DROP VIEW IF EXISTS v_public_dashboard CASCADE;

-- 2. ELIMINAR V_HOSP EXISTENTE Y RECREAR
-- =====================================================
DROP VIEW IF EXISTS v_hosp CASCADE;

-- 3. CREAR V_HOSP CON INFORMACIÓN COMPLETA
-- =====================================================
CREATE VIEW v_hosp AS
SELECT 
    -- Información básica del paciente
    p.id as patient_id,
    p.name as patient_name,
    p.history_number,
    p.mrn,
    p.mrn_int,
    p.birth_date,
    p.sex,
    p.species_code,
    s.label as species_label,
    p.breed_id,
    b.label as breed_label,
    b.image_url as breed_image_url,
    
    -- Información del propietario
    o.id as owner_id,
    o.name as owner_name,
    o.phone as owner_phone,
    o.email as owner_email,
    o.address as owner_address,
    
    -- Información de hospitalización
    h.id as hospitalization_id,
    h.clinic_id,
    h.admission_date,
    h.discharge_date,
    h.status as hospitalization_status,
    h.priority as hospitalization_priority,
    h.bed_number,
    h.room_number,
    h.diagnosis,
    h.treatment_plan,
    h.special_instructions,
    h.assigned_vet,
    h.created_at as hospitalization_created_at,
    
    -- Veterinario asignado
    cr.display_name as assigned_vet_name,
    cr.email as assigned_vet_email,
    
    -- Conteos de seguimientos
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'treatment') as total_treatments,
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'treatment' AND f.status = 'completed') as completed_treatments,
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'treatment' AND f.status = 'scheduled') as pending_treatments,
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'treatment' AND f.status = 'overdue') as overdue_treatments,
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'evolution') as evolution_entries,
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'vital_signs') as vital_signs_entries,
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.follow_type = 'medication') as medication_entries,
    
    -- Conteos de notas
    (SELECT COUNT(*) FROM notes n WHERE n.hospitalization_id = h.id) as total_notes,
    (SELECT COUNT(*) FROM notes n WHERE n.hospitalization_id = h.id AND n.is_important = true) as important_notes,
    (SELECT COUNT(*) FROM notes n WHERE n.hospitalization_id = h.id AND n.created_at::date = CURRENT_DATE) as today_notes,
    
    -- Conteos de completions
    (SELECT COUNT(*) FROM follows f WHERE f.hospitalization_id = h.id AND f.completed_at::date = CURRENT_DATE) as today_completions,
    
    -- Última actividad
    (SELECT MAX(f.updated_at) FROM follows f WHERE f.hospitalization_id = h.id) as last_activity,
    
    -- Metadatos
    h.created_at,
    h.updated_at
FROM hospitalization h
LEFT JOIN patients p ON h.patient_id = p.id
LEFT JOIN owners o ON p.owner_id = o.id
LEFT JOIN species s ON p.species_code = s.code
LEFT JOIN breeds b ON p.breed_id = b.id
LEFT JOIN clinic_roles cr ON h.assigned_vet = cr.user_id AND h.clinic_id = cr.clinic_id
WHERE h.status = 'active';

-- 4. CREAR VISTA SIMPLIFICADA PARA DASHBOARD
-- =====================================================
CREATE OR REPLACE VIEW v_dashboard AS
SELECT 
    patient_id,
    patient_name,
    history_number,
    hospitalization_status,
    hospitalization_priority,
    bed_number,
    room_number,
    owner_name,
    owner_phone,
    total_treatments,
    completed_treatments,
    pending_treatments,
    overdue_treatments,
    important_notes,
    last_activity
FROM v_hosp
ORDER BY last_activity DESC NULLS LAST;

-- 5. CREAR FUNCIÓN PARA OBTENER TRATAMIENTOS DEL DÍA
-- =====================================================
DROP FUNCTION IF EXISTS get_today_treatments(UUID) CASCADE;
CREATE FUNCTION get_today_treatments(p_hospitalization_id UUID DEFAULT NULL)
RETURNS TABLE (
    follow_id UUID,
    patient_name TEXT,
    medication_name TEXT,
    dosage TEXT,
    scheduled_time TIME,
    status TEXT,
    priority TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        p.name,
        f.medication_name,
        f.medication_dosage,
        f.scheduled_time,
        f.status,
        f.priority
    FROM follows f
    LEFT JOIN patients p ON f.patient_id = p.id
    WHERE f.scheduled_date = CURRENT_DATE
    AND f.follow_type = 'treatment'
    AND (p_hospitalization_id IS NULL OR f.hospitalization_id = p_hospitalization_id)
    ORDER BY f.scheduled_time;
END;
$$ LANGUAGE plpgsql;

-- 6. CREAR FUNCIÓN PARA OBTENER EVOLUCIÓN RECIENTE
-- =====================================================
DROP FUNCTION IF EXISTS get_recent_evolution(UUID, INTEGER) CASCADE;
CREATE FUNCTION get_recent_evolution(p_hospitalization_id UUID DEFAULT NULL, p_days INTEGER DEFAULT 7)
RETURNS TABLE (
    follow_id UUID,
    patient_name TEXT,
    evolution_date DATE,
    follow_type TEXT,
    observations TEXT,
    completed_by_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        p.name,
        f.scheduled_date,
        f.follow_type,
        f.observations,
        cr.display_name
    FROM follows f
    LEFT JOIN patients p ON f.patient_id = p.id
    LEFT JOIN clinic_roles cr ON f.completed_by = cr.user_id AND f.clinic_id = cr.clinic_id
    WHERE f.scheduled_date >= CURRENT_DATE - INTERVAL '1 day' * p_days
    AND f.follow_type IN ('evolution', 'vital_signs')
    AND (p_hospitalization_id IS NULL OR f.hospitalization_id = p_hospitalization_id)
    ORDER BY f.scheduled_date DESC, f.scheduled_time DESC;
END;
$$ LANGUAGE plpgsql;

-- 7. CREAR FUNCIÓN PARA OBTENER SIGNOS VITALES
-- =====================================================
DROP FUNCTION IF EXISTS get_vital_signs(UUID, INTEGER) CASCADE;
CREATE FUNCTION get_vital_signs(p_hospitalization_id UUID DEFAULT NULL, p_days INTEGER DEFAULT 7)
RETURNS TABLE (
    follow_id UUID,
    patient_name TEXT,
    measurement_date DATE,
    measurement_time TIME,
    vital_signs JSONB,
    observations TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        p.name,
        f.scheduled_date,
        f.scheduled_time,
        f.vital_signs,
        f.observations
    FROM follows f
    LEFT JOIN patients p ON f.patient_id = p.id
    WHERE f.scheduled_date >= CURRENT_DATE - INTERVAL '1 day' * p_days
    AND f.follow_type = 'vital_signs'
    AND (p_hospitalization_id IS NULL OR f.hospitalization_id = p_hospitalization_id)
    ORDER BY f.scheduled_date DESC, f.scheduled_time DESC;
END;
$$ LANGUAGE plpgsql;

-- 8. COMENTARIOS EN VISTAS Y FUNCIONES
-- =====================================================
COMMENT ON VIEW v_hosp IS 'Vista consolidada con toda la información de hospitalización, tratamientos, evoluciones y métricas';
COMMENT ON VIEW v_dashboard IS 'Vista simplificada para dashboard con información esencial';
COMMENT ON FUNCTION get_today_treatments IS 'Función para obtener tratamientos programados para hoy';
COMMENT ON FUNCTION get_recent_evolution IS 'Función para obtener evolución reciente del paciente';
COMMENT ON FUNCTION get_vital_signs IS 'Función para obtener signos vitales recientes';

-- 9. VERIFICAR QUE NO HAY DEPENDENCIAS ROTAS
-- =====================================================
-- Las funciones reemplazan la funcionalidad de las vistas eliminadas
-- y proporcionan mayor flexibilidad para consultas específicas

-- =====================================================
-- CONSOLIDACIÓN COMPLETADA: VISTAS UNIFICADAS EN V_HOSP
-- =====================================================
