-- ========================================
-- FIX: Corregir tabla notes para incluir patient_id
-- ========================================

-- 1. Verificar si la tabla notes existe y su estructura
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'notes' AND table_schema = 'public';

-- 2. Si la tabla notes no existe, crearla con la estructura correcta
CREATE TABLE IF NOT EXISTS public.notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    patient_id TEXT NOT NULL, -- MRN del paciente
    title TEXT,
    body TEXT,
    created_by TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Si la tabla ya existe pero no tiene patient_id, agregar la columna
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notes' 
        AND column_name = 'patient_id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.notes ADD COLUMN patient_id TEXT;
    END IF;
END $$;

-- 4. Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_notes_clinic_id ON public.notes(clinic_id);
CREATE INDEX IF NOT EXISTS idx_notes_patient_id ON public.notes(patient_id);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON public.notes(created_at);

-- 5. Habilitar RLS (Row Level Security)
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- 6. Crear políticas RLS para la tabla notes
CREATE POLICY "Users can view notes from their clinic" ON public.notes
    FOR SELECT USING (
        clinic_id = (auth.jwt() ->> 'clinic_id')::uuid
    );

CREATE POLICY "Users can insert notes for their clinic" ON public.notes
    FOR INSERT WITH CHECK (
        clinic_id = (auth.jwt() ->> 'clinic_id')::uuid
    );

CREATE POLICY "Users can update notes from their clinic" ON public.notes
    FOR UPDATE USING (
        clinic_id = (auth.jwt() ->> 'clinic_id')::uuid
    );

CREATE POLICY "Users can delete notes from their clinic" ON public.notes
    FOR DELETE USING (
        clinic_id = (auth.jwt() ->> 'clinic_id')::uuid
    );

-- 7. Crear función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.update_notes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Crear trigger para updated_at
DROP TRIGGER IF EXISTS trigger_update_notes_updated_at ON public.notes;
CREATE TRIGGER trigger_update_notes_updated_at
    BEFORE UPDATE ON public.notes
    FOR EACH ROW
    EXECUTE FUNCTION public.update_notes_updated_at();

-- 9. Verificar que la función create_prescription esté correcta
-- (Esta función debería estar en tu base de datos)
CREATE OR REPLACE FUNCTION public.create_prescription(payload JSONB)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    prescription_id UUID;
    item_record JSONB;
BEGIN
    -- Insertar en la tabla notes (no en una tabla separada de prescriptions)
    INSERT INTO public.notes (
        clinic_id,
        patient_id,
        title,
        body,
        created_by
    ) VALUES (
        (payload ->> 'clinic_id')::uuid,
        payload ->> 'mrn',
        'Receta Médica',
        payload ->> 'notes',
        'Sistema' -- TODO: Obtener del contexto de autenticación
    ) RETURNING id INTO prescription_id;

    -- Procesar items si existen
    IF payload ? 'items' AND jsonb_array_length(payload -> 'items') > 0 THEN
        -- Aquí podrías procesar los items de la receta
        -- Por ahora solo devolvemos el ID de la receta
        NULL;
    END IF;

    -- Devolver resultado
    result := jsonb_build_object(
        'success', true,
        'prescription_id', prescription_id,
        'message', 'Receta creada exitosamente'
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Comentarios de la tabla
COMMENT ON TABLE public.notes IS 'Tabla para almacenar notas y recetas médicas';
COMMENT ON COLUMN public.notes.patient_id IS 'MRN (Medical Record Number) del paciente';
COMMENT ON COLUMN public.notes.title IS 'Título de la nota o receta';
COMMENT ON COLUMN public.notes.body IS 'Contenido de la nota o receta';
COMMENT ON COLUMN public.notes.created_by IS 'Usuario que creó la nota';

-- ========================================
-- VERIFICACIÓN
-- ========================================

-- Verificar que la tabla tiene la estructura correcta
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notes' 
AND table_schema = 'public'
ORDER BY ordinal_position;
