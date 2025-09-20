# Zuliadog - Sistema Veterinario

Sistema de gestión veterinaria desarrollado en Flutter con Supabase.

## Estructura del Proyecto

```
├── lib/                    # Código fuente Flutter
│   ├── core/              # Configuración y temas
│   ├── features/          # Funcionalidades principales
│   └── auth/              # Autenticación
├── database/              # Scripts SQL de Supabase
├── Assets/                # Recursos (imágenes, fuentes, docs)
└── windows/               # Configuración Windows
```

## Características

- 🏥 **Gestión de Pacientes** - Registro y seguimiento de mascotas
- 📋 **Historias Médicas** - Sistema optimizado con editor Quill
- 💊 **Prescripciones** - Gestión de medicamentos
- 📊 **Reportes** - Análisis y estadísticas
- 🔐 **Autenticación** - Sistema seguro con Supabase

## Base de Datos

Todos los scripts SQL están organizados en la carpeta `database/` con documentación completa.

## Desarrollo

```bash
flutter pub get
flutter run
```

## Tecnologías

- **Flutter** - Framework UI
- **Supabase** - Backend y base de datos
- **Quill** - Editor de texto rico
- **Iconsax** - Iconografía
