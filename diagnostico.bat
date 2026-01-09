@echo off
title Diagnostico NFC Service
chcp 65001 >nul 2>&1

echo.
echo ================================================
echo    DIAGNOSTICO NFC SERVICE
echo ================================================
echo.

set "SCRIPT_DIR=%~dp0"

echo [1] Verificando archivos...
if exist "%SCRIPT_DIR%nfc-service.js" (
    echo      [OK] nfc-service.js
) else (
    echo      [ERROR] No se encuentra nfc-service.js
)

if exist "%SCRIPT_DIR%node\node.exe" (
    echo      [OK] Node.js portable encontrado
    "%SCRIPT_DIR%node\node.exe" --version
) else (
    echo      [WARN] Node.js portable no encontrado
    where node >nul 2>&1
    if %errorlevel% equ 0 (
        echo      [OK] Node.js del sistema encontrado
        node --version
    ) else (
        echo      [ERROR] Node.js no encontrado en el sistema
    )
)

echo.
echo [2] Verificando procesos...
tasklist | findstr /i "node.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo      [OK] Proceso node.exe encontrado
    tasklist | findstr /i "node.exe"
) else (
    echo      [INFO] No hay procesos node.exe corriendo
)

tasklist | findstr /i "wscript.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo      [OK] Proceso wscript.exe encontrado (watchdog)
) else (
    echo      [INFO] No hay procesos wscript.exe corriendo
)

echo.
echo [3] Verificando puerto 3001...
netstat -ano | findstr ":3001" >nul 2>&1
if %errorlevel% equ 0 (
    echo      [OK] Puerto 3001 en uso
    netstat -ano | findstr ":3001"
) else (
    echo      [ERROR] Puerto 3001 no esta en uso
)

echo.
echo [4] Verificando servicio HTTP...
curl -s http://localhost:3001/status >nul 2>&1
if %errorlevel% equ 0 (
    echo      [OK] Servicio responde en http://localhost:3001/status
    curl -s http://localhost:3001/status
) else (
    echo      [ERROR] Servicio no responde
)

echo.
echo [5] Verificando logs...
if exist "%SCRIPT_DIR%inicio.log" (
    echo      [OK] Log de inicio encontrado:
    type "%SCRIPT_DIR%inicio.log"
) else (
    echo      [INFO] No hay log de inicio
)

if exist "%SCRIPT_DIR%watchdog.log" (
    echo      [OK] Log de watchdog encontrado (ultimas 5 lineas):
    powershell -Command "Get-Content '%SCRIPT_DIR%watchdog.log' -Tail 5"
) else (
    echo      [INFO] No hay log de watchdog
)

echo.
echo [6] Intentando iniciar servicio manualmente...
cd /d "%SCRIPT_DIR%"
if exist "%SCRIPT_DIR%node\node.exe" (
    echo      Iniciando con Node.js portable...
    start "" "%SCRIPT_DIR%node\node.exe" nfc-service.js
) else (
    echo      Iniciando con Node.js del sistema...
    start "" node nfc-service.js
)
timeout /t 5 /nobreak >nul

echo.
echo [7] Verificando nuevamente puerto 3001...
netstat -ano | findstr ":3001" >nul 2>&1
if %errorlevel% equ 0 (
    echo      [OK] Servicio iniciado correctamente
) else (
    echo      [ERROR] El servicio no se pudo iniciar
    echo      Revisa los logs para mas informacion
)

echo.
echo ================================================
pause
