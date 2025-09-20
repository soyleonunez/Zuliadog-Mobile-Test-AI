-- CREATE_PATIENTS_SEARCH_VIEW.sql
-- Vista para búsqueda de pacientes optimizada
-- Esta vista combina información de pacientes con datos de clínica para búsquedas eficientes

CREATE OR REPLACE VIEW patients_search AS
SELECT 
    p.id as patient_id,
    p.clinic_id,
    p.name as patient_name,
    p.mrn as history_number,
    p.mrn_int,
    p.owner_name,
    p.owner_phone,
    p.owner_email,
    CASE 
        WHEN p.species = 'dog' THEN 'Canino'
        WHEN p.species = 'cat' THEN 'Felino'
        WHEN p.species = 'bird' THEN 'Ave'
        WHEN p.species = 'reptile' THEN 'Reptil'
        WHEN p.species = 'other' THEN 'Otro'
        ELSE 'No especificado'
    END as species_label,
    COALESCE(p.breed, 'No especificado') as breed_label,
    CASE 
        WHEN p.sex = 'male' THEN 'Macho'
        WHEN p.sex = 'female' THEN 'Hembra'
        ELSE 'No especificado'
    END as sex
FROM patients p
WHERE p.clinic_id IS NOT NULL;

-- Comentarios sobre la vista
COMMENT ON VIEW patients_search IS 'Vista optimizada para búsqueda de pacientes con etiquetas en español';
COMMENT ON COLUMN patients_search.patient_id IS 'ID único del paciente';
COMMENT ON COLUMN patients_search.clinic_id IS 'ID de la clínica';
COMMENT ON COLUMN patients_search.patient_name IS 'Nombre del paciente';
COMMENT ON COLUMN patients_search.history_number IS 'Número de historia médica (MRN)';
COMMENT ON COLUMN patients_search.mrn_int IS 'MRN como entero para búsquedas numéricas';
COMMENT ON COLUMN patients_search.owner_name IS 'Nombre del propietario';
COMMENT ON COLUMN patients_search.owner_phone IS 'Teléfono del propietario';
COMMENT ON COLUMN patients_search.owner_email IS 'Email del propietario';
COMMENT ON COLUMN patients_search.species_label IS 'Especie en español';
COMMENT ON COLUMN patients_search.breed_label IS 'Raza del animal';
COMMENT ON COLUMN patients_search.sex IS 'Sexo en español';

-- Crear índices para optimizar las búsquedas
CREATE INDEX IF NOT EXISTS idx_patients_search_name ON patients USING gin(to_tsvector('spanish', name));
CREATE INDEX IF NOT EXISTS idx_patients_search_owner_name ON patients USING gin(to_tsvector('spanish', owner_name));
CREATE INDEX IF NOT EXISTS idx_patients_search_mrn ON patients (mrn);
CREATE INDEX IF NOT EXISTS idx_patients_search_mrn_int ON patients (mrn_int);
CREATE INDEX IF NOT EXISTS idx_patients_search_clinic_id ON patients (clinic_id);

-- Política RLS para la vista (si es necesario)
-- ALTER VIEW patients_search SET (security_invoker = true);

-- Verificar que la vista se creó correctamente
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE viewname = 'patients_search';
