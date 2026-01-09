@echo off
title Resumen Instalacion NFC Service
chcp 65001 >nul 2>&1
color 0A

set "SCRIPT_DIR=%~dp0"

echo.
echo ================================================
echo    INSTALACION COMPLETADA EXITOSAMENTE
echo ================================================
echo.

echo VERIFICACION FINAL:
echo.

:: Verificar puerto
netstat -ano 2>nul | findstr ":3001" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Servicio NFC corriendo en puerto 3001
) else (
    echo   [WARN] Servicio no detectado en puerto 3001
    echo          Puede estar iniciando, espera unos segundos
)

:: Verificar procesos
tasklist | findstr /i "node.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Proceso Node.js activo
) else (
    echo   [WARN] Proceso Node.js no detectado
)

tasklist | findstr /i "wscript.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Watchdog activo
) else (
    echo   [WARN] Watchdog no detectado
)

:: Verificar accesos directos
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if exist "%STARTUP%\NFC-Service.lnk" (
    echo   [OK] Inicio automatico configurado
) else (
    echo   [ERROR] Inicio automatico no configurado
)

echo.
echo CARACTERISTICAS INSTALADAS:
echo   [+] Inicio automatico con Windows
echo   [+] Watchdog: reinicia si el servicio muere
echo   [+] Deteccion de suspension/hibernacion
echo   [+] Reconexion NFC automatica
echo   [+] Servicio completamente oculto
echo.
echo ACCESOS WEB:
echo   Consola: http://localhost:3001/console
echo   Estado:  http://localhost:3001/status
echo   Logs:    http://localhost:3001/logs
echo.
echo NOTA: Si el servicio no responde, ejecuta:
echo   diagnostico.bat
echo.
echo ================================================
echo.
echo Presiona ENTER para cerrar esta ventana...
pause >nul
