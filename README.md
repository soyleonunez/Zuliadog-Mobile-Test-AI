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
- id (UUID, PK)
- name (TEXT)
- address (TEXT)
- phone (TEXT)
- email (TEXT)
- created_at (TIMESTAMP)
```

#### `patients`
```sql
- id (UUID, PK)
- clinic_id (UUID, FK)
- name (TEXT)
- mrn (TEXT, UNIQUE)
- mrn_int (INTEGER)
- species_id (UUID, FK)
- breed_id (UUID, FK)
- sex (TEXT)
- birth_date (DATE)
- created_at (TIMESTAMP)
```

#### `owners`
```sql
- id (UUID, PK)
- patient_id (UUID, FK)
- name (TEXT)
- phone (TEXT)
- email (TEXT)
- address (TEXT)
- created_at (TIMESTAMP)
```

#### `medical_records`
```sql
- id (UUID, PK)
- patient_id (UUID, FK)
- clinic_id (UUID, FK)
- content (TEXT)
- is_locked (BOOLEAN)
- locked_by (UUID, FK)
- locked_at (TIMESTAMP)
- created_at (TIMESTAMP)
```

#### `clinic_roles`
```sql
- id (UUID, PK)
- user_id (UUID, FK)
- clinic_id (UUID, FK)
- role (TEXT)
- department (TEXT)
- is_active (BOOLEAN)
- created_at (TIMESTAMP)
```

#### `breeds`
```sql
- id (TEXT, PK)
- name (TEXT)
- species (TEXT)
- image_bucket (TEXT)
- image_key (TEXT)
- image_url (TEXT)
- created_at (TIMESTAMP)
```

#### `species`
```sql
- id (UUID, PK)
- label (TEXT)
- created_at (TIMESTAMP)
```

#### `documents`
```sql
- id (UUID, PK)
- clinic_id (UUID, FK)
- patient_id (UUID, FK)
- name (TEXT)
- ext (TEXT)
- size_bytes (INTEGER)
- storage_bucket (TEXT)
- storage_key (TEXT)
- uploaded_by (UUID, FK)
- created_at (TIMESTAMP)
```

### **Vistas Principales**

#### `v_app` (Vista Principal de Pacientes)
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
LEFT JOIN owners o ON p.id = o.patient_id
LEFT JOIN species s ON p.species_id = s.id
LEFT JOIN breeds b ON p.breed_id = b.id;
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