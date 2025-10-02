/*
  # Esquema para App Móvil de Dueños de Mascotas

  ## Descripción
  Este esquema crea las tablas necesarias para una app móvil de solo lectura
  donde los dueños de mascotas pueden consultar información sobre sus mascotas,
  citas veterinarias, archivos médicos y historial.

  ## 1. Nuevas Tablas

  ### `pet_owners`
  Tabla de dueños de mascotas (usuarios de la app móvil)
  - `id` (uuid, primary key) - ID único del dueño
  - `email` (text, unique) - Email del dueño
  - `full_name` (text) - Nombre completo
  - `phone` (text) - Teléfono de contacto
  - `avatar_url` (text) - URL de foto de perfil
  - `created_at` (timestamptz) - Fecha de registro
  - `updated_at` (timestamptz) - Última actualización

  ### `pets`
  Tabla de mascotas
  - `id` (uuid, primary key) - ID único de la mascota
  - `owner_id` (uuid, foreign key) - ID del dueño
  - `name` (text) - Nombre de la mascota
  - `species` (text) - Especie (perro, gato, otro)
  - `breed` (text) - Raza
  - `gender` (text) - Género (macho, hembra)
  - `birth_date` (date) - Fecha de nacimiento
  - `weight` (numeric) - Peso en kg
  - `color` (text) - Color/descripción física
  - `photo_url` (text) - URL de foto de la mascota
  - `microchip` (text) - Número de microchip
  - `is_active` (boolean) - Estado activo/inactivo
  - `created_at` (timestamptz) - Fecha de registro
  - `updated_at` (timestamptz) - Última actualización

  ### `appointments`
  Tabla de citas veterinarias
  - `id` (uuid, primary key) - ID único de la cita
  - `pet_id` (uuid, foreign key) - ID de la mascota
  - `appointment_date` (timestamptz) - Fecha y hora de la cita
  - `appointment_type` (text) - Tipo de cita (consulta, vacuna, cirugía, etc.)
  - `veterinarian` (text) - Nombre del veterinario
  - `clinic_name` (text) - Nombre de la clínica
  - `status` (text) - Estado (programada, completada, cancelada)
  - `notes` (text) - Notas adicionales
  - `created_at` (timestamptz) - Fecha de creación

  ### `medical_files`
  Tabla de archivos médicos (PDFs, imágenes, etc.)
  - `id` (uuid, primary key) - ID único del archivo
  - `pet_id` (uuid, foreign key) - ID de la mascota
  - `file_name` (text) - Nombre del archivo
  - `file_type` (text) - Tipo de archivo (vacuna, receta, certificado, análisis)
  - `file_url` (text) - URL del archivo en storage
  - `file_size` (integer) - Tamaño en bytes
  - `description` (text) - Descripción del archivo
  - `upload_date` (timestamptz) - Fecha de carga
  - `created_at` (timestamptz) - Fecha de creación

  ### `medical_history`
  Tabla de historial médico
  - `id` (uuid, primary key) - ID único del registro
  - `pet_id` (uuid, foreign key) - ID de la mascota
  - `visit_date` (timestamptz) - Fecha de la visita
  - `visit_type` (text) - Tipo de visita (consulta, emergencia, seguimiento)
  - `diagnosis` (text) - Diagnóstico
  - `treatment` (text) - Tratamiento aplicado
  - `medications` (text) - Medicamentos recetados
  - `veterinarian` (text) - Veterinario que atendió
  - `observations` (text) - Observaciones adicionales
  - `created_at` (timestamptz) - Fecha de creación
  - `updated_at` (timestamptz) - Última actualización

  ### `veterinary_contacts`
  Tabla de contactos veterinarios
  - `id` (uuid, primary key) - ID único del contacto
  - `clinic_name` (text) - Nombre de la clínica
  - `veterinarian_name` (text) - Nombre del veterinario
  - `phone` (text) - Teléfono
  - `email` (text) - Email
  - `address` (text) - Dirección
  - `specialty` (text) - Especialidad
  - `created_at` (timestamptz) - Fecha de creación

  ## 2. Seguridad (RLS)
  - Se habilita RLS en todas las tablas
  - Los dueños solo pueden ver sus propias mascotas y datos relacionados
  - Políticas restrictivas para SELECT (solo lectura en esta fase)

  ## 3. Índices
  - Índices en claves foráneas para mejorar rendimiento de consultas
  - Índices en campos de búsqueda frecuente (email, pet owner_id, etc.)

  ## 4. Notas Importantes
  - Este es un esquema de SOLO LECTURA para la app móvil
  - La inserción de datos se realizará desde el sistema administrativo
  - Los dueños NO pueden editar información en esta versión
*/

-- =====================================================
-- CREAR TABLAS
-- =====================================================

-- Tabla de dueños de mascotas
CREATE TABLE IF NOT EXISTS pet_owners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  phone text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabla de mascotas
CREATE TABLE IF NOT EXISTS pets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES pet_owners(id) ON DELETE CASCADE,
  name text NOT NULL,
  species text NOT NULL DEFAULT 'dog',
  breed text,
  gender text,
  birth_date date,
  weight numeric(5,2),
  color text,
  photo_url text,
  microchip text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabla de citas
CREATE TABLE IF NOT EXISTS appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id uuid NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  appointment_date timestamptz NOT NULL,
  appointment_type text NOT NULL DEFAULT 'consulta',
  veterinarian text NOT NULL,
  clinic_name text DEFAULT 'Zuliadog',
  status text DEFAULT 'programada',
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Tabla de archivos médicos
CREATE TABLE IF NOT EXISTS medical_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id uuid NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_type text NOT NULL,
  file_url text NOT NULL,
  file_size integer DEFAULT 0,
  description text,
  upload_date timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Tabla de historial médico
CREATE TABLE IF NOT EXISTS medical_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id uuid NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  visit_date timestamptz NOT NULL,
  visit_type text NOT NULL DEFAULT 'consulta',
  diagnosis text,
  treatment text,
  medications text,
  veterinarian text NOT NULL,
  observations text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabla de contactos veterinarios
CREATE TABLE IF NOT EXISTS veterinary_contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_name text NOT NULL,
  veterinarian_name text NOT NULL,
  phone text,
  email text,
  address text,
  specialty text,
  created_at timestamptz DEFAULT now()
);

-- =====================================================
-- CREAR ÍNDICES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_pets_owner_id ON pets(owner_id);
CREATE INDEX IF NOT EXISTS idx_pets_is_active ON pets(is_active);
CREATE INDEX IF NOT EXISTS idx_appointments_pet_id ON appointments(pet_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_medical_files_pet_id ON medical_files(pet_id);
CREATE INDEX IF NOT EXISTS idx_medical_history_pet_id ON medical_history(pet_id);
CREATE INDEX IF NOT EXISTS idx_medical_history_visit_date ON medical_history(visit_date);

-- =====================================================
-- HABILITAR ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE pet_owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE veterinary_contacts ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- CREAR POLÍTICAS RLS (SOLO LECTURA)
-- =====================================================

-- Políticas para pet_owners
CREATE POLICY "Pet owners can view own profile"
  ON pet_owners FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Políticas para pets
CREATE POLICY "Pet owners can view own pets"
  ON pets FOR SELECT
  TO authenticated
  USING (
    owner_id IN (
      SELECT id FROM pet_owners WHERE id = auth.uid()
    )
  );

-- Políticas para appointments
CREATE POLICY "Pet owners can view appointments of own pets"
  ON appointments FOR SELECT
  TO authenticated
  USING (
    pet_id IN (
      SELECT id FROM pets WHERE owner_id = auth.uid()
    )
  );

-- Políticas para medical_files
CREATE POLICY "Pet owners can view medical files of own pets"
  ON medical_files FOR SELECT
  TO authenticated
  USING (
    pet_id IN (
      SELECT id FROM pets WHERE owner_id = auth.uid()
    )
  );

-- Políticas para medical_history
CREATE POLICY "Pet owners can view medical history of own pets"
  ON medical_history FOR SELECT
  TO authenticated
  USING (
    pet_id IN (
      SELECT id FROM pets WHERE owner_id = auth.uid()
    )
  );

-- Políticas para veterinary_contacts (públicos - todos pueden ver)
CREATE POLICY "Anyone can view veterinary contacts"
  ON veterinary_contacts FOR SELECT
  TO authenticated
  USING (true);

-- =====================================================
-- FUNCIÓN PARA ACTUALIZAR updated_at
-- =====================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'handle_updated_at'
  ) THEN
    CREATE FUNCTION handle_updated_at()
    RETURNS TRIGGER AS $func$
    BEGIN
      NEW.updated_at = now();
      RETURN NEW;
    END;
    $func$ LANGUAGE plpgsql;
  END IF;
END $$;

-- =====================================================
-- CREAR TRIGGERS
-- =====================================================

DROP TRIGGER IF EXISTS set_updated_at_pet_owners ON pet_owners;
CREATE TRIGGER set_updated_at_pet_owners
  BEFORE UPDATE ON pet_owners
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_pets ON pets;
CREATE TRIGGER set_updated_at_pets
  BEFORE UPDATE ON pets
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_medical_history ON medical_history;
CREATE TRIGGER set_updated_at_medical_history
  BEFORE UPDATE ON medical_history
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();
