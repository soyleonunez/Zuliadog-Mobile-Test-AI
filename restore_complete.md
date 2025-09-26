# Script Completo de Restauración

El archivo `restore_database.sql` debe ejecutarse paso a paso en Supabase SQL Editor para restaurar la base de datos.

**LO QUE ESTE SCRIPT HACE:**

✅ **Reconstruye v_app correctamente con todos los campos que la aplicación necesita**  
❌ **Elimina vista `patients_search` innecesaria**  
🔄 **Mantiene las vistas `v_dashboard`, `v_hosp` que están bien estructuradas en tu CSV**  
🧹 **Limpiar la estructura original**

**CAMPOS DEFINITIVOS QUE INCLUYE LA VISTA V_APP RESTAURADA:**

### Campos principales que la app usa para búsqueda:
- `patient_name` | ---> nombre del paciente
- `mrn` | ---> MRN de 6 dígitos
- `history_number` | ---> para la versión NEW de search que usa en historias
- `patient_id` | ---> id formal del paciente 
- `clinic_id` | ---> del clinic actual
- `owner_name` | ---> identificador para búsqueda de propietario 
- `temper`, | ---> campor temper natural
- `species_code`, `patient_species_code` y `species_label` | ---> tanto código como text
- `breed_id` y `breed_label` | ---> para search  + imagen de races
- `sex`, `birth_date`, | ---> campos secundarios necesarios
- `admission_date`, | ---> condición para filtering pacientes vistos
- `owner_lastname`, `owner_phone`, `owner_email` | ---> Propiedad columna completa
- compat finishers como `mrn_int`, `temperature`, etc.

**SEGUIR EJECUTAR INTRUCCIONES:**

1. Ejecutar SQL paso a paso:
   1. Aplica **elimination** /DROP de vistas innecesarias 
   2. Eliminar/Restaurar v_app new schema
   3. Grant permisos apropiados 
   4. Teste en la UI que selects of v_app regresan resultado

2.  Verifica permisos para que visibilidad sea correcta.

3. El **CAMPOS** queda idéntico a CSV de original con **CORRECCIONES MANUALES** donde faltaban los nombres esperados del appClient.

4. **Respaldo**. Ejecuta en desarrollo primero y backup antes que en prod.

**ERRORES OBSERVADOS Y SUS FIXES ABAJO:**

- `patients_search` fue cara­cios /innecesaria ---> SE BORRA ✅  
- `v_app` faltan campos para OK las queries de historias/home/búsquez varios......ARREGLA EL NUEVO ❇

**LISTOS PARA EJECUTE IN SQL AFTER DESCARGAR EL FILE** restore_database.sql
