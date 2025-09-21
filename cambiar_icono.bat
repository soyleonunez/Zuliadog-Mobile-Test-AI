@echo off
REM Script para cambiar entre iconos de la aplicación Zuliadog
REM Uso: cambiar_icono.bat [solid|translucent]

if "%1"=="solid" (
    echo 🔄 Cambiando a icono sólido...
    copy "windows\runner\resources\icons\app_icon_solid.ico" "windows\runner\resources\app_icon.ico" /Y
    echo ✅ Icono cambiado a sólido
    goto :end
)

if "%1"=="translucent" (
    echo 🔄 Cambiando a icono translúcido...
    copy "windows\runner\resources\icons\app_icon_translucent.ico" "windows\runner\resources\app_icon.ico" /Y
    echo ✅ Icono cambiado a translúcido
    goto :end
)

echo ❌ Uso: cambiar_icono.bat [solid^|translucent]
echo.
echo 📋 Comandos para aplicar el cambio:
echo    flutter clean
echo    flutter build windows
exit /b 1

:end
echo.
echo 📋 Comandos para aplicar el cambio:
echo    flutter clean
echo    flutter build windows
echo.
if "%1"=="solid" (
    echo 🎯 Para probar el icono translúcido: cambiar_icono.bat translucent
) else (
    echo 🎯 Para probar el icono sólido: cambiar_icono.bat solid
)
