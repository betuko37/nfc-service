@echo off
title Instalador Servicio NFC

echo.
echo =======================================
echo    INSTALADOR SERVICIO NFC ACR122U
echo =======================================
echo.

:: Verificar que los archivos existen
if not exist "%~dp0nfc-service.exe" (
    echo [ERROR] No se encuentra nfc-service.exe
    pause
    exit /b 1
)

if not exist "%~dp0nfc-service-oculto.vbs" (
    echo [ERROR] No se encuentra nfc-service-oculto.vbs
    pause
    exit /b 1
)

:: Configurar rutas
set "vbsPath=%~dp0nfc-service-oculto.vbs"
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "shortcutPath=%startupFolder%\NFC-Service.lnk"

echo [1/3] Creando acceso directo en Inicio...

:: Crear acceso directo al VBS
powershell -Command "$WS = New-Object -ComObject WScript.Shell; $SC = $WS.CreateShortcut('%shortcutPath%'); $SC.TargetPath = '%vbsPath%'; $SC.WorkingDirectory = '%~dp0'; $SC.WindowStyle = 7; $SC.Description = 'Servicio NFC ACR122U'; $SC.Save()"

if exist "%shortcutPath%" (
    echo [OK] Acceso directo creado correctamente
) else (
    echo [ERROR] Error al crear acceso directo
    pause
    exit /b 1
)

echo.
echo [2/3] Configurando servicio...
timeout /t 1 /nobreak >nul
echo [OK] Servicio configurado

echo.
echo [3/3] Iniciando servicio en segundo plano...
cscript //nologo "%vbsPath%"
timeout /t 2 /nobreak >nul

echo.
echo =======================================
echo [OK] INSTALACION COMPLETADA
echo =======================================
echo.
echo El servicio NFC esta corriendo en segundo plano
echo Se iniciara automaticamente al encender la PC
echo No veras ninguna ventana
echo.
echo Puerto: 3001
echo Estado: http://localhost:3001/status
echo.
echo Para verificar que esta corriendo:
echo - Abre el Administrador de Tareas
echo - Busca "nfc-service.exe" en Procesos
echo.
pause