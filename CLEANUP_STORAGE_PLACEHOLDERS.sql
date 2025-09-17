-- ===============================================
-- SCRIPT DE LIMPIEZA: Eliminar placeholders de Storage
-- ===============================================
-- 
-- Este script elimina archivos .emptyFolderPlaceholder
-- que pueden estar causando problemas en el visor
--
-- ⚠️  EJECUTAR CON PRECAUCIÓN - NO SE PUEDE DESHACER
-- ===============================================

-- 1. Verificar placeholders existentes
SELECT 
    name,
    bucket_id,
    created_at,
    updated_at
FROM storage.objects 
WHERE name LIKE '%.emptyFolderPlaceholder'
  AND bucket_id = (SELECT id FROM storage.buckets WHERE name = 'system_files');

-- 2. Eliminar placeholders (descomenta para ejecutar)
-- DELETE FROM storage.objects
-- WHERE name LIKE '%.emptyFolderPlaceholder'
--   AND bucket_id = (SELECT id FROM storage.buckets WHERE name = 'system_files');

-- 3. Verificar limpieza
-- SELECT COUNT(*) as remaining_placeholders
-- FROM storage.objects 
-- WHERE name LIKE '%.emptyFolderPlaceholder'
--   AND bucket_id = (SELECT id FROM storage.buckets WHERE name = 'system_files');

-- ===============================================
-- ALTERNATIVA: Limpiar desde el panel de Supabase
-- ===============================================
-- 
-- 1. Ve a Storage > system_files
-- 2. Busca archivos que terminen en .emptyFolderPlaceholder
-- 3. Elimínalos manualmente
-- 
-- ===============================================
