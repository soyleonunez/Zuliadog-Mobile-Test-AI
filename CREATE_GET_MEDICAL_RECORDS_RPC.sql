-- Función RPC para obtener historias médicas por paciente
-- Evita problemas de RLS y políticas que referencian clinic_members

CREATE OR REPLACE FUNCTION get_medical_records_by_patient(
  p_clinic_id UUID,
  p_patient_id TEXT
)
RETURNS TABLE (
  id UUID,
  clinic_id UUID,
  patient_id TEXT,
  date DATE,
  title TEXT,
  summary TEXT,
  diagnosis TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  department_code TEXT,
  locked BOOLEAN,
  content_delta TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    mr.id,
    mr.clinic_id,
    mr.patient_id,
    mr.date,
    mr.title,
    mr.summary,
    mr.diagnosis,
    mr.created_by,
    mr.created_at,
    mr.updated_at,
    mr.department_code,
    mr.locked,
    mr.content_delta
  FROM medical_records mr
  WHERE mr.clinic_id = p_clinic_id
    AND mr.patient_id = p_patient_id
  ORDER BY mr.date DESC, mr.created_at DESC;
END;
$$;

-- Otorgar permisos de ejecución
GRANT EXECUTE ON FUNCTION get_medical_records_by_patient(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_medical_records_by_patient(UUID, TEXT) TO anon;
