-- FIX_CONTENT_DELTA_DATA.sql
-- Script para corregir datos de content_delta que puedan estar mal

-- 1. Verificar el estado actual antes de hacer cambios
SELECT 
    'BEFORE_FIX' as status,
    COUNT(*) as total_records,
    COUNT(CASE WHEN summary IS NOT NULL AND summary != '' THEN 1 END) as records_with_summary,
    COUNT(CASE WHEN content_delta IS NOT NULL AND content_delta != '' THEN 1 END) as records_with_content_delta,
    COUNT(CASE WHEN summary IS NOT NULL AND summary != '' AND content_delta IS NULL THEN 1 END) as records_summary_only,
    COUNT(CASE WHEN content_delta IS NOT NULL AND content_delta != '' AND summary IS NULL THEN 1 END) as records_content_delta_only
FROM medical_records;

-- 2. Si content_delta está vacío pero summary tiene contenido, 
--    convertir summary a formato delta y guardarlo en content_delta
--    (Solo si content_delta está realmente vacío)
UPDATE medical_records 
SET content_delta = jsonb_build_array(
    jsonb_build_object('insert', COALESCE(summary, '') || E'\n')
)
WHERE (content_delta IS NULL OR content_delta = '' OR content_delta = '[]'::jsonb)
  AND summary IS NOT NULL 
  AND summary != '';

-- 3. Si summary está vacío pero content_delta tiene contenido,
--    extraer el texto plano de content_delta y guardarlo en summary
--    (Solo si summary está realmente vacío)
UPDATE medical_records 
SET summary = CASE 
    WHEN content_delta IS NULL OR content_delta = '' THEN NULL
    WHEN jsonb_typeof(content_delta::jsonb) = 'array' THEN
        (SELECT string_agg(
            CASE 
                WHEN elem->>'insert' IS NOT NULL THEN elem->>'insert'
                ELSE ''
            END, 
            ''
        ) FROM jsonb_array_elements(content_delta::jsonb) as elem)
    ELSE NULL
END
WHERE (summary IS NULL OR summary = '')
  AND content_delta IS NOT NULL 
  AND content_delta != ''
  AND content_delta != '[]'::jsonb;

-- 4. Limpiar content_delta que contenga solo texto plano (no formato delta)
--    y convertirlo al formato correcto
UPDATE medical_records 
SET content_delta = jsonb_build_array(
    jsonb_build_object('insert', content_delta::text || E'\n')
)
WHERE content_delta IS NOT NULL 
  AND content_delta != ''
  AND content_delta != '[]'::jsonb
  AND NOT (content_delta::text ~ '^\[.*\]$')
  AND jsonb_typeof(content_delta::jsonb) != 'array';

-- 5. Verificar el estado después de los cambios
SELECT 
    'AFTER_FIX' as status,
    COUNT(*) as total_records,
    COUNT(CASE WHEN summary IS NOT NULL AND summary != '' THEN 1 END) as records_with_summary,
    COUNT(CASE WHEN content_delta IS NOT NULL AND content_delta != '' THEN 1 END) as records_with_content_delta,
    COUNT(CASE WHEN summary IS NOT NULL AND summary != '' AND content_delta IS NULL THEN 1 END) as records_summary_only,
    COUNT(CASE WHEN content_delta IS NOT NULL AND content_delta != '' AND summary IS NULL THEN 1 END) as records_content_delta_only
FROM medical_records;

-- 6. Mostrar algunos ejemplos de los datos corregidos
SELECT 
    id,
    title,
    summary,
    content_delta,
    LENGTH(summary) as summary_length,
    LENGTH(content_delta::text) as content_delta_length
FROM medical_records 
WHERE summary IS NOT NULL OR content_delta IS NOT NULL
ORDER BY created_at DESC 
LIMIT 5;
