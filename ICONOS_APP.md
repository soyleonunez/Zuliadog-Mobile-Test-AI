# 🎨 Configuración de Iconos de la Aplicación Zuliadog

## Iconos Disponibles

La aplicación tiene dos opciones de icono disponibles:

1. **Solid (Sólido)** - `app icon - solid.png`
   - Icono con fondo sólido
   - Más visible en fondos claros
   - Estilo más tradicional

2. **Translucent (Translúcido)** - `app icon - translucent.png`
   - Icono con transparencia
   - Se adapta mejor a diferentes fondos
   - Estilo más moderno

## 🔄 Cómo Cambiar de Icono

### Método 1: Script Automático (Recomendado)

1. Abre PowerShell en la raíz del proyecto
2. Ejecuta uno de estos comandos:

```bash
# Para usar el icono sólido
.\cambiar_icono.bat solid

# Para usar el icono translúcido
.\cambiar_icono.bat translucent
```

3. Después de cambiar el icono, ejecuta:
```bash
flutter clean
flutter build windows
```

### Método 2: Manual

1. Ve a la carpeta `windows\runner\resources\icons\`
2. Copia el archivo PNG que quieras usar
3. Pégalo en `windows\runner\resources\` y renómbralo a `app_icon.ico`
4. Ejecuta `flutter clean && flutter build windows`

## 📁 Estructura de Archivos

```
Assets/Icon/
├── app icon - solid.png          # Icono sólido original
├── app icon - solid.svg          # Versión SVG sólida
├── app icon - translucent.png    # Icono translúcido original
└── app icon - translucent.svg    # Versión SVG translúcida

windows/runner/resources/
├── app_icon.ico                  # Icono actual de la app
└── icons/
    ├── app_icon_solid.png        # Copia del icono sólido
    └── app_icon_translucent.png  # Copia del icono translúcido
```

## 🎯 Recomendaciones

- **Icono Sólido**: Mejor para aplicaciones de escritorio tradicionales
- **Icono Translúcido**: Mejor para aplicaciones modernas y cuando quieres que se adapte al tema del sistema

## 🔧 Notas Técnicas

- Los archivos ICO se generan automáticamente desde los PNG
- Windows puede usar archivos PNG como ICO sin problemas
- Después de cambiar el icono, siempre ejecuta `flutter clean` para limpiar la caché
