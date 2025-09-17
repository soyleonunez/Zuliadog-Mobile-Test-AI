# Configuración del Clinic ID

## 📋 Pasos para configurar tu Clinic ID

### 1. **Obtener el UUID de tu clínica**

Tienes varias opciones para obtener el UUID de tu clínica:

#### Opción A: Desde Supabase Dashboard
1. Ve a tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard)
2. Navega a **Table Editor** → **clinics** (o la tabla donde tengas las clínicas)
3. Copia el `id` de tu clínica (debe ser un UUID como `123e4567-e89b-12d3-a456-426614174000`)

#### Opción B: Crear una nueva clínica
Si no tienes una clínica creada, puedes crear una:

```sql
-- En Supabase SQL Editor
INSERT INTO clinics (name, address, phone, email, created_at)
VALUES ('Mi Clínica Veterinaria', 'Dirección de la clínica', '+1234567890', 'clinic@email.com', NOW())
RETURNING id;
```

### 2. **Actualizar la configuración**

Edita el archivo `lib/core/config.dart` y reemplaza:

```dart
static const String clinicId = 'CLINIC_UUID_AQUI';
```

Por tu UUID real:

```dart
static const String clinicId = '123e4567-e89b-12d3-a456-426614174000';
```

### 3. **Verificar la estructura de la base de datos**

Asegúrate de que tienes estas tablas en Supabase:

#### Tabla `clinics`
```sql
CREATE TABLE clinics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Tabla `documents`
```sql
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID REFERENCES clinics(id),
  name TEXT NOT NULL,
  ext TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  storage_bucket TEXT NOT NULL,
  storage_key TEXT NOT NULL,
  uploaded_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Vista `v_documents_export`
```sql
CREATE VIEW v_documents_export AS
SELECT 
  d.id as document_id,
  d.name as original_name,
  d.ext,
  d.size_bytes,
  d.storage_bucket,
  d.storage_key,
  d.created_at,
  c.id as clinic_id,
  p.id as patient_id,
  p.name as patient_name,
  p.owner_name,
  p.history_number,
  'documento' as tipo
FROM documents d
LEFT JOIN clinics c ON d.clinic_id = c.id
LEFT JOIN patients p ON d.patient_id = p.id;
```

### 4. **Configurar los buckets de Storage**

En Supabase Dashboard → **Storage**, crea estos buckets:

- `profiles` (público)
- `patients` (público)
- `medical_records` (privado)
- `billing_docs` (privado)
- `system_files` (privado)

### 5. **Probar la configuración**

Una vez configurado, la aplicación debería:

1. ✅ Conectarse a Supabase sin errores
2. ✅ Mostrar el visor médico sin errores
3. ✅ Poder indexar archivos del inbox
4. ✅ Listar documentos correctamente

## 🔧 Troubleshooting

### Error: "Clinic not found"
- Verifica que el `clinicId` sea correcto
- Asegúrate de que la clínica existe en la tabla `clinics`

### Error: "Bucket not found"
- Verifica que los buckets estén creados en Supabase Storage
- Revisa los nombres de los buckets en `AppConfig.storageBuckets`

### Error: "View not found"
- Crea la vista `v_documents_export` con el SQL proporcionado
- Verifica que la vista tenga los permisos correctos

## 📝 Notas importantes

- El `clinicId` debe ser un UUID válido
- Los buckets deben existir antes de usar la aplicación
- La vista `v_documents_export` es necesaria para listar documentos
- Los permisos de RLS (Row Level Security) deben estar configurados correctamente
