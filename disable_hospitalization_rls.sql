-- Deshabilitar temporalmente RLS para tablas de hospitalización
-- Esto permitirá que la inserción funcione mientras verificamos el problema

-- ============================================
-- DESHABILITAR RLS TEMPORALMENTE
-- ============================================

-- Deshabilitar RLS para hospitalization
ALTER TABLE public.hospitalization DISABLE ROW LEVEL SECURITY;

-- Deshabilitar RLS para tasks
ALTER TABLE public.tasks DISABLE ROW LEVEL SECURITY;

-- Deshabilitar RLS para notes
ALTER TABLE public.notes DISABLE ROW LEVEL SECURITY;

-- Deshabilitar RLS para completions
ALTER TABLE public.completions DISABLE ROW LEVEL SECURITY;

-- ============================================
-- VERIFICAR ESTADO
-- ============================================

-- Verificar que RLS esté deshabilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('hospitalization', 'tasks', 'notes', 'completions')
AND schemaname = 'public';

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON TABLE public.hospitalization IS 'RLS temporalmente deshabilitado para permitir inserción';
COMMENT ON TABLE public.tasks IS 'RLS temporalmente deshabilitado para permitir inserción';
COMMENT ON TABLE public.notes IS 'RLS temporalmente deshabilitado para permitir inserción';
COMMENT ON TABLE public.completions IS 'RLS temporalmente deshabilitado para permitir inserción';
