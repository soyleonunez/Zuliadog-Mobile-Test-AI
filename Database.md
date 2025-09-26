# 📊 Esquema de Base de Datos - Zuliadog

## 🏥 **Tablas Principales**

### `clinics`
```sql
- id (UUID, PK) - Identificador único de la clínica
- name (TEXT) - Nombre de la clínica
- mrn_seq (BIGINT) - Secuencia para MRN
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de última actualización
```

### `patients`
```sql
- id (UUID, PK) - Identificador único del paciente
- clinic_id (UUID, FK) - ID de la clínica
- owner_id (UUID, FK) - ID del dueño
- mrn (TEXT, UNIQUE) - Medical Record Number
- mrn_int (INTEGER) - MRN como entero
- name (TEXT) - Nombre del paciente
- species_code (TEXT, FK) - Código de especie
- breed_id (UUID, FK) - ID de la raza
- sex (TEXT) - Sexo del animal
- birth_date (DATE) - Fecha de nacimiento
- weight_kg (NUMERIC) - Peso en kg
- notes (TEXT) - Notas adicionales
- photo_path (TEXT) - Ruta de la foto
- created_by (UUID, FK) - Usuario que creó el registro
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de última actualización
- history_number (TEXT) - Número de historia
- species (TEXT) - Especie (texto)
- breed (TEXT) - Raza (texto)
- owner_lastname (TEXT) - Apellido del dueño
- admission_date (DATE) - Fecha de admisión
- feeding (TEXT) - Información de alimentación
- weight (NUMERIC) - Peso
- temperature (NUMERIC) - Temperatura
- pulse (INTEGER) - Pulso
- respiration (INTEGER) - Respiración
- hydration (TEXT) - Hidratación
- temperamento (TEXT) - Temperamento
```

### `owners`
```sql
- id (UUID, PK) - Identificador único del dueño
- clinic_id (UUID, FK) - ID de la clínica
- name (TEXT) - Nombre del dueño
- phone (TEXT) - Teléfono
- email (TEXT) - Email
- address (TEXT) - Dirección
- national_id (TEXT) - Cédula/DNI
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de última actualización
```

### `medical_records`
```sql
- id (UUID, PK) - Identificador único del registro
- clinic_id (UUID, FK) - ID de la clínica
- patient_id (TEXT, FK) - MRN del paciente
- date (DATE) - Fecha del registro
- title (TEXT) - Título del registro
- summary (TEXT) - Resumen
- doctor (TEXT) - Doctor que atendió
- created_by (UUID, FK) - Usuario que creó el registro
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de última actualización
- department_code (TEXT) - Código del departamento
- locked (BOOLEAN) - Si está bloqueado
- content_delta (TEXT) - Contenido delta para editor
```

### `clinic_roles`
```sql
- clinic_id (UUID, PK) - ID de la clínica
- user_id (UUID, PK) - ID del usuario
- email (TEXT) - Email del usuario
- display_name (TEXT) - Nombre para mostrar
- role (USER_ROLE) - Rol del usuario
- is_active (BOOLEAN) - Si está activo
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de última actualización
```

### `breeds`
```sql
- id (UUID, PK) - Identificador único de la raza
- species_code (TEXT, FK) - Código de especie
- label (TEXT) - Nombre de la raza
- image_bucket (TEXT) - Bucket de la imagen
- image_key (TEXT) - Clave de la imagen
- image_url (TEXT) - URL de la imagen
```

### `species`
```sql
- code (TEXT, PK) - Código de la especie
- label (TEXT) - Nombre de la especie
```

### `documents`
```sql
- id (UUID, PK) - Identificador único del documento
- clinic_id (UUID, FK) - ID de la clínica
- patient_id (UUID, FK) - ID del paciente
- owner_id (UUID, FK) - ID del dueño
- path (TEXT) - Ruta del archivo
- doc_type (DOC_TYPE) - Tipo de documento
- tags (ARRAY) - Etiquetas
- ext (TEXT) - Extensión del archivo
- size_bytes (BIGINT) - Tamaño en bytes
- storage_bucket (TEXT) - Bucket de almacenamiento
- storage_key (TEXT) - Clave de almacenamiento
- uploaded_by (UUID, FK) - Usuario que subió el archivo
- created_at (TIMESTAMP) - Fecha de creación
- tipo (TEXT) - Tipo de documento
- paciente_id (UUID) - ID del paciente (alternativo)
- mascota_id (UUID) - ID de la mascota
- notes (TEXT) - Notas del documento
- owner_name_snapshot (TEXT) - Nombre del dueño (snapshot)
- history_number_snapshot (TEXT) - Número de historia (snapshot)
- paciente_name_snapshot (TEXT) - Nombre del paciente (snapshot)
- name (TEXT) - Nombre del archivo
- record_id (UUID, FK) - ID del registro médico
- in_lab_results (BOOLEAN) - Si está en resultados de laboratorio
- in_medical_records (BOOLEAN) - Si está en registros médicos
- in_system_files (BOOLEAN) - Si está en archivos del sistema
- mime_type (TEXT) - Tipo MIME
```

## 🏥 **Tablas de Hospitalización**

### `hospitalization_records`
```sql
- id (UUID, PK) - Identificador único del registro de hospitalización
- clinic_id (UUID, FK) - ID de la clínica
- patient_id (UUID, FK) - ID del paciente
- admission_date (TIMESTAMP) - Fecha de admisión
- discharge_date (TIMESTAMP) - Fecha de alta
- status (TEXT) - Estado (active, discharged, transferred)
- priority (TEXT) - Prioridad (low, normal, high, critical)
- room_number (TEXT) - Número de habitación
- bed_number (TEXT) - Número de cama
- diagnosis (TEXT) - Diagnóstico
- treatment_plan (TEXT) - Plan de tratamiento
- special_instructions (TEXT) - Instrucciones especiales
- assigned_vet (UUID, FK) - Veterinario asignado
- created_by (UUID, FK) - Usuario que creó el registro
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de última actualización
```

### `hospitalization_tasks`
```sql
- id (UUID, PK) - Identificador único de la tarea
- hospitalization_id (UUID, FK) - ID del registro de hospitalización
- clinic_id (UUID, FK) - ID de la clínica
- patient_id (UUID, FK) - ID del paciente
- task_type (TEXT) - Tipo de tarea (medication, feeding, exercise, monitoring, treatment, examination)
- title (TEXT) - Título de la tarea
- description (TEXT) - Descripción
- scheduled_time (TIMESTAMP) - Hora programada
- duration_minutes (INTEGER) - Duración en minutos
- frequency (TEXT) - Frecuencia (once, daily, twice_daily, every_4_hours)
- status (TEXT) - Estado (pending, in_progress, completed, cancelled)
- medication_name (TEXT) - Nombre del medicamento
- dosage (TEXT) - Dosis
- route (TEXT) - Vía de administración (oral, iv, im, subcutaneous)
- special_instructions (TEXT) - Instrucciones especiales
- completed_by (UUID, FK) - Usuario que completó la tarea
- completed_at (TIMESTAMP) - Fecha de finalización
- created_by (UUID, FK) - Usuario que creó la tarea
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de última actualización
```

### `hospitalization_notes`
```sql
- id (UUID, PK) - Identificador único de la nota
- hospitalization_id (UUID, FK) - ID del registro de hospitalización
- clinic_id (UUID, FK) - ID de la clínica
- patient_id (UUID, FK) - ID del paciente
- note_type (TEXT) - Tipo de nota (general, vital_signs, behavior, appetite, medication_response, concern, improvement)
- content (TEXT) - Contenido de la nota
- is_important (BOOLEAN) - Si es importante
- created_by (UUID, FK) - Usuario que creó la nota
- created_at (TIMESTAMP) - Fecha de creación
```

## 🔍 **Vistas Principales**

### `v_app` (Vista Principal de Pacientes)
```sql
SELECT 
  p.id as patient_id,
  p.clinic_id,
  p.name as patient_name,
  p.mrn as history_number,
  p.mrn_int,
  o.name as owner_name,
  o.phone as owner_phone,
  o.email as owner_email,
  s.label as species_label,
  b.label as breed_label,
  b.id as breed_id,
  p.sex
FROM patients p
LEFT JOIN owners o ON p.owner_id = o.id
LEFT JOIN species s ON p.species_code = s.code
LEFT JOIN breeds b ON p.breed_id = b.id;
```

### `v_hospitalization_complete` (Vista de Hospitalización)
```sql
SELECT 
  -- Datos del paciente
  p.id as patient_id,
  p.clinic_id,
  p.name as patient_name,
  p.mrn,
  p.mrn_int,
  p.sex,
  p.birth_date,
  p.species_code,
  s.label as species_label,
  p.breed_id,
  b.label as breed_label,
  b.image_url as breed_image_url,
  
  -- Datos del dueño
  o.id as owner_id,
  o.name as owner_name,
  o.phone as owner_phone,
  o.email as owner_email,
  o.address as owner_address,
  
  -- Datos de hospitalización
  hr.id as hospitalization_id,
  hr.admission_date,
  hr.discharge_date,
  hr.status as hospitalization_status,
  hr.priority,
  hr.room_number,
  hr.bed_number,
  hr.diagnosis,
  hr.treatment_plan,
  hr.special_instructions,
  hr.assigned_vet,
  hr.created_at as hospitalization_created_at,
  
  -- Veterinario asignado
  vet.email as assigned_vet_email,
  vet.raw_user_meta_data->>'display_name' as assigned_vet_name,
  
  -- Estadísticas
  (SELECT COUNT(*) FROM hospitalization_tasks ht WHERE ht.hospitalization_id = hr.id AND ht.status = 'pending') as pending_tasks,
  (SELECT COUNT(*) FROM hospitalization_tasks ht WHERE ht.hospitalization_id = hr.id AND ht.status = 'completed') as completed_tasks,
  (SELECT COUNT(*) FROM hospitalization_notes hn WHERE hn.hospitalization_id = hr.id AND hn.is_important = true) as important_notes,
  
  -- Última actualización
  GREATEST(
    hr.updated_at,
    (SELECT MAX(ht.updated_at) FROM hospitalization_tasks ht WHERE ht.hospitalization_id = hr.id),
    (SELECT MAX(hn.created_at) FROM hospitalization_notes hn WHERE hn.hospitalization_id = hr.id)
  ) as last_updated

FROM hospitalization_records hr
JOIN patients p ON hr.patient_id = p.id
LEFT JOIN owners o ON p.owner_id = o.id
LEFT JOIN species s ON p.species_code = s.code
LEFT JOIN breeds b ON p.breed_id = b.id
LEFT JOIN auth.users vet ON hr.assigned_vet = vet.id
WHERE hr.status = 'active';
```

## 🔐 **Políticas RLS**

### Principios de Seguridad
1. **Multi-tenancy**: Cada clínica solo accede a sus datos
2. **Control de acceso**: Basado en roles y departamentos
3. **Aislamiento de datos**: RLS en todas las tablas
4. **Auditoría**: Registro de todas las operaciones

### Funciones de Seguridad
```sql
-- Obtener clinic_id del usuario actual
get_user_clinic_id() RETURNS UUID

-- Verificar membresía en clínica
is_member_of(target_clinic_id UUID) RETURNS BOOLEAN

-- Obtener clinic_id actual
current_clinic_id() RETURNS UUID
```

## 🗂️ **Storage Buckets**

### `dept_files`
- **Propósito**: Archivos de departamentos
- **Visibilidad**: Privado
- **Estructura**: `{clinic_id}/departments/{department}/{file}`
- **Acceso**: Miembros del departamento

### `patients_media`
- **Propósito**: Medios de pacientes (fotos, videos)
- **Visibilidad**: Privado
- **Estructura**: `{clinic_id}/patients/{mrn}/{file}`
- **Acceso**: Personal médico autorizado

### `admin_docs`
- **Propósito**: Documentos administrativos
- **Visibilidad**: Privado
- **Estructura**: `{clinic_id}/admin/{category}/{file}`
- **Acceso**: Solo administradores

### `system`
- **Propósito**: Archivos del sistema
- **Visibilidad**: Privado
- **Estructura**: `{clinic_id}/temp/{user_id}/{file}`
- **Acceso**: Usuarios autenticados

### `med_records`
- **Propósito**: Registros médicos
- **Visibilidad**: Privado
- **Estructura**: `{clinic_id}/records/{mrn}/{file}`
- **Acceso**: Personal médico autorizado

## 📝 **Notas Importantes**

1. **Relaciones**: 
   - `patients.owner_id` → `owners.id`
   - `patients.species_code` → `species.code`
   - `patients.breed_id` → `breeds.id`
   - `medical_records.patient_id` → `patients.mrn` (TEXT)

2. **Índices**: Todas las tablas tienen índices optimizados para consultas frecuentes

3. **Triggers**: Triggers automáticos para `updated_at` en todas las tablas

4. **RLS**: Todas las tablas tienen Row Level Security habilitado

5. **Snapshots**: La tabla `documents` mantiene snapshots de nombres para auditoría

