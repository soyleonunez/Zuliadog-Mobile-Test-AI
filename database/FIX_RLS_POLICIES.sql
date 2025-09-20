-- Corregir políticas RLS que referencian clinic_members (que ya no existe)
-- Actualizar para usar clinic_roles en su lugar

-- 1. Eliminar políticas existentes que referencian clinic_members
DROP POLICY IF EXISTS "Users can view their own clinic data" ON medical_records;
DROP POLICY IF EXISTS "Users can insert their own clinic data" ON medical_records;
DROP POLICY IF EXISTS "Users can update their own clinic data" ON medical_records;
DROP POLICY IF EXISTS "Users can delete their own clinic data" ON medical_records;

DROP POLICY IF EXISTS "Users can view their own clinic data" ON patients;
DROP POLICY IF EXISTS "Users can insert their own clinic data" ON patients;
DROP POLICY IF EXISTS "Users can update their own clinic data" ON patients;
DROP POLICY IF EXISTS "Users can delete their own clinic data" ON patients;

DROP POLICY IF EXISTS "Users can view their own clinic data" ON record_attachments;
DROP POLICY IF EXISTS "Users can insert their own clinic data" ON record_attachments;
DROP POLICY IF EXISTS "Users can update their own clinic data" ON record_attachments;
DROP POLICY IF EXISTS "Users can delete their own clinic data" ON record_attachments;

-- 2. Crear nuevas políticas usando clinic_roles
-- Políticas para medical_records
CREATE POLICY "Users can view their own clinic data" ON medical_records
  FOR SELECT USING (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Users can insert their own clinic data" ON medical_records
  FOR INSERT WITH CHECK (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Users can update their own clinic data" ON medical_records
  FOR UPDATE USING (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Users can delete their own clinic data" ON medical_records
  FOR DELETE USING (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- Políticas para patients
CREATE POLICY "Users can view their own clinic data" ON patients
  FOR SELECT USING (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Users can insert their own clinic data" ON patients
  FOR INSERT WITH CHECK (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Users can update their own clinic data" ON patients
  FOR UPDATE USING (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Users can delete their own clinic data" ON patients
  FOR DELETE USING (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- Políticas para record_attachments
CREATE POLICY "Users can view their own clinic data" ON record_attachments
  FOR SELECT USING (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Users can insert their own clinic data" ON record_attachments
  FOR INSERT WITH CHECK (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Users can update their own clinic data" ON record_attachments
  FOR UPDATE USING (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "Users can delete their own clinic data" ON record_attachments
  FOR DELETE USING (
    clinic_id IN (
      SELECT clinic_id FROM clinic_roles 
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- 3. Habilitar RLS en las tablas si no está habilitado
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE record_attachments ENABLE ROW LEVEL SECURITY;

-- 4. Crear la función RPC para obtener historias médicas
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

-- 5. Otorgar permisos de ejecución
GRANT EXECUTE ON FUNCTION get_medical_records_by_patient(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_medical_records_by_patient(UUID, TEXT) TO anon;
