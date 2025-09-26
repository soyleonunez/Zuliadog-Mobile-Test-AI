-- Políticas RLS que respetan el sistema de autenticación con clinic_roles
-- Verifica que el usuario esté autenticado y tenga un rol válido

-- ============================================
-- ELIMINAR POLÍTICAS EXISTENTES
-- ============================================

-- Eliminar políticas existentes de hospitalization
DROP POLICY IF EXISTS "hospitalization_all_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_select_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_insert_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_update_authenticated" ON public.hospitalization;
DROP POLICY IF EXISTS "hospitalization_delete_authenticated" ON public.hospitalization;

-- Eliminar políticas existentes de tasks
DROP POLICY IF EXISTS "tasks_all_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update_authenticated" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete_authenticated" ON public.tasks;

-- Eliminar políticas existentes de notes
DROP POLICY IF EXISTS "notes_all_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_select_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_insert_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_update_authenticated" ON public.notes;
DROP POLICY IF EXISTS "notes_delete_authenticated" ON public.notes;

-- Eliminar políticas existentes de completions
DROP POLICY IF EXISTS "completions_all_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_select_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_insert_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_update_authenticated" ON public.completions;
DROP POLICY IF EXISTS "completions_delete_authenticated" ON public.completions;

-- ============================================
-- FUNCIÓN AUXILIAR PARA VERIFICAR ROL
-- ============================================

-- Función para verificar si el usuario tiene un rol válido en clinic_roles
CREATE OR REPLACE FUNCTION is_clinic_member()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.clinic_roles 
    WHERE user_id = auth.uid() 
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- CREAR POLÍTICAS RLS CON AUTENTICACIÓN
-- ============================================

-- Políticas para hospitalization
CREATE POLICY "hospitalization_select_members" ON public.hospitalization
    FOR SELECT
    TO authenticated
    USING (is_clinic_member());

CREATE POLICY "hospitalization_insert_members" ON public.hospitalization
    FOR INSERT
    TO authenticated
    WITH CHECK (is_clinic_member());

CREATE POLICY "hospitalization_update_members" ON public.hospitalization
    FOR UPDATE
    TO authenticated
    USING (is_clinic_member())
    WITH CHECK (is_clinic_member());

CREATE POLICY "hospitalization_delete_members" ON public.hospitalization
    FOR DELETE
    TO authenticated
    USING (is_clinic_member());

-- Políticas para tasks
CREATE POLICY "tasks_select_members" ON public.tasks
    FOR SELECT
    TO authenticated
    USING (is_clinic_member());

CREATE POLICY "tasks_insert_members" ON public.tasks
    FOR INSERT
    TO authenticated
    WITH CHECK (is_clinic_member());

CREATE POLICY "tasks_update_members" ON public.tasks
    FOR UPDATE
    TO authenticated
    USING (is_clinic_member())
    WITH CHECK (is_clinic_member());

CREATE POLICY "tasks_delete_members" ON public.tasks
    FOR DELETE
    TO authenticated
    USING (is_clinic_member());

-- Políticas para notes
CREATE POLICY "notes_select_members" ON public.notes
    FOR SELECT
    TO authenticated
    USING (is_clinic_member());

CREATE POLICY "notes_insert_members" ON public.notes
    FOR INSERT
    TO authenticated
    WITH CHECK (is_clinic_member());

CREATE POLICY "notes_update_members" ON public.notes
    FOR UPDATE
    TO authenticated
    USING (is_clinic_member())
    WITH CHECK (is_clinic_member());

CREATE POLICY "notes_delete_members" ON public.notes
    FOR DELETE
    TO authenticated
    USING (is_clinic_member());

-- Políticas para completions
CREATE POLICY "completions_select_members" ON public.completions
    FOR SELECT
    TO authenticated
    USING (is_clinic_member());

CREATE POLICY "completions_insert_members" ON public.completions
    FOR INSERT
    TO authenticated
    WITH CHECK (is_clinic_member());

CREATE POLICY "completions_update_members" ON public.completions
    FOR UPDATE
    TO authenticated
    USING (is_clinic_member())
    WITH CHECK (is_clinic_member());

CREATE POLICY "completions_delete_members" ON public.completions
    FOR DELETE
    TO authenticated
    USING (is_clinic_member());

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

COMMENT ON FUNCTION is_clinic_member() IS 'Verifica si el usuario autenticado tiene un rol válido en clinic_roles';
COMMENT ON POLICY "hospitalization_select_members" ON public.hospitalization IS 'Permite a miembros de clínica leer registros de hospitalización';
COMMENT ON POLICY "hospitalization_insert_members" ON public.hospitalization IS 'Permite a miembros de clínica insertar registros de hospitalización';
COMMENT ON POLICY "hospitalization_update_members" ON public.hospitalization IS 'Permite a miembros de clínica actualizar registros de hospitalización';
COMMENT ON POLICY "hospitalization_delete_members" ON public.hospitalization IS 'Permite a miembros de clínica eliminar registros de hospitalización';

COMMENT ON POLICY "tasks_select_members" ON public.tasks IS 'Permite a miembros de clínica leer tareas';
COMMENT ON POLICY "tasks_insert_members" ON public.tasks IS 'Permite a miembros de clínica insertar tareas';
COMMENT ON POLICY "tasks_update_members" ON public.tasks IS 'Permite a miembros de clínica actualizar tareas';
COMMENT ON POLICY "tasks_delete_members" ON public.tasks IS 'Permite a miembros de clínica eliminar tareas';

COMMENT ON POLICY "notes_select_members" ON public.notes IS 'Permite a miembros de clínica leer notas';
COMMENT ON POLICY "notes_insert_members" ON public.notes IS 'Permite a miembros de clínica insertar notas';
COMMENT ON POLICY "notes_update_members" ON public.notes IS 'Permite a miembros de clínica actualizar notas';
COMMENT ON POLICY "notes_delete_members" ON public.notes IS 'Permite a miembros de clínica eliminar notas';

COMMENT ON POLICY "completions_select_members" ON public.completions IS 'Permite a miembros de clínica leer completions';
COMMENT ON POLICY "completions_insert_members" ON public.completions IS 'Permite a miembros de clínica insertar completions';
COMMENT ON POLICY "completions_update_members" ON public.completions IS 'Permite a miembros de clínica actualizar completions';
COMMENT ON POLICY "completions_delete_members" ON public.completions IS 'Permite a miembros de clínica eliminar completions';
