# 🔧 **GUÍA DE LIMPIEZA DE VISTAS - ZULIADOG**

## ✅ **Estado Final Después de Restauración**

### **VISTAS QUE SE CONSERVAN:**
1. **`v_app`** - Vista principal para:
   - Búsqueda de pacientes
   - Listas generales y filtros
   - Información estándar de pacientes

2. **`v_hosp`** - Vista especializada para:
   - Funcionalidad de hospitalización
   - Dashboard de pacientes hospitalizados

### **VISTAS QUE SE ELIMINAN:**
- ❌ `patients_search` - Duplicada por `v_app`
- ❌ `v_patient_owner` - Reemplazada por joins en `v_app`
- ❌ `v_records_full` - No utilizada por la app
- ❌ `v_patient_data` - Redundante con `v_app`
- ❌ `v_dashboard` - Duplica funcionalidad de `v_hosp`
- ❌ Cualquier otra vista que no sea las dos mencionadas

## 📋 **PROCESO DE RESTAURACIÓN:**

1. **Ejecutar:** `restore_database.sql` completo
2. **Verificar:** Solo `v_app` y `v_hosp` existen
3. **Confirmar:** App funciona correctamente sin errores

## 🔍 **COMANDO DE VERIFICACIÓN FINAL:**

Después de la ejecución, para verificar que quedan solo los vistas deseadas:

```sql
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'VIEW' 
ORDER BY table_name;
```

**Resultado esperado:**
- v_app ✅
- v_hosp ✅  
- (ninguna otra vista)

## ⚠️ **ACTUALIZACIONES EN CÓDIGO:**

**Archivo actualizado:** 
- `lib/features/services/history_service.dart` → 
  - Elimina referencias a `v_patient_owner` 
  - Elimina referencias a `v_records_full`
  - Solo verifica `v_app` y `v_hosp`

**Todos los demás archivos:** Mismo comportamiento ya que todos usan `v_app` para queries estándar.
