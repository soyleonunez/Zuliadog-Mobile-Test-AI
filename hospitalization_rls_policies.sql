-- Políticas RLS para tablas de hospitalización
-- Permite a usuarios autenticados insertar, leer, actualizar y eliminar datos

-- ============================================
-- TABLA: hospitalization
-- ============================================

-- Habilitar RLS
ALTER TABLE public.hospitalization ENABLE ROW LEVEL SECURITY;

-- Política para SELECT (lectura)
CREATE POLICY "hospitalization_select_authenticated" ON public.hospitalization
    FOR SELECT
    TO authenticated
    USING (true);

-- Política para INSERT (inserción)
CREATE POLICY "hospitalization_insert_authenticated" ON public.hospitalization
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Política para UPDATE (actualización)
CREATE POLICY "hospitalization_update_authenticated" ON public.hospitalization
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Política para DELETE (eliminación)
CREATE POLICY "hospitalization_delete_authenticated" ON public.hospitalization
    FOR DELETE
    TO authenticated
    USING (true);

-- ============================================
-- TABLA: tasks
-- ============================================

-- Habilitar RLS
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Política para SELECT (lectura)
CREATE POLICY "tasks_select_authenticated" ON public.tasks
    FOR SELECT
    TO authenticated
    USING (true);

-- Política para INSERT (inserción)
CREATE POLICY "tasks_insert_authenticated" ON public.tasks
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Política para UPDATE (actualización)
CREATE POLICY "tasks_update_authenticated" ON public.tasks
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Política para DELETE (eliminación)
CREATE POLICY "tasks_delete_authenticated" ON public.tasks
    FOR DELETE
    TO authenticated
    USING (true);

-- ============================================
-- TABLA: notes
-- ============================================

-- Habilitar RLS
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- Política para SELECT (lectura)
CREATE POLICY "notes_select_authenticated" ON public.notes
    FOR SELECT
    TO authenticated
    USING (true);

-- Política para INSERT (inserción)
CREATE POLICY "notes_insert_authenticated" ON public.notes
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Política para UPDATE (actualización)
CREATE POLICY "notes_update_authenticated" ON public.notes
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Política para DELETE (eliminación)
CREATE POLICY "notes_delete_authenticated" ON public.notes
    FOR DELETE
    TO authenticated
    USING (true);

-- ============================================
-- TABLA: completions
-- ============================================

-- Habilitar RLS
ALTER TABLE public.completions ENABLE ROW LEVEL SECURITY;

-- Política para SELECT (lectura)
CREATE POLICY "completions_select_authenticated" ON public.completions
    FOR SELECT
    TO authenticated
    USING (true);

-- Política para INSERT (inserción)
CREATE POLICY "completions_insert_authenticated" ON public.completions
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Política para UPDATE (actualización)
CREATE POLICY "completions_update_authenticated" ON public.completions
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Política para DELETE (eliminación)
CREATE POLICY "completions_delete_authenticated" ON public.completions
    FOR DELETE
    TO authenticated
    USING (true);

-- ============================================
-- VISTAS PÚBLICAS
-- ============================================

-- NOTA: Las vistas públicas (v_hosp, v_app) no necesitan políticas RLS
-- ya que son vistas que consolidan datos de tablas con RLS habilitado

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON POLICY "hospitalization_select_authenticated" ON public.hospitalization IS 'Permite a usuarios autenticados leer registros de hospitalización';
COMMENT ON POLICY "hospitalization_insert_authenticated" ON public.hospitalization IS 'Permite a usuarios autenticados insertar registros de hospitalización';
COMMENT ON POLICY "hospitalization_update_authenticated" ON public.hospitalization IS 'Permite a usuarios autenticados actualizar registros de hospitalización';
COMMENT ON POLICY "hospitalization_delete_authenticated" ON public.hospitalization IS 'Permite a usuarios autenticados eliminar registros de hospitalización';

COMMENT ON POLICY "tasks_select_authenticated" ON public.tasks IS 'Permite a usuarios autenticados leer tareas';
COMMENT ON POLICY "tasks_insert_authenticated" ON public.tasks IS 'Permite a usuarios autenticados insertar tareas';
COMMENT ON POLICY "tasks_update_authenticated" ON public.tasks IS 'Permite a usuarios autenticados actualizar tareas';
COMMENT ON POLICY "tasks_delete_authenticated" ON public.tasks IS 'Permite a usuarios autenticados eliminar tareas';

COMMENT ON POLICY "notes_select_authenticated" ON public.notes IS 'Permite a usuarios autenticados leer notas';
COMMENT ON POLICY "notes_insert_authenticated" ON public.notes IS 'Permite a usuarios autenticados insertar notas';
COMMENT ON POLICY "notes_update_authenticated" ON public.notes IS 'Permite a usuarios autenticados actualizar notas';
COMMENT ON POLICY "notes_delete_authenticated" ON public.notes IS 'Permite a usuarios autenticados eliminar notas';

COMMENT ON POLICY "completions_select_authenticated" ON public.completions IS 'Permite a usuarios autenticados leer completions';
COMMENT ON POLICY "completions_insert_authenticated" ON public.completions IS 'Permite a usuarios autenticados insertar completions';
COMMENT ON POLICY "completions_update_authenticated" ON public.completions IS 'Permite a usuarios autenticados actualizar completions';
COMMENT ON POLICY "completions_delete_authenticated" ON public.completions IS 'Permite a usuarios autenticados eliminar completions';
