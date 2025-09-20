-- DEBUG_CONTENT_DELTA_ISSUE.sql
-- Script para depurar el problema de content_delta vs summary

-- 1. Verificar la estructura de la tabla medical_records
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'medical_records' 
AND column_name IN ('summary', 'content_delta', 'title')
ORDER BY ordinal_position;

-- 2. Verificar datos existentes en medical_records
SELECT 
    id,
    title,
    summary,
    content_delta,
    LENGTH(summary) as summary_length,
    LENGTH(content_delta) as content_delta_length,
    created_at
FROM medical_records 
ORDER BY created_at DESC 
LIMIT 10;

-- 3. Verificar si hay registros donde content_delta está vacío pero summary tiene contenido
SELECT 
    id,
    title,
    summary,
    content_delta,
    CASE 
        WHEN summary IS NOT NULL AND summary != '' THEN 'summary_has_content'
        ELSE 'summary_empty'
    END as summary_status,
    CASE 
        WHEN content_delta IS NOT NULL AND content_delta != '' THEN 'content_delta_has_content'
        ELSE 'content_delta_empty'
    END as content_delta_status
FROM medical_records 
WHERE (summary IS NOT NULL AND summary != '') 
   OR (content_delta IS NOT NULL AND content_delta != '')
ORDER BY created_at DESC 
LIMIT 10;

-- 4. Verificar si hay registros donde content_delta contiene el mismo contenido que summary
SELECT 
    id,
    title,
    summary,
    content_delta,
    CASE 
        WHEN summary = content_delta THEN 'SAME_CONTENT'
        WHEN summary IS NULL AND content_delta IS NULL THEN 'BOTH_NULL'
        WHEN summary IS NULL AND content_delta IS NOT NULL THEN 'SUMMARY_NULL_CONTENT_DELTA_HAS'
        WHEN summary IS NOT NULL AND content_delta IS NULL THEN 'SUMMARY_HAS_CONTENT_DELTA_NULL'
        ELSE 'DIFFERENT_CONTENT'
    END as content_comparison
FROM medical_records 
WHERE summary IS NOT NULL OR content_delta IS NOT NULL
ORDER BY created_at DESC 
LIMIT 10;

-- 5. Verificar el formato de content_delta (debería ser JSON válido)
SELECT 
    id,
    content_delta,
    CASE 
        WHEN content_delta IS NULL THEN 'NULL'
        WHEN content_delta = '' THEN 'EMPTY_STRING'
        WHEN content_delta::text ~ '^\[.*\]$' THEN 'LOOKS_LIKE_JSON_ARRAY'
        WHEN content_delta::text ~ '^\{.*\}$' THEN 'LOOKS_LIKE_JSON_OBJECT'
        ELSE 'NOT_JSON_FORMAT'
    END as content_delta_format
FROM medical_records 
WHERE content_delta IS NOT NULL
ORDER BY created_at DESC 
LIMIT 10;

-- 6. Intentar parsear content_delta como JSON para verificar si es válido
SELECT 
    id,
    content_delta,
    CASE 
        WHEN content_delta IS NULL THEN 'NULL'
        WHEN content_delta = '' THEN 'EMPTY_STRING'
        ELSE 
            CASE 
                WHEN jsonb_typeof(content_delta::jsonb) = 'array' THEN 'VALID_JSON_ARRAY'
                WHEN jsonb_typeof(content_delta::jsonb) = 'object' THEN 'VALID_JSON_OBJECT'
                ELSE 'INVALID_JSON'
            END
    END as json_validation
FROM medical_records 
WHERE content_delta IS NOT NULL AND content_delta != ''
ORDER BY created_at DESC 
LIMIT 10;
