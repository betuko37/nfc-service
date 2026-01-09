@echo off
title Diagnostico NFC Service
chcp 65001 >nul 2>&1
color 0E

echo.
echo ================================================
echo    DIAGNOSTICO COMPLETO NFC SERVICE
echo ================================================
echo.

set "SCRIPT_DIR=%~dp0"

echo [1/7] Verificando archivos instalados...
echo.

if exist "%SCRIPT_DIR%nfc-service.js" (
    echo      [OK] nfc-service.js
) else (
    echo      [ERROR] nfc-service.js NO ENCONTRADO
)

if exist "%SCRIPT_DIR%node\node.exe" (
    echo      [OK] node\node.exe
    echo           Version: 
    "%SCRIPT_DIR%node\node.exe" --version
) else (
    echo      [ERROR] node\node.exe NO ENCONTRADO
    echo             Esta es la causa del problema!
)

if exist "%SCRIPT_DIR%node_modules" (
    echo      [OK] node_modules
) else (
    echo      [ERROR] node_modules NO ENCONTRADO
)

if exist "%SCRIPT_DIR%node_modules\@pokusew\pcsclite\build\Release\pcsclite.node" (
    echo      [OK] pcsclite.node
) else (
    echo      [ERROR] pcsclite.node NO ENCONTRADO
)

echo.
echo [2/7] Verificando procesos...
echo.
tasklist | findstr /i "node.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo      [INFO] Procesos node.exe encontrados:
    tasklist | findstr /i "node.exe"
) else (
    echo      [INFO] No hay procesos node.exe corriendo
)

echo.
echo [3/7] Verificando puerto 47321...
echo.
netstat -ano | findstr ":47321" >nul 2>&1
if %errorlevel% equ 0 (
    echo      [INFO] Puerto 47321 en uso:
    netstat -ano | findstr ":47321"
) else (
    echo      [INFO] Puerto 47321 libre (servicio no corriendo)
)

echo.
echo [4/7] Verificando respuesta HTTP...
echo.
curl -s http://127.0.0.1:47321/ping > "%TEMP%\nfc_diag.txt" 2>nul
if %errorlevel% equ 0 (
    echo      [OK] Servicio responde:
    type "%TEMP%\nfc_diag.txt"
    del "%TEMP%\nfc_diag.txt" 2>nul
) else (
    echo      [ERROR] Servicio NO responde en http://127.0.0.1:47321/ping
    del "%TEMP%\nfc_diag.txt" 2>nul
)

echo.
echo [5/7] Verificando logs...
echo.
if exist "%SCRIPT_DIR%inicio.log" (
    echo      Log de inicio:
    type "%SCRIPT_DIR%inicio.log"
    echo.
) else (
    echo      [INFO] No hay log de inicio
)

if exist "%SCRIPT_DIR%watchdog.log" (
    echo      Ultimas lineas de watchdog.log:
    powershell -Command "Get-Content '%SCRIPT_DIR%watchdog.log' -Tail 5" 2>nul
) else (
    echo      [INFO] No hay log de watchdog
)

echo.
echo [6/7] Intentando iniciar servicio manualmente...
echo.

:: Matar procesos anteriores
taskkill /F /IM node.exe >nul 2>&1
timeout /t 2 /nobreak >nul

cd /d "%SCRIPT_DIR%"

if exist "%SCRIPT_DIR%node\node.exe" (
    echo      Ejecutando: node\node.exe nfc-service.js
    echo      Esperando 10 segundos...
    echo.
    echo -------- SALIDA DEL SERVICIO --------
    start "" /B "%SCRIPT_DIR%node\node.exe" nfc-service.js
    timeout /t 10 /nobreak >nul
    echo -------- FIN SALIDA --------
) else (
    echo      [ERROR] No se puede iniciar - node.exe no existe
)

echo.
echo [7/7] Verificacion final...
echo.
timeout /t 3 /nobreak >nul

netstat -ano | findstr ":47321" >nul 2>&1
if %errorlevel% equ 0 (
    echo      [OK] Servicio corriendo en puerto 47321
    curl -s http://127.0.0.1:47321/ping 2>nul
) else (
    echo      [ERROR] El servicio no esta corriendo
    echo.
    echo      SOLUCION: Revisa los errores arriba.
    echo      Si dice "NODE_MODULE_VERSION", las versiones
    echo      de Node.js no coinciden.
)

echo.
echo ================================================
echo.
pause
