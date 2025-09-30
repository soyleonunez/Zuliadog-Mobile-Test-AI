@echo off
echo ========================================
echo Compilando Zuliadog en modo Release
echo ========================================

echo.
echo 1. Limpiando proyecto...
flutter clean

echo.
echo 2. Obteniendo dependencias...
flutter pub get

echo.
echo 3. Compilando en modo Release...
flutter build windows --release

echo.
echo 4. Verificando archivos generados...
if exist "build\windows\x64\runner\Release\zuliadog.exe" (
    echo ✅ Compilación exitosa!
    echo Archivo: build\windows\x64\runner\Release\zuliadog.exe
) else (
    echo ❌ Error en la compilación
    pause
    exit /b 1
)

echo.
echo 5. Listo para crear el instalador con Inno Setup
echo.
pause

