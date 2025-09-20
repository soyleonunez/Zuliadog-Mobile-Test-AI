-- Actualización de referencias de clinic_members a clinic_roles
-- Este archivo actualiza las funciones RPC y referencias para usar la nueva tabla clinic_roles

-- 1. Actualizar función save_medical_record para usar clinic_roles
CREATE OR REPLACE FUNCTION public.save_medical_record(payload JSONB)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    record_id UUID;
    clinic_uuid UUID := (payload ->> 'clinic_id')::uuid;
    patient_mrn TEXT := payload ->> 'mrn';
    content_delta TEXT := payload ->> 'content_delta';
    title TEXT := payload ->> 'title';
    summary TEXT := payload ->> 'summary';
    diagnosis TEXT := payload ->> 'diagnosis';
    department_code TEXT := COALESCE(payload ->> 'department_code', 'MED');
    locked BOOLEAN := COALESCE((payload ->> 'locked')::boolean, false);
    record_date DATE := COALESCE((payload ->> 'date')::date, CURRENT_DATE);
    created_by_email TEXT := payload ->> 'created_by_email';
    created_by_id UUID;
    patient_patch JSONB := payload -> 'patient_patch';
    attachments JSONB := payload -> 'attachments';
    attachment JSONB;
    attachment_id UUID;
BEGIN
    -- Obtener el ID del usuario creador desde clinic_roles
    IF created_by_email IS NOT NULL THEN
        SELECT id INTO created_by_id 
        FROM public.clinic_roles 
        WHERE clinic_id = clinic_uuid 
        AND email = created_by_email 
        AND is_active = true
        LIMIT 1;
    END IF;
    
    -- Si no se encuentra el usuario, usar un ID por defecto o el primer rol activo
    IF created_by_id IS NULL THEN
        SELECT id INTO created_by_id 
        FROM public.clinic_roles 
        WHERE clinic_id = clinic_uuid 
        AND is_active = true
        ORDER BY created_at ASC
        LIMIT 1;
    END IF;

    -- Insertar o actualizar el registro médico
    INSERT INTO public.medical_records (
        clinic_id,
        patient_id,
        date,
        title,
        summary,
        diagnosis,
        department_code,
        locked,
        content_delta,
        created_by,
        created_at,
        updated_at
    ) VALUES (
        clinic_uuid,
        patient_mrn,
        record_date,
        title,
        summary,
        diagnosis,
        department_code,
        locked,
        content_delta,
        created_by_id::text,
        NOW(),
        NOW()
    ) RETURNING id INTO record_id;

    -- Actualizar información del paciente si se proporciona
    IF patient_patch IS NOT NULL THEN
        UPDATE public.patients 
        SET 
            name = COALESCE(patient_patch ->> 'name', name),
            species = COALESCE(patient_patch ->> 'species', species),
            breed = COALESCE(patient_patch ->> 'breed', breed),
            sex = COALESCE(patient_patch ->> 'sex', sex),
            age_label = COALESCE(patient_patch ->> 'age_label', age_label),
            temperature = COALESCE((patient_patch ->> 'temperature')::numeric, temperature),
            respiration = COALESCE((patient_patch ->> 'respiration')::integer, respiration),
            pulse = COALESCE((patient_patch ->> 'pulse')::integer, pulse),
            hydration = COALESCE(patient_patch ->> 'hydration', hydration),
            owner_name = COALESCE(patient_patch ->> 'owner_name', owner_name),
            owner_phone = COALESCE(patient_patch ->> 'owner_phone', owner_phone),
            owner_email = COALESCE(patient_patch ->> 'owner_email', owner_email),
            updated_at = NOW()
        WHERE mrn = patient_mrn AND clinic_id = clinic_uuid;
    END IF;

    -- Procesar adjuntos si se proporcionan
    IF attachments IS NOT NULL AND jsonb_array_length(attachments) > 0 THEN
        FOR attachment IN SELECT * FROM jsonb_array_elements(attachments)
        LOOP
            INSERT INTO public.record_attachments (
                record_id,
                path,
                doc_type,
                label,
                meta,
                created_at
            ) VALUES (
                record_id,
                attachment ->> 'path',
                COALESCE(attachment ->> 'doc_type', 'other'),
                COALESCE(attachment ->> 'label', 'Adjunto'),
                attachment -> 'meta',
                NOW()
            ) RETURNING id INTO attachment_id;
        END LOOP;
    END IF;

    -- Devolver resultado exitoso
    result := jsonb_build_object(
        'success', true,
        'record_id', record_id,
        'message', 'Registro médico guardado exitosamente'
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Actualizar función create_prescription para usar clinic_roles
CREATE OR REPLACE FUNCTION public.create_prescription(payload JSONB)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    prescription_id UUID;
    clinic_uuid UUID := (payload ->> 'clinic_id')::uuid;
    patient_mrn TEXT := payload ->> 'mrn';
    notes_content TEXT := payload ->> 'notes';
    created_by_email TEXT := payload ->> 'created_by_email';
    created_by_id UUID;
BEGIN
    -- Obtener el ID del usuario creador desde clinic_roles
    IF created_by_email IS NOT NULL THEN
        SELECT id INTO created_by_id 
        FROM public.clinic_roles 
        WHERE clinic_id = clinic_uuid 
        AND email = created_by_email 
        AND is_active = true
        LIMIT 1;
    END IF;
    
    -- Si no se encuentra el usuario, usar un ID por defecto
    IF created_by_id IS NULL THEN
        SELECT id INTO created_by_id 
        FROM public.clinic_roles 
        WHERE clinic_id = clinic_uuid 
        AND is_active = true
        ORDER BY created_at ASC
        LIMIT 1;
    END IF;

    -- Insertar en la tabla notes con la estructura correcta
    INSERT INTO public.notes (
        clinic_id,
        patient_id,
        title,
        body,
        created_by
    ) VALUES (
        clinic_uuid,
        patient_mrn,
        'Receta Médica',
        notes_content,
        created_by_id::text
    ) RETURNING id INTO prescription_id;

    -- Devolver resultado exitoso
    result := jsonb_build_object(
        'success', true,
        'prescription_id', prescription_id,
        'message', 'Receta creada exitosamente'
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Crear función para obtener roles activos de una clínica
CREATE OR REPLACE FUNCTION public.get_clinic_roles(clinic_uuid UUID)
RETURNS TABLE (
    id UUID,
    email TEXT,
    role TEXT,
    full_name TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cr.id,
        cr.email,
        cr.role,
        cr.full_name,
        cr.is_active,
        cr.created_at
    FROM public.clinic_roles cr
    WHERE cr.clinic_id = clinic_uuid
    AND cr.is_active = true
    ORDER BY cr.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Crear función para obtener rol por email
CREATE OR REPLACE FUNCTION public.get_role_by_email(
    clinic_uuid UUID,
    user_email TEXT
)
RETURNS TABLE (
    id UUID,
    email TEXT,
    role TEXT,
    full_name TEXT,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cr.id,
        cr.email,
        cr.role,
        cr.full_name,
        cr.is_active
    FROM public.clinic_roles cr
    WHERE cr.clinic_id = clinic_uuid
    AND cr.email = user_email
    AND cr.is_active = true
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Actualizar políticas RLS para clinic_roles
ALTER TABLE public.clinic_roles ENABLE ROW LEVEL SECURITY;

-- Política para que las clínicas solo vean sus propios roles
DROP POLICY IF EXISTS "Clinics can view their own roles." ON public.clinic_roles;
CREATE POLICY "Clinics can view their own roles."
ON public.clinic_roles FOR SELECT
USING (clinic_id = auth.jwt() ->> 'clinic_id')::uuid;

-- Política para que las clínicas solo puedan insertar roles para sí mismas
DROP POLICY IF EXISTS "Clinics can insert their own roles." ON public.clinic_roles;
CREATE POLICY "Clinics can insert their own roles."
ON public.clinic_roles FOR INSERT
WITH CHECK (clinic_id = auth.jwt() ->> 'clinic_id')::uuid;

-- Política para que las clínicas solo puedan actualizar sus propios roles
DROP POLICY IF EXISTS "Clinics can update their own roles." ON public.clinic_roles;
CREATE POLICY "Clinics can update their own roles."
ON public.clinic_roles FOR UPDATE
USING (clinic_id = auth.jwt() ->> 'clinic_id')::uuid;

-- Política para que las clínicas solo puedan eliminar sus propios roles
DROP POLICY IF EXISTS "Clinics can delete their own roles." ON public.clinic_roles;
CREATE POLICY "Clinics can delete their own roles."
ON public.clinic_roles FOR DELETE
USING (clinic_id = auth.jwt() ->> 'clinic_id')::uuid;

-- 6. Comentarios de documentación
COMMENT ON FUNCTION public.save_medical_record(JSONB) IS 'Guarda un registro médico completo usando clinic_roles para created_by';
COMMENT ON FUNCTION public.create_prescription(JSONB) IS 'Crea una receta médica usando clinic_roles para created_by';
COMMENT ON FUNCTION public.get_clinic_roles(UUID) IS 'Obtiene todos los roles activos de una clínica';
COMMENT ON FUNCTION public.get_role_by_email(UUID, TEXT) IS 'Obtiene un rol específico por email en una clínica';
