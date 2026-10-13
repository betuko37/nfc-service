@echo off
title Instalador Servicio NFC v2.0
chcp 65001 >nul 2>&1

echo.
echo ================================================
echo    INSTALADOR SERVICIO NFC v2.0
echo ================================================
echo.

:: Obtener directorio actual del script
set "SCRIPT_DIR=%~dp0"

:: Verificar archivos
if not exist "%SCRIPT_DIR%nfc-service.js" (
    echo [ERROR] No se encuentra nfc-service.js
    if "%1"=="" pause
    exit /b 1
)

if not exist "%SCRIPT_DIR%watchdog.vbs" (
    echo [ERROR] No se encuentra watchdog.vbs
    if "%1"=="" pause
    exit /b 1
)

echo [1/4] Deteniendo servicios anteriores...
schtasks /end /tn "NFC-Service" >nul 2>&1
schtasks /end /tn "NFC-Watchdog" >nul 2>&1
for /f "tokens=2" %%i in ('wmic process where "name='node.exe' and commandline like '%%nfc-service.js%%'" get processid 2^>nul ^| findstr [0-9]') do (
    taskkill /F /PID %%i >nul 2>&1
)
for /f "tokens=2" %%i in ('wmic process where "name='wscript.exe' and commandline like '%%watchdog.vbs%%'" get processid 2^>nul ^| findstr [0-9]') do (
    taskkill /F /PID %%i >nul 2>&1
)
timeout /t 1 /nobreak >nul
echo [OK] Procesos detenidos

echo.
echo [2/4] Limpiando configuracion anterior...
:: Eliminar tareas programadas si existen
schtasks /delete /tn "NFC-Service" /f >nul 2>&1
schtasks /delete /tn "NFC-Watchdog" /f >nul 2>&1
:: Eliminar accesos directos y tareas anteriores
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
del "%STARTUP%\NFC-Service.lnk" >nul 2>&1
del "%STARTUP%\NFC-Watchdog.lnk" >nul 2>&1
echo [OK] Configuracion limpiada

echo.
echo [3/4] Registrando tareas permanentes de Windows...

:: Las tareas sobreviven al cierre de CMD y se ejecutan de nuevo después de reiniciar.
:: Se ejecutan con el usuario actual para que QZ Tray y sus impresoras sean visibles.
set "WScriptPath=%SystemRoot%\System32\wscript.exe"
schtasks /create /tn "NFC-Service" /tr "\"%WScriptPath%\" \"%SCRIPT_DIR%iniciar-oculto.vbs\"" /sc onlogon /delay 0000:10 /ru "%USERNAME%" /rl LIMITED /f >nul
if errorlevel 1 (
    echo [ERROR] No se pudo registrar NFC-Service
    exit /b 1
)
schtasks /create /tn "NFC-Watchdog" /tr "\"%WScriptPath%\" \"%SCRIPT_DIR%watchdog.vbs\"" /sc onlogon /delay 0000:30 /ru "%USERNAME%" /rl LIMITED /f >nul
if errorlevel 1 (
    echo [ERROR] No se pudo registrar NFC-Watchdog
    exit /b 1
)
echo [OK] NFC-Service registrado para iniciar con Windows
echo [OK] NFC-Watchdog registrado para reiniciar el servicio si falla

echo.
echo [4/4] Iniciando servicios...
cd /d "%SCRIPT_DIR%"

:: Verificar que existe node portable
if exist "%SCRIPT_DIR%node\node.exe" (
    echo      Node.js portable encontrado
) else (
    echo      [WARN] Node.js portable no encontrado, usando del sistema
)

:: Iniciar la tarea, no un proceso hijo de esta ventana CMD
schtasks /run /tn "NFC-Service" >nul 2>&1
echo      Esperando que inicie el servicio...
timeout /t 8 /nobreak >nul

:: Verificar puerto con reintentos (más tiempo)
set "INTENTOS=0"
:verificar_puerto
set /a INTENTOS+=1
netstat -ano 2>nul | findstr ":47321" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Servicio NFC corriendo en puerto 47321
    goto :puerto_ok
)
if %INTENTOS% lss 10 (
    echo      Reintentando... ^(%INTENTOS%/10^)
    timeout /t 3 /nobreak >nul
    goto :verificar_puerto
)
echo [WARN] El servicio no responde en puerto 47321
echo      Revisa el log en: %SCRIPT_DIR%inicio.log

:puerto_ok
:: Iniciar el watchdog mediante la tarea registrada
schtasks /run /tn "NFC-Watchdog" >nul 2>&1
echo [OK] Watchdog iniciado

:: Si no es modo silencioso, mostrar resumen final
if not "%1"=="silent" (
    echo.
    echo ================================================
    echo    INSTALACION COMPLETADA EXITOSAMENTE
    echo ================================================
    echo.
    echo VERIFICACION FINAL:
    echo.
    
    :: Verificar puerto una vez mas
    netstat -ano 2>nul | findstr ":47321" >nul 2>&1
    if %errorlevel% equ 0 (
        echo   [OK] Servicio NFC corriendo en puerto 47321
    ) else (
        echo   [WARN] Servicio no detectado en puerto 47321
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
    schtasks /query /tn "NFC-Service" >nul 2>&1
    if errorlevel 1 (
        echo   [ERROR] Inicio automatico no configurado
    ) else (
        echo   [OK] Inicio automatico configurado en Windows
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
    echo   Consola: http://127.0.0.1:47321/console
    echo   Estado:  http://127.0.0.1:47321/status
    echo   Logs:    http://127.0.0.1:47321/logs
    echo.
    echo NOTA: Si el servicio no responde, ejecuta:
    echo   diagnostico.bat
    echo.
    echo ================================================
    echo.
    echo Presiona ENTER para cerrar esta ventana...
    pause >nul
)
