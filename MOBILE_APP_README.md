# PawCare - App Móvil para Dueños de Mascotas

## Descripción General

Prototipo de aplicación móvil Flutter diseñada para que los dueños de mascotas puedan consultar información médica, citas veterinarias, archivos y perfiles de sus mascotas desde sus dispositivos móviles.

Esta es una **versión de solo lectura** enfocada en proporcionar una experiencia visual moderna y accesible inspirada en aplicaciones como Paw Buddy y diseños minimalistas tipo 21st gallery.

---

## 🎨 Características de Diseño

### Estilo Visual
- **Paleta de colores**: Tonos azules modernos con acentos verdes y cálidos
- **Tipografía**: Inter (Google Fonts) con pesos variables
- **Componentes**: Cards con sombras suaves, bordes redondeados (16px), animaciones fluidas
- **Tema**: Claro, minimalista, con alto contraste para accesibilidad

### Animaciones
- Transiciones suaves entre pantallas
- Cards con animación de fade-in y slide-up
- Efectos de escala al presionar elementos interactivos
- Shimmer loading para estados de carga

---

## 📱 Pantallas Implementadas

### 1. **Onboarding** (`mobile_onboarding_screen.dart`)
- 3 pantallas de bienvenida con paginación
- Animaciones de entrada con Flutter Animate
- Botones de "Siguiente" y "Saltar"

### 2. **Dashboard** (`mobile_dashboard_screen.dart`)
- Saludo personalizado basado en hora del día
- Cards estadísticas: Mascotas, Citas próximas, Archivos totales
- Accesos rápidos: Nueva cita, Contactar veterinario
- Lista de próximas citas con información de mascota

### 3. **Mis Mascotas** (`mobile_pets_screen.dart`)
- Carrusel horizontal con fotos de mascotas
- Lista completa con información detallada (edad, peso, género)
- Navegación a detalle de cada mascota

### 4. **Detalle de Mascota** (`mobile_pet_detail_screen.dart`)
- Header con foto de mascota (expandible)
- Cards de información: Edad, Peso, Género
- Tabs: Historial Médico y Citas
- Visualización cronológica de visitas y tratamientos

### 5. **Archivos** (`mobile_files_screen.dart`)
- Filtros por tipo: Todos, Vacunas, Recetas, Análisis, Certificados
- Estadísticas de archivos almacenados
- Lista de documentos con íconos según tipo
- Información de tamaño y fecha de carga

### 6. **Perfil** (`mobile_profile_screen.dart`)
- Información del dueño (foto, nombre, contacto)
- Lista de contactos veterinarios
- Opciones de configuración
- Botón de cerrar sesión

---

## 🗄️ Estructura de Base de Datos

### Tablas Principales

#### `pet_owners`
Dueños de mascotas (usuarios de la app)
- id, email, full_name, phone, avatar_url
- created_at, updated_at

#### `pets`
Mascotas registradas
- id, owner_id, name, species, breed, gender
- birth_date, weight, color, photo_url, microchip
- is_active, created_at, updated_at

#### `appointments`
Citas veterinarias
- id, pet_id, appointment_date, appointment_type
- veterinarian, clinic_name, status, notes

#### `medical_files`
Archivos médicos (PDFs, imágenes)
- id, pet_id, file_name, file_type, file_url
- file_size, description, upload_date

#### `medical_history`
Historial de visitas médicas
- id, pet_id, visit_date, visit_type
- diagnosis, treatment, medications
- veterinarian, observations

#### `veterinary_contacts`
Contactos de veterinarios
- id, clinic_name, veterinarian_name
- phone, email, address, specialty

### Seguridad (RLS)
Todas las tablas tienen Row Level Security habilitado:
- Los dueños solo pueden ver datos de sus propias mascotas
- Políticas restrictivas de solo SELECT
- Los contactos veterinarios son públicos (visibles para todos)

---

## 🔧 Servicios y Conexión de Datos

### `MobileDataService` (`lib/mobile/services/mobile_data_service.dart`)

Servicio de datos con métodos de solo lectura:

```dart
// Obtener información del dueño
getPetOwner(String ownerId)

// Listar mascotas del dueño
getPetsByOwner(String ownerId)

// Obtener mascota por ID
getPetById(String petId)

// Citas próximas
getUpcomingAppointments(String ownerId)

// Citas por mascota
getAllAppointmentsByPet(String petId)

// Archivos médicos
getMedicalFilesByPet(String petId)
getAllMedicalFilesByOwner(String ownerId)

// Historial médico
getMedicalHistoryByPet(String petId)

// Contactos veterinarios
getVeterinaryContacts()

// Estadísticas para dashboard
getDashboardStats(String ownerId)
```

---

## 🎯 Integración con APIs Reales (Próximos Pasos)

### Conexión Actual
- Datos de prueba insertados en Supabase
- ID de dueño hardcoded: `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11`
- Consultas mediante Supabase client

### Para Conectar APIs Reales:

1. **Autenticación de Usuario**
   ```dart
   // Implementar login con Supabase Auth
   final response = await Supabase.instance.client.auth.signInWithPassword(
     email: email,
     password: password,
   );

   // Usar el ID del usuario autenticado
   final userId = Supabase.instance.client.auth.currentUser?.id;
   ```

2. **Reemplazar Owner ID Hardcoded**
   - En cada pantalla, obtener `ownerId` del usuario autenticado
   - Guardar en estado global (Provider, Riverpod, etc.)

3. **Manejo de Archivos**
   - Usar Supabase Storage para subir/descargar PDFs
   - Implementar visor de PDF in-app
   - Cache local de archivos descargados

4. **Notificaciones Push**
   - Integrar Firebase Cloud Messaging
   - Notificar citas próximas (24h antes)
   - Recordatorios de vacunas

5. **Sincronización Offline**
   - Implementar cache con `sqflite` o `hive`
   - Sincronizar cuando haya conexión
   - Indicador de estado de sincronización

---

## 🚀 Cómo Ejecutar el Prototipo

### Requisitos
- Flutter 3.3.0 o superior
- Dart SDK
- Cuenta de Supabase configurada (ya incluida en el código)

### Pasos

1. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

2. **Ejecutar en dispositivo/emulador**
   ```bash
   flutter run
   ```

3. **Para compilar release**
   ```bash
   # Android
   flutter build apk --release

   # iOS
   flutter build ios --release
   ```

### Datos de Prueba
El prototipo incluye datos de muestra:
- **Dueño**: María González
- **Mascotas**: Max (Golden Retriever), Luna (Siamés), Rocky (Bulldog Francés)
- **Citas**: 4 citas programadas
- **Archivos**: Certificados, análisis, recetas
- **Historial**: 4 visitas médicas previas

---

## 📦 Componentes Reutilizables

### `AnimatedCard` (`lib/mobile/widgets/animated_card.dart`)
Card con animaciones de entrada y efecto de presión

```dart
AnimatedCard(
  delay: 100,
  onTap: () {},
  child: YourContent(),
)
```

### `ShimmerLoading` (`lib/mobile/widgets/shimmer_loading.dart`)
Skeleton loader con efecto shimmer

```dart
ShimmerLoading(
  width: double.infinity,
  height: 100,
  borderRadius: BorderRadius.circular(16),
)
```

### `MobileTheme` (`lib/mobile/core/mobile_theme.dart`)
Tema centralizado con colores, tipografía y estilos

```dart
MobileTheme.primaryColor
MobileTheme.cardShadow()
MobileTheme.primaryGradient()
```

---

## 🎨 Paleta de Colores

| Color | Hex | Uso |
|-------|-----|-----|
| Primary | `#2D6BFF` | Botones principales, acentos |
| Secondary | `#6C63FF` | Gradientes, elementos secundarios |
| Accent | `#FF6584` | Alertas, elementos destacados |
| Background | `#F8F9FE` | Fondo de pantallas |
| Surface | `#FFFFFF` | Cards, componentes |
| Text Primary | `#1A1F36` | Títulos, textos principales |
| Text Secondary | `#6B7280` | Subtítulos, descripciones |
| Success | `#10B981` | Estados positivos |
| Warning | `#F59E0B` | Alertas |
| Error | `#EF4444` | Errores |

---

## 📐 Sistema de Espaciado

- Base: 4px
- Espacios comunes: 8px, 12px, 16px, 20px, 24px, 32px
- Padding cards: 16px
- Margen entre cards: 12px
- Border radius: 8px (pequeño), 12px (medio), 16px (grande), 20px (pills)

---

## 🔮 Futuras Mejoras

### Fase 2: Interactividad
- [ ] Agendar nuevas citas desde la app
- [ ] Solicitar recetas/certificados
- [ ] Chat con veterinario
- [ ] Recordatorios personalizables

### Fase 3: Funcionalidades Avanzadas
- [ ] Integración con calendario del dispositivo
- [ ] Compartir archivos médicos
- [ ] Historial de peso/crecimiento con gráficas
- [ ] Comunidad de dueños de mascotas
- [ ] Tienda de productos veterinarios

### Fase 4: Administración desde el Veterinario
- [ ] Dashboard web para veterinarios
- [ ] Subir archivos y actualizar historiales
- [ ] Gestión de citas bidireccional
- [ ] Sistema de pagos integrado

---

## 📞 Soporte y Contacto

Para consultas técnicas o reportar issues, contactar al equipo de desarrollo de Zuliadog.

**Versión**: 1.0.0
**Fecha**: Octubre 2025
**Plataforma**: Flutter (iOS & Android)
