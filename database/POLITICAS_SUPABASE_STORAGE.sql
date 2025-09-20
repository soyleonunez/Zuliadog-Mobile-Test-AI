-- ============================================
-- POLÍTICAS PARA SUPABASE STORAGE
-- ============================================
-- Ejecuta estos comandos en Supabase SQL Editor

-- 1. Crear el bucket system_files si no existe
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'system_files',
  'system_files', 
  false,  -- No público
  52428800,  -- 50MB límite
  ARRAY['application/pdf', 'image/*', 'text/*', 'application/*']
) ON CONFLICT (id) DO NOTHING;

-- 2. Política para permitir lectura anónima (para desarrollo)
CREATE POLICY "Permitir lectura anónima de system_files" ON storage.objects
FOR SELECT USING (bucket_id = 'system_files');

-- 3. Política para permitir inserción anónima (para desarrollo)
CREATE POLICY "Permitir inserción anónima en system_files" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'system_files');

-- 4. Política para permitir actualización anónima (para desarrollo)
CREATE POLICY "Permitir actualización anónima en system_files" ON storage.objects
FOR UPDATE USING (bucket_id = 'system_files');

-- 5. Política para permitir eliminación anónima (para desarrollo)
CREATE POLICY "Permitir eliminación anónima en system_files" ON storage.objects
FOR DELETE USING (bucket_id = 'system_files');

-- ============================================
-- POLÍTICAS ALTERNATIVAS (MÁS SEGURAS)
-- ============================================
-- Si prefieres políticas más restrictivas, usa estas en su lugar:

-- Política para usuarios autenticados únicamente:
-- CREATE POLICY "Solo usuarios autenticados pueden leer system_files" ON storage.objects
-- FOR SELECT USING (bucket_id = 'system_files' AND auth.role() = 'authenticated');

-- Política para usuarios autenticados con clinic_id específico:
-- CREATE POLICY "Usuarios autenticados con clinic_id específico" ON storage.objects
-- FOR SELECT USING (
--   bucket_id = 'system_files' 
--   AND auth.role() = 'authenticated'
--   AND name LIKE (auth.jwt() ->> 'clinic_id' || '/%')
-- );

-- ============================================
-- VERIFICAR POLÍTICAS
-- ============================================
-- Para verificar que las políticas están activas:
SELECT * FROM storage.policies WHERE bucket_id = 'system_files';

-- Para verificar el bucket:
SELECT * FROM storage.buckets WHERE id = 'system_files';

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Las políticas anónimas son para DESARROLLO únicamente
-- 2. En PRODUCCIÓN, usa políticas autenticadas
-- 3. Ajusta los tipos MIME según tus necesidades
-- 4. Ajusta el límite de tamaño según tus archivos
