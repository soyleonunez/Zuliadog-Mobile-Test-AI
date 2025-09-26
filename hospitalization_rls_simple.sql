-- Políticas RLS simplificadas para hospitalización
-- Primero verificar autenticación básica, luego agregar verificación de clinic_roles

-- ============================================
-- ELIMINAR POLÍTICAS EXISTENTES
-- ============================================

-- Eliminar políticas existentes de hospitalization
DROP POLICY IF EXISTS "hospitalization_all_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_select_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_insert_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_update_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_delete_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_select_members" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_insert_members" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_update_members" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_delete_members" ON public.hospitalization;

-- Eliminar políticas existentes de tasks
DROP POLICY IF EXISTS "tasks_all_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select_members" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert_members" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update_members" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete_members" ON public.tasks;

-- Eliminar políticas existentes de notes
DROP POLICY IF EXISTS "notes_all_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_select_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_insert_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_update_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_delete_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_select_members" ON public.notes;
DROP POLICY IF EXISTS "notes_insert_members" ON public.notes;
DROP POLICY IF EXISTS "notes_update_members" ON public.notes;
DROP POLICY IF EXISTS "notes_delete_members" ON public.notes;

-- Eliminar políticas existentes de completions
DROP POLICY IF EXISTS "completions_all_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_select_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_insert_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_update_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_delete_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_select_members" ON public.completions;
DROP POLICY IF EXISTS "completions_insert_members" ON public.completions;
DROP POLICY IF EXISTS "completions_update_members" ON public.completions;
DROP POLICY IF EXISTS "completions_delete_members" ON public.completions;

-- ============================================
-- CREAR POLÍTICAS RLS SIMPLES
-- ============================================

-- Políticas para hospitalization - Solo usuarios autenticados
CREATE POLICY "hospitalization_select_auth" ON public.hospitalization
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "hospitalization_insert_auth" ON public.hospitalization
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "hospitalization_update_auth" ON public.hospitalization
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "hospitalization_delete_auth" ON public.hospitalization
    FOR DELETE
    TO authenticated
    USING (true);

-- Políticas para tasks - Solo usuarios autenticados
CREATE POLICY "tasks_select_auth" ON public.tasks
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "tasks_insert_auth" ON public.tasks
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "tasks_update_auth" ON public.tasks
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "tasks_delete_auth" ON public.tasks
    FOR DELETE
    TO authenticated
    USING (true);

-- Políticas para notes - Solo usuarios autenticados
CREATE POLICY "notes_select_auth" ON public.notes
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "notes_insert_auth" ON public.notes
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "notes_update_auth" ON public.notes
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "notes_delete_auth" ON public.notes
    FOR DELETE
    TO authenticated
    USING (true);

-- Políticas para completions - Solo usuarios autenticados
CREATE POLICY "completions_select_auth" ON public.completions
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "completions_insert_auth" ON public.completions
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "completions_update_auth" ON public.completions
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "completions_delete_auth" ON public.completions
    FOR DELETE
    TO authenticated
    USING (true);

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

COMMENT ON POLICY "hospitalization_select_auth" ON public.hospitalization IS 'Permite a usuarios autenticados leer registros de hospitalización';
COMMENT ON POLICY "hospitalization_insert_auth" ON public.hospitalization IS 'Permite a usuarios autenticados insertar registros de hospitalización';
COMMENT ON POLICY "hospitalization_update_auth" ON public.hospitalization IS 'Permite a usuarios autenticados actualizar registros de hospitalización';
COMMENT ON POLICY "hospitalization_delete_auth" ON public.hospitalization IS 'Permite a usuarios autenticados eliminar registros de hospitalización';

COMMENT ON POLICY "tasks_select_auth" ON public.tasks IS 'Permite a usuarios autenticados leer tareas';
COMMENT ON POLICY "tasks_insert_auth" ON public.tasks IS 'Permite a usuarios autenticados insertar tareas';
COMMENT ON POLICY "tasks_update_auth" ON public.tasks IS 'Permite a usuarios autenticados actualizar tareas';
COMMENT ON POLICY "tasks_delete_auth" ON public.tasks IS 'Permite a usuarios autenticados eliminar tareas';

COMMENT ON POLICY "notes_select_auth" ON public.notes IS 'Permite a usuarios autenticados leer notas';
COMMENT ON POLICY "notes_insert_auth" ON public.notes IS 'Permite a usuarios autenticados insertar notas';
COMMENT ON POLICY "notes_update_auth" ON public.notes IS 'Permite a usuarios autenticados actualizar notas';
COMMENT ON POLICY "notes_delete_auth" ON public.notes IS 'Permite a usuarios autenticados eliminar notas';

COMMENT ON POLICY "completions_select_auth" ON public.completions IS 'Permite a usuarios autenticados leer completions';
COMMENT ON POLICY "completions_insert_auth" ON public.completions IS 'Permite a usuarios autenticados insertar completions';
COMMENT ON POLICY "completions_update_auth" ON public.completions IS 'Permite a usuarios autenticados actualizar completions';
COMMENT ON POLICY "completions_delete_auth" ON public.completions IS 'Permite a usuarios autenticados eliminar completions';
