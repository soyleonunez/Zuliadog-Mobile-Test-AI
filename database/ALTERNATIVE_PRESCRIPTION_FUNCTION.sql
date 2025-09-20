-- ========================================
-- ALTERNATIVA: Función create_prescription simplificada
-- ========================================

-- Si prefieres no usar la tabla notes, aquí tienes una versión alternativa
-- que solo devuelve un JSON con la información de la receta sin guardarla en BD

CREATE OR REPLACE FUNCTION public.create_prescription(payload JSONB)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    prescription_id UUID;
    items_array JSONB;
    item JSONB;
    items_list JSONB := '[]'::jsonb;
BEGIN
    -- Generar un ID único para la receta
    prescription_id := gen_random_uuid();
    
    -- Procesar items si existen
    IF payload ? 'items' AND jsonb_array_length(payload -> 'items') > 0 THEN
        items_array := payload -> 'items';
        
        -- Procesar cada item (puedes agregar lógica específica aquí)
        FOR item IN SELECT * FROM jsonb_array_elements(items_array)
        LOOP
            -- Agregar el item procesado a la lista
            items_list := items_list || jsonb_build_object(
                'id', gen_random_uuid(),
                'name', item ->> 'name',
                'dosage', item ->> 'dosage',
                'instructions', item ->> 'instructions'
            );
        END LOOP;
    END IF;

    -- Devolver resultado sin guardar en BD
    result := jsonb_build_object(
        'success', true,
        'prescription_id', prescription_id,
        'clinic_id', payload ->> 'clinic_id',
        'mrn', payload ->> 'mrn',
        'notes', payload ->> 'notes',
        'items', items_list,
        'created_at', NOW(),
        'message', 'Receta generada exitosamente (no guardada en BD)'
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- OPCIÓN 3: Usar tabla medical_records para recetas
-- ========================================

-- Si prefieres usar la tabla medical_records existente para recetas:

CREATE OR REPLACE FUNCTION public.create_prescription_v2(payload JSONB)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    record_id UUID;
    items_array JSONB;
    item JSONB;
    items_list JSONB := '[]'::jsonb;
BEGIN
    -- Crear un record médico para la receta
    INSERT INTO public.medical_records (
        clinic_id,
        patient_id,
        date,
        department_code,
        title,
        summary,
        content_delta,
        created_by,
        locked
    ) VALUES (
        (payload ->> 'clinic_id')::uuid,
        payload ->> 'mrn',
        CURRENT_DATE,
        'RX', -- Código para recetas
        'Receta Médica',
        payload ->> 'notes',
        jsonb_build_object(
            'ops', jsonb_build_array(
                jsonb_build_object(
                    'insert', COALESCE(payload ->> 'notes', 'Receta médica')
                )
            )
        )::text,
        'Sistema', -- TODO: Obtener del contexto de autenticación
        false
    ) RETURNING id INTO record_id;

    -- Procesar items si existen
    IF payload ? 'items' AND jsonb_array_length(payload -> 'items') > 0 THEN
        items_array := payload -> 'items';
        
        -- Procesar cada item
        FOR item IN SELECT * FROM jsonb_array_elements(items_array)
        LOOP
            items_list := items_list || jsonb_build_object(
                'id', gen_random_uuid(),
                'name', item ->> 'name',
                'dosage', item ->> 'dosage',
                'instructions', item ->> 'instructions'
            );
        END LOOP;
    END IF;

    -- Devolver resultado
    result := jsonb_build_object(
        'success', true,
        'record_id', record_id,
        'prescription_id', record_id, -- Para compatibilidad
        'clinic_id', payload ->> 'clinic_id',
        'mrn', payload ->> 'mrn',
        'notes', payload ->> 'notes',
        'items', items_list,
        'created_at', NOW(),
        'message', 'Receta creada exitosamente en medical_records'
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- INSTRUCCIONES DE USO
-- ========================================

/*
OPCIÓN 1: Usar FIX_NOTES_TABLE.sql
- Ejecuta el archivo FIX_NOTES_TABLE.sql en tu base de datos
- Esto creará/corregirá la tabla notes con la columna patient_id
- La función create_prescription funcionará correctamente

OPCIÓN 2: Usar función simplificada
- Ejecuta solo la función create_prescription de este archivo
- No guarda datos en BD, solo devuelve JSON
- Útil para testing o si no necesitas persistencia

OPCIÓN 3: Usar medical_records
- Ejecuta la función create_prescription_v2
- Usa la tabla medical_records existente
- Más integrado con el sistema actual

RECOMENDACIÓN: Usa la OPCIÓN 1 (FIX_NOTES_TABLE.sql) para una solución completa.
*/
