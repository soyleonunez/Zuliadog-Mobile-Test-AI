# 🚀 Guía Rápida para Crear el Instalador de Zuliadog

## 📋 Pasos Simples

### 1. Compilar la Aplicación
```cmd
flutter build windows --release
```

### 2. Crear el Instalador
1. **Abre Inno Setup** (busca "Inno Setup Compiler" en el menú de inicio)
2. **Abre el archivo**: `Zuliadog_Installer.iss`
3. **Compila**: Presiona `F9` o ve a `Build` → `Compile`
4. **El instalador se creará en**: `installer/Zuliadog_Setup_1.0.0.exe`

## 🎯 O Usar el Script Automático

Ejecuta simplemente:
```cmd
build_and_install.bat
```

Este script:
- ✅ Compila la aplicación automáticamente
- ✅ Crea la carpeta `installer`
- ✅ Abre Inno Setup con el script listo

## 📁 Archivos Importantes

- `Zuliadog_Installer.iss` - Script de Inno Setup
- `build_and_install.bat` - Script automático
- `build/windows/x64/runner/Release/` - Aplicación compilada
- `installer/` - Carpeta donde se crea el instalador

## 🧪 Probar el Instalador

1. **Ejecuta**: `installer/Zuliadog_Setup_1.0.0.exe`
2. **Sigue el asistente** de instalación
3. **Verifica** que la aplicación funcione:
   - ✅ Menú lateral visible
   - ✅ Navegación entre secciones
   - ✅ Botón de historia médica funcional
   - ✅ Búsqueda de pacientes

## 🔧 Características del Instalador

- **Detección automática** si la app está ejecutándose
- **Instalación en**: `C:\Program Files\Zuliadog`
- **Iconos opcionales** en escritorio y barra de inicio
- **Desinstalador completo**
- **Interfaz en español**

## ⚠️ Si Hay Problemas

1. **Error de compilación**: Verifica que Flutter esté actualizado
2. **Error de Inno Setup**: Asegúrate de que esté instalado correctamente
3. **App no funciona**: Verifica que todos los archivos DLL estén incluidos

---

**¡Listo para crear el instalador! 🎉**

