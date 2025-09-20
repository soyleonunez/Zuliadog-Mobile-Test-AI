# Base de Datos - Zuliadog

Esta carpeta contiene todos los scripts SQL para la configuración y mantenimiento de la base de datos Supabase del sistema Zuliadog.

## Archivos de Scripts

### 🔧 **Scripts de Configuración Inicial**
- `CREATE_GET_MEDICAL_RECORDS_RPC.sql` - Función RPC para obtener registros médicos
- `ALTERNATIVE_PRESCRIPTION_FUNCTION.sql` - Función alternativa para prescripciones
- `CREATE_PATIENTS_SEARCH_VIEW.sql` - Vista optimizada para búsqueda de pacientes

### 🔒 **Scripts de Seguridad (RLS)**
- `DISABLE_RLS_TEMPORARILY.sql` - Deshabilitar RLS temporalmente
- `FIX_RLS_POLICIES.sql` - Corregir políticas RLS
- `FIX_CLINIC_ROLES_RLS.sql` - Corregir roles de clínica en RLS
- `POLITICAS_SUPABASE_STORAGE.sql` - Políticas de almacenamiento

### 🛠️ **Scripts de Corrección**
- `FIX_POLICIES.sql` - Corregir políticas generales
- `FIX_NOTES_TABLE.sql` - Corregir tabla de notas
- `UPDATE_CLINIC_ROLES_REFERENCES.sql` - Actualizar referencias de roles
- `FIX_CONTENT_DELTA_DATA.sql` - Corregir datos de content_delta vs summary

### 🔍 **Scripts de Depuración**
- `DEBUG_CONTENT_DELTA_ISSUE.sql` - Depurar problema de content_delta vs summary

### 🧹 **Scripts de Limpieza**
- `CLEANUP_STORAGE_PLACEHOLDERS.sql` - Limpiar placeholders de almacenamiento

## Uso

1. **Ejecutar en orden**: Los scripts deben ejecutarse en el orden lógico según las dependencias
2. **Backup**: Siempre hacer backup antes de ejecutar scripts de modificación
3. **Testing**: Probar en ambiente de desarrollo antes de producción

## Estructura de la Base de Datos

### Tablas Principales
- `patients` - Información de pacientes
- `medical_records` - Historias médicas
- `clinic_roles` - Roles de clínica
- `prescriptions` - Prescripciones médicas

### Vistas
- `patients_search` - Vista optimizada para búsqueda de pacientes con etiquetas en español

### Funciones RPC
- `get_medical_records()` - Obtener historias médicas
- `alternative_prescription_function()` - Función de prescripciones

## Notas Importantes

- ⚠️ **RLS**: Row Level Security está habilitado por defecto
- 🔐 **Permisos**: Verificar permisos antes de ejecutar scripts
- 📝 **Logs**: Revisar logs de Supabase después de ejecutar scripts
- 🔄 **Rollback**: Tener scripts de rollback preparados

## Contacto

Para dudas sobre la base de datos, contactar al equipo de desarrollo.
