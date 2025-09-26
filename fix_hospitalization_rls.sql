-- Corregir políticas RLS para hospitalización
-- Eliminar políticas existentes y crear nuevas más permisivas

-- ============================================
-- ELIMINAR POLÍTICAS EXISTENTES
-- ============================================

-- Eliminar políticas existentes de hospitalization
DROP POLICY IF EXISTS "hospitalization_select_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_insert_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_update_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_delete_authenticated" ON public.hospitalization;

-- Eliminar políticas existentes de tasks
DROP POLICY IF EXISTS "tasks_select_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete_authenticated" ON public.tasks;

-- Eliminar políticas existentes de notes
DROP POLICY IF EXISTS "notes_select_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_insert_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_update_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_delete_authenticated" ON public.notes;

-- Eliminar políticas existentes de completions
DROP POLICY IF EXISTS "completions_select_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_insert_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_update_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_delete_authenticated" ON public.completions;

-- ============================================
-- CREAR NUEVAS POLÍTICAS MÁS PERMISIVAS
-- ============================================

-- Políticas para hospitalization
CREATE POLICY "hospitalization_all_authenticated" ON public.hospitalization
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Políticas para tasks
CREATE POLICY "tasks_all_authenticated" ON public.tasks
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Políticas para notes
CREATE POLICY "notes_all_authenticated" ON public.notes
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Políticas para completions
CREATE POLICY "completions_all_authenticated" ON public.completions
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ============================================
-- VERIFICAR RLS HABILITADO
-- ============================================

-- Asegurar que RLS esté habilitado
ALTER TABLE public.hospitalization ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON POLICY "hospitalization_all_authenticated" ON public.hospitalization IS 'Política permisiva para usuarios autenticados en hospitalization';
COMMENT ON POLICY "tasks_all_authenticated" ON public.tasks IS 'Política permisiva para usuarios autenticados en tasks';
COMMENT ON POLICY "notes_all_authenticated" ON public.notes IS 'Política permisiva para usuarios autenticados en notes';
COMMENT ON POLICY "completions_all_authenticated" ON public.completions IS 'Política permisiva para usuarios autenticados en completions';
