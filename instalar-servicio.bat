@echo off
chcp 65001 >nul
title Instalador Servicio NFC
color 0A

echo.
echo ═══════════════════════════════════════
echo    INSTALADOR SERVICIO NFC ACR122U
echo ═══════════════════════════════════════
echo.

:: Verificar que los archivos existen
if not exist "%~dp0nfc-service.exe" (
    color 0C
    echo [ERROR] No se encuentra nfc-service.exe
    pause
    exit /b 1
)

if not exist "%~dp0nfc-service-oculto.vbs" (
    color 0C
    echo [ERROR] No se encuentra nfc-service-oculto.vbs
    pause
    exit /b 1
)

:: Configurar rutas - AHORA USA EL VBS
set "vbsPath=%~dp0nfc-service-oculto.vbs"
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "shortcutPath=%startupFolder%\NFC-Service.lnk"

echo [1/3] Creando acceso directo en Inicio...

:: Crear acceso directo al VBS (no al exe)
powershell -Command "$WS = New-Object -ComObject WScript.Shell; $SC = $WS.CreateShortcut('%shortcutPath%'); $SC.TargetPath = '%vbsPath%'; $SC.WorkingDirectory = '%~dp0'; $SC.WindowStyle = 7; $SC.Description = 'Servicio NFC ACR122U'; $SC.Save()"

if exist "%shortcutPath%" (
    echo [√] Acceso directo creado correctamente
) else (
    color 0C
    echo [X] Error al crear acceso directo
    pause
    exit /b 1
)

echo.
echo [2/3] Configurando servicio...
timeout /t 1 /nobreak >nul
echo [√] Servicio configurado

echo.
echo [3/3] Iniciando servicio en segundo plano...
wscript "%vbsPath%"
timeout /t 2 /nobreak >nul

echo.
echo ═══════════════════════════════════════
echo [√] INSTALACIÓN COMPLETADA
echo ═══════════════════════════════════════
echo.
echo El servicio NFC está corriendo en segundo plano
echo Se iniciará automáticamente al encender la PC
echo No verás ninguna ventana
echo.
echo Puerto: 3001
echo Estado: http://localhost:3001/status
echo.
echo Para verificar que está corriendo:
echo - Abre el Administrador de Tareas
echo - Busca "nfc-service.exe" en Procesos
echo.
pause