# Implementación de Imágenes de Razas Automáticas

## Resumen

Se ha implementado un sistema automático para mostrar imágenes de razas en las cards de pacientes. El sistema obtiene las imágenes desde Supabase y tiene fallbacks por especie. **Refactorizado para usar un servicio unificado `DataService`.**

## Archivos Modificados

### 1. `lib/features/data/data_service.dart` (NUEVO - UNIFICADO)
Servicio unificado que combina funcionalidades de archivos e imágenes de razas.

**Funciones principales:**
- **Archivos:** `downloadToDownloads()`, `downloadToTemp()`, `getFilePublicUrl()`, `testFileConnection()`
- **Imágenes de razas:** `getBreedImageUrl()`, `getSpeciesFallbackImage()`, `buildBreedImageWidget()`
- **Utilidades:** `testConnection()` - Prueba conexión general

### 2. `lib/features/data/buscador.dart`
Actualizado el modelo `PatientSearchRow` para incluir `breedId`.

**Cambios:**
- Agregado campo `breedId` al modelo
- Actualizada consulta SQL para incluir `breed_id`
- Actualizado `fromJson()` para parsear el nuevo campo

### 3. `lib/features/home.dart`
Actualizadas las cards de búsqueda para usar imágenes de razas.

**Cambios:**
- Importado `DataService`
- Reemplazado avatar estático por `DataService().buildBreedImageWidget()`
- Mantenido fallback por especie

### 4. `lib/features/widgets/optimizedhist.dart`
Actualizadas las cards de pacientes y panel de información.

**Cambios:**
- Importado `DataService`
- Actualizado `_buildSearchResultItem()` para usar imágenes de razas
- Actualizado panel de información del paciente
- Actualizada consulta SQL para incluir `breed_id`

### 5. `lib/features/utilities/visor.dart`
Actualizado para usar el nuevo `DataService` unificado.

**Cambios:**
- Reemplazado `FileService` por `DataService`
- Actualizado métodos de descarga y prueba de conexión

### 6. Archivos Eliminados
- `lib/features/data/breed_image_service.dart` - Funcionalidad movida a `DataService`
- `lib/features/data/file_service.dart` - Funcionalidad movida a `DataService`

## Cómo Funciona

### 1. Flujo de Obtención de Imagen
```
1. Se llama a BreedImageService.buildBreedImageWidget()
2. Si hay breedId, se consulta Supabase para obtener URL
3. Si hay URL cacheada, se usa directamente
4. Si no, se construye URL desde bucket y key
5. Si falla, se usa fallback por especie
```

### 2. Fallbacks por Especie
- **Canino/Perro**: `Assets/Images/Dog icon.png`
- **Felino/Gato**: `Assets/Images/Cat icon.png`
- **Otros**: `Assets/Images/Other icon.png`

### 3. Estados de Carga
- **Cargando**: Spinner circular
- **Imagen encontrada**: `Image.network()` con la URL
- **Error de red**: Fallback por especie
- **Sin breedId**: Fallback por especie

## Estructura de Base de Datos Requerida

### Tabla `breeds`
```sql
CREATE TABLE breeds (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  species TEXT NOT NULL,
  image_bucket TEXT,
  image_key TEXT,
  image_url TEXT, -- URL cacheada
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Vista `patients_search`
```sql
CREATE VIEW patients_search AS
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
  b.id as breed_id, -- NUEVO CAMPO
  p.sex
FROM patients p
LEFT JOIN owners o ON p.id = o.patient_id
LEFT JOIN species s ON p.species_id = s.id
LEFT JOIN breeds b ON p.breed_id = b.id;
```

## Uso en el Código

### Widget Básico
```dart
DataService().buildBreedImageWidget(
  breedId: patient.breedId,
  species: patient.species,
  width: 40,
  height: 40,
  borderRadius: 20,
)
```

### Obtener URL Directamente
```dart
final dataService = DataService();
final imageUrl = await dataService.getBreedImageUrl('breed_123');
if (imageUrl != null) {
  // Usar la URL
}
```

### Fallback por Especie
```dart
final dataService = DataService();
final fallbackPath = dataService.getSpeciesFallbackImage('Canino');
// Retorna: 'Assets/Images/Dog icon.png'
```

### Descargar Archivos
```dart
final dataService = DataService();
await dataService.downloadToDownloads(url, filename);
```

### Probar Conexión
```dart
final dataService = DataService();
final result = await dataService.testConnection();
```

## Configuración de Supabase Storage

1. **Bucket público** para imágenes de razas
2. **Políticas RLS** configuradas para acceso público de lectura
3. **URLs públicas** generadas automáticamente

## Próximos Pasos

1. **Agregar assets de fallback** por especie (CAN.png, FEL.png, etc.)
2. **Implementar caché local** para mejorar rendimiento
3. **Agregar compresión** de imágenes automática
4. **Implementar selección de imagen** en formularios de paciente

## Notas Técnicas

- Las imágenes se cargan de forma asíncrona con `FutureBuilder`
- Se maneja el estado de carga con spinners
- Los errores de red se capturan y muestran fallback
- El sistema es completamente opcional - funciona sin `breedId`
- Compatible con el diseño existente de la aplicación
