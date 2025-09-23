@echo off
echo ========================================
echo    Zuliadog - Compilacion e Instalador
echo ========================================
echo.

echo Paso 1: Compilando la aplicacion...
flutter build windows --release
if errorlevel 1 (
    echo ❌ Error al compilar la aplicacion
    pause
    exit /b 1
)
echo ✅ Aplicacion compilada correctamente
echo.

echo Paso 2: Creando directorio de instalador...
if not exist "installer" mkdir installer
echo ✅ Directorio creado
echo.

echo Paso 3: Abriendo Inno Setup...
echo Ahora se abrira Inno Setup con el script Zuliadog_Installer.iss
echo.
echo INSTRUCCIONES:
echo 1. En Inno Setup, presiona F9 o ve a Build ^> Compile
echo 2. El instalador se creara en la carpeta 'installer'
echo 3. Busca el archivo Zuliadog_Setup_1.0.0.exe
echo.

pause
start "" "Zuliadog_Installer.iss"

