@echo off
chcp 65001 >nul
title Instalador Servicio NFC
color 0A

echo.
echo ═══════════════════════════════════════
echo    INSTALADOR SERVICIO NFC ACR122U
echo ═══════════════════════════════════════
echo.

:: Verificar que el .exe existe
if not exist "%~dp0nfc-service.exe" (
    color 0C
    echo [ERROR] No se encuentra nfc-service.exe
    echo Asegúrate de que este archivo .bat está en la misma carpeta
    pause
    exit /b 1
)

:: Configurar rutas
set "exePath=%~dp0nfc-service.exe"
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "shortcutPath=%startupFolder%\NFC-Service.lnk"

echo [1/3] Creando acceso directo en Inicio...

:: Crear acceso directo usando PowerShell
powershell -Command "$WS = New-Object -ComObject WScript.Shell; $SC = $WS.CreateShortcut('%shortcutPath%'); $SC.TargetPath = '%exePath%'; $SC.WorkingDirectory = '%~dp0'; $SC.WindowStyle = 7; $SC.Description = 'Servicio NFC ACR122U'; $SC.Save()"

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
echo [3/3] Iniciando servicio...
start "" "%exePath%"
timeout /t 2 /nobreak >nul

echo.
echo ═══════════════════════════════════════
echo [√] INSTALACIÓN COMPLETADA
echo ═══════════════════════════════════════
echo.
echo El servicio NFC está ahora ejecutándose
echo Se iniciará automáticamente al encender la PC
echo.
echo Puerto: 3001
echo Estado: http://localhost:3001/status
echo.
pause