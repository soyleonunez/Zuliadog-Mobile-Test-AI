-- ============================================
-- SOLUCIÓN RÁPIDA PARA POLÍTICAS RLS
-- ============================================
-- Ejecuta estos comandos en Supabase SQL Editor

-- 1. Eliminar políticas existentes problemáticas
DROP POLICY IF EXISTS "Permitir lectura anónima de system_files" ON storage.objects;
DROP POLICY IF EXISTS "Permitir inserción anónima en system_files" ON storage.objects;
DROP POLICY IF EXISTS "Permitir actualización anónima en system_files" ON storage.objects;
DROP POLICY IF EXISTS "Permitir eliminación anónima en system_files" ON storage.objects;

-- 2. Crear política simple que permita TODO para system_files
CREATE POLICY "Acceso completo a system_files para desarrollo" ON storage.objects
FOR ALL USING (bucket_id = 'system_files');

-- 3. Verificar que el bucket existe
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'system_files',
  'system_files', 
  false,  -- No público
  52428800,  -- 50MB límite
  ARRAY['application/pdf', 'image/*', 'text/*', 'application/*']
) ON CONFLICT (id) DO NOTHING;

-- 4. Verificar políticas
SELECT * FROM storage.policies WHERE bucket_id = 'system_files';

-- ============================================
-- ALTERNATIVA: HACER BUCKET PÚBLICO
-- ============================================
-- Si las políticas no funcionan, puedes hacer el bucket público:
-- UPDATE storage.buckets SET public = true WHERE id = 'system_files';
