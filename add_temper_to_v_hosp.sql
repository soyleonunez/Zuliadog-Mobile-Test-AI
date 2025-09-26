-- AGREGAR TEMPER A v_hosp existente
-- =================================

-- 1. Ejecutar esto para obtener la definición actual:
-- SELECT pg_get_viewdef('v_hosp'::regclass);

-- 2. En el resultado, buscar las líneas de SELECT y agregar:
--     p.temper,

-- 3. En las líneas de GROUP BY agregar:
--     p.temper

-- 4. Ejecutar CREATE OR REPLACE VIEW v_hosp AS (.....) con solo esta modificación
