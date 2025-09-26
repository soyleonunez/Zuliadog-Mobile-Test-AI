# 🐕 Zuliadog - Sistema de Gestión Veterinaria

## 📋 Descripción General

Zuliadog es una aplicación de escritorio desarrollada en Flutter para la gestión integral de clínicas veterinarias. Proporciona herramientas completas para el manejo de pacientes, historias médicas, hospitalización, documentos y administración de clínicas.

## 🚀 Características Principales

### 🏥 **Gestión de Pacientes**
- Registro completo de pacientes con MRN (Medical Record Number)
- Información detallada del propietario
- Búsqueda avanzada y filtros
- Gestión de especies y razas
- Imágenes automáticas de razas

### 📋 **Historias Médicas**
- Editor de texto avanzado para historias clínicas
- Bloqueo de registros para evitar ediciones simultáneas
- Exportación a PDF
- Timeline de actividades
- Gestión de archivos adjuntos

### 🏥 **Hospitalización**
- Panel de control de pacientes hospitalizados
- Vista de calendario/Gantt
- Gestión de camas y habitaciones
- Seguimiento de tratamientos

### 📁 **Gestión de Documentos**
- Sistema de buckets organizados por categorías
- Subida y descarga de archivos
- Visor integrado de PDFs
- Políticas de seguridad RLS

### 🔐 **Sistema de Autenticación**
- Login por departamentos/roles
- Control de acceso basado en clínicas
- Gestión de usuarios y permisos

## 🏗️ Arquitectura Técnica

### **Frontend**
- **Framework**: Flutter (Windows Desktop)
- **Estado**: Provider/Riverpod
- **UI**: Material Design 3
- **Navegación**: GoRouter

### **Backend**
- **Base de Datos**: Supabase (PostgreSQL)
- **Storage**: Supabase Storage
- **Autenticación**: Supabase Auth
- **API**: Supabase REST/GraphQL

### **Seguridad**
- **RLS (Row Level Security)**: Políticas de seguridad a nivel de fila
- **Multi-tenancy**: Aislamiento por clínica
- **Control de acceso**: Basado en roles y departamentos

## 📊 Estructura de Base de Datos

### **Tablas Principales**

#### `clinics`
```sql
- id (UUID, PK) - Identificador único de la clínica
- name (TEXT) - Nombre de la clínica
- mrn_seq (BIGINT) - Secuencia para MRN
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de última actualización
```

#### `patients`
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

#### `owners`
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

#### `medical_records`
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

#### `clinic_roles`
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

#### `breeds`
```sql
- id (UUID, PK) - Identificador único de la raza
- species_code (TEXT, FK) - Código de especie
- label (TEXT) - Nombre de la raza
- image_bucket (TEXT) - Bucket de la imagen
- image_key (TEXT) - Clave de la imagen
- image_url (TEXT) - URL de la imagen
```

#### `species`
```sql
- code (TEXT, PK) - Código de la especie
- label (TEXT) - Nombre de la especie
```

#### `documents`
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

### **Tablas de Sistema Integral**

#### `hospitalization` (Tabla única de hospitalización)
```sql
- id (UUID, PK) - Identificador único del registro de hospitalización
- clinic_id (UUID, FK) - ID de la clínica
- patient_id (UUID, FK) - ID del paciente
- admission_date (DATE) - Fecha de admisión
- discharge_date (DATE) - Fecha de alta
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

#### `tasks` (Tabla general de tareas)
```sql
- id (UUID, PK) - Identificador único de la tarea
- clinic_id (UUID, FK) - ID de la clínica
- patient_id (UUID, FK) - ID del paciente (opcional)
- hospitalization_id (UUID, FK) - ID de hospitalización (opcional)
- task_type (TEXT) - Tipo de tarea (medication, feeding, exercise, monitoring, treatment, examination, vaccination, surgery, consultation, follow_up, lab_test, imaging, therapy, grooming, boarding)
- title (TEXT) - Título de la tarea
- description (TEXT) - Descripción
- scheduled_time (TIMESTAMP) - Hora programada
- duration_minutes (INTEGER) - Duración en minutos
- frequency (TEXT) - Frecuencia (once, daily, twice_daily, every_4_hours, weekly, monthly)
- status (TEXT) - Estado (pending, in_progress, completed, cancelled, overdue)
- priority (TEXT) - Prioridad (low, normal, high, urgent)
- medication_name (TEXT) - Nombre del medicamento
- dosage (TEXT) - Dosis
- route (TEXT) - Vía de administración (oral, iv, im, subcutaneous, topical, inhalation)
- food_type (TEXT) - Tipo de comida
- feeding_schedule (TEXT) - Horario de alimentación
- exam_type (TEXT) - Tipo de examen
- vital_signs (JSONB) - Signos vitales
- special_instructions (TEXT) - Instrucciones especiales
- completed_by (UUID, FK) - Usuario que completó la tarea
- completed_at (TIMESTAMP) - Fecha de finalización
- created_by (UUID, FK) - Usuario que creó la tarea
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de última actualización
```

#### `notes` (Tabla general de notas)
```sql
- id (UUID, PK) - Identificador único de la nota
- clinic_id (UUID, FK) - ID de la clínica
- patient_id (UUID, FK) - ID del paciente (opcional)
- hospitalization_id (UUID, FK) - ID de hospitalización (opcional)
- task_id (UUID, FK) - ID de la tarea (opcional)
- note_type (TEXT) - Tipo de nota (general, vital_signs, behavior, appetite, medication_response, concern, improvement, observation, instruction, reminder, lab_result, imaging_result, treatment_response, owner_communication)
- content (TEXT) - Contenido de la nota
- is_important (BOOLEAN) - Si es importante
- is_private (BOOLEAN) - Si es privada
- tags (TEXT[]) - Etiquetas
- created_by (UUID, FK) - Usuario que creó la nota
- created_at (TIMESTAMP) - Fecha de creación
- updated_at (TIMESTAMP) - Fecha de última actualización
```

#### `completions` (Tabla general de completiones)
```sql
- id (UUID, PK) - Identificador único de la completión
- clinic_id (UUID, FK) - ID de la clínica
- patient_id (UUID, FK) - ID del paciente (opcional)
- task_id (UUID, FK) - ID de la tarea
- completion_type (TEXT) - Tipo de completión (task_completed, medication_administered, feeding_completed, exam_performed, treatment_given, vital_signs_taken, lab_sample_collected, imaging_completed, therapy_session)
- completion_status (TEXT) - Estado de completión (completed, partial, failed, cancelled)
- completion_notes (TEXT) - Notas de completión
- completion_data (JSONB) - Datos específicos (valores de signos vitales, etc.)
- completed_by (UUID, FK) - Usuario que completó
- completed_at (TIMESTAMP) - Fecha de completión
- created_at (TIMESTAMP) - Fecha de creación
```

### **Vistas Principales**

#### `v_app` (Vista Integral de la Aplicación)
```sql
-- Vista completa que integra pacientes, hospitalización, tareas, notas y completiones
-- Incluye estadísticas en tiempo real y última actividad
-- Optimizada para el dashboard principal
```

#### `patients_search`
```sql
-- Vista optimizada para búsquedas de pacientes
-- Incluye información completa del paciente y propietario
-- Optimizada con índices para búsquedas rápidas
```

## 🗂️ Estructura de Storage (Buckets)

### **dept_files**
- **Propósito**: Archivos de departamentos
- **Visibilidad**: Privado
- **Estructura**: `{clinic_id}/departments/{department}/{file}`
- **Acceso**: Miembros del departamento

### **patients_media**
- **Propósito**: Medios de pacientes (fotos, videos)
- **Visibilidad**: Privado
- **Estructura**: `{clinic_id}/patients/{mrn}/{file}`
- **Acceso**: Personal médico autorizado

### **admin_docs**
- **Propósito**: Documentos administrativos
- **Visibilidad**: Privado
- **Estructura**: `{clinic_id}/admin/{category}/{file}`
- **Acceso**: Solo administradores

### **system**
- **Propósito**: Archivos del sistema
- **Visibilidad**: Privado
- **Estructura**: `{clinic_id}/temp/{user_id}/{file}`
- **Acceso**: Usuarios autenticados

### **med_records**
- **Propósito**: Registros médicos
- **Visibilidad**: Privado
- **Estructura**: `{clinic_id}/records/{mrn}/{file}`
- **Acceso**: Personal médico autorizado

## 🔐 Políticas de Seguridad (RLS)

### **Principios de Seguridad**
1. **Multi-tenancy**: Cada clínica solo accede a sus datos
2. **Control de acceso**: Basado en roles y departamentos
3. **Aislamiento de datos**: RLS en todas las tablas
4. **Auditoría**: Registro de todas las operaciones

### **Funciones de Seguridad**
```sql
-- Obtener clinic_id del usuario actual
get_user_clinic_id() RETURNS UUID

-- Verificar membresía en clínica
is_member_of(target_clinic_id UUID) RETURNS BOOLEAN

-- Obtener clinic_id actual
current_clinic_id() RETURNS UUID
```

### **Políticas RLS Implementadas**
- **SELECT**: Solo miembros de la clínica
- **INSERT**: Solo miembros activos
- **UPDATE**: Solo miembros autorizados
- **DELETE**: Solo administradores

## 🚀 Instalación y Configuración

### **Requisitos del Sistema**
- Windows 10/11 (64-bit)
- Flutter SDK 3.0+
- Visual Studio Build Tools
- Inno Setup (para crear instalador)

### **Configuración de Supabase**
1. Crear proyecto en Supabase
2. Configurar las tablas según el esquema
3. Crear los buckets de storage
4. Configurar políticas RLS
5. Obtener URL y API Key

### **Configuración de la Aplicación**
1. Editar `lib/core/config.dart`
2. Configurar `clinicId` y credenciales de Supabase
3. Compilar con `flutter build windows --release`
4. Crear instalador con Inno Setup

### **Scripts de Automatización**
- `build_and_install.bat`: Compilación y creación de instalador
- `cambiar_icono.bat`: Cambio de iconos de la aplicación

## 📁 Estructura del Proyecto

```
lib/
├── auth/                    # Autenticación y login
├── core/                    # Configuración y utilidades
├── features/                # Funcionalidades principales
│   ├── data/               # Servicios de datos
│   ├── services/           # Servicios de negocio
│   ├── utilities/          # Utilidades de la aplicación
│   └── widgets/            # Widgets reutilizables
├── test_storage_access.dart # Pruebas de storage
└── main.dart               # Punto de entrada
```

## 🧪 Pruebas y Verificación

### **Pruebas de Storage**
- Integradas en el botón reload del home
- Verificación de acceso a todos los buckets
- Pruebas de RLS y permisos

### **Pruebas de Conexión**
- Verificación de conectividad con Supabase
- Validación de autenticación
- Pruebas de consultas a base de datos

## 🔧 Desarrollo

### **Comandos Útiles**
```bash
# Desarrollo
flutter run -d windows

# Compilación
flutter build windows --release

# Limpieza
flutter clean

# Análisis de código
flutter analyze
```

### **Estructura de Código**
- **Servicios**: Lógica de negocio y conexión con Supabase
- **Widgets**: Componentes reutilizables de UI
- **Utilities**: Funcionalidades específicas de la aplicación
- **Data**: Gestión de datos y repositorios

## 📝 Notas de Desarrollo

### **Características Implementadas**
- ✅ Sistema de autenticación completo
- ✅ Gestión de pacientes con MRN
- ✅ Editor de historias médicas
- ✅ Sistema de hospitalización
- ✅ Gestión de documentos
- ✅ Políticas RLS implementadas
- ✅ Multi-tenancy por clínica
- ✅ Imágenes automáticas de razas
- ✅ Exportación a PDF
- ✅ Visor de documentos integrado

### **Próximas Mejoras**
- 🔄 Sistema de notificaciones
- 🔄 Reportes avanzados
- 🔄 Integración con sistemas de facturación
- 🔄 App móvil complementaria
- 🔄 API REST para integraciones

## 📞 Soporte

Para soporte técnico o consultas sobre el desarrollo:
- Revisar la documentación en `/docs`
- Verificar logs en la consola de la aplicación
- Comprobar configuración de Supabase
- Validar políticas RLS

---

**Zuliadog** - Sistema de Gestión Veterinaria Profesional 🐕‍🦺