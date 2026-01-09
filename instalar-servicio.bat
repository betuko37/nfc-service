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
taskkill /F /IM nfc-service.exe >nul 2>&1
taskkill /F /IM wscript.exe >nul 2>&1
timeout /t 1 /nobreak >nul
echo [OK] Procesos detenidos

echo.
echo [2/4] Limpiando configuracion anterior...
:: Eliminar tareas programadas si existen
schtasks /delete /tn "NFC-Service" /f >nul 2>&1
schtasks /delete /tn "NFC-Watchdog" /f >nul 2>&1
:: Eliminar accesos directos anteriores
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
del "%STARTUP%\NFC-Service.lnk" >nul 2>&1
del "%STARTUP%\NFC-Watchdog.lnk" >nul 2>&1
echo [OK] Configuracion limpiada

echo.
echo [3/4] Creando accesos directos de inicio automatico...

:: Crear acceso directo para NFC-Service (ejecuta VBS oculto)
> "%TEMP%\nfc1.vbs" echo Set WS = CreateObject("WScript.Shell")
>> "%TEMP%\nfc1.vbs" echo Set SC = WS.CreateShortcut("%STARTUP%\NFC-Service.lnk")
>> "%TEMP%\nfc1.vbs" echo SC.TargetPath = "wscript.exe"
>> "%TEMP%\nfc1.vbs" echo SC.Arguments = """%SCRIPT_DIR%iniciar-oculto.vbs"""
>> "%TEMP%\nfc1.vbs" echo SC.WorkingDirectory = "%SCRIPT_DIR%"
>> "%TEMP%\nfc1.vbs" echo SC.WindowStyle = 7
>> "%TEMP%\nfc1.vbs" echo SC.Save
cscript //nologo "%TEMP%\nfc1.vbs" >nul 2>&1
del "%TEMP%\nfc1.vbs" >nul 2>&1

:: Crear acceso directo para Watchdog
> "%TEMP%\nfc2.vbs" echo Set WS = CreateObject("WScript.Shell")
>> "%TEMP%\nfc2.vbs" echo Set SC = WS.CreateShortcut("%STARTUP%\NFC-Watchdog.lnk")
>> "%TEMP%\nfc2.vbs" echo SC.TargetPath = "wscript.exe"
>> "%TEMP%\nfc2.vbs" echo SC.Arguments = """%SCRIPT_DIR%watchdog.vbs"""
>> "%TEMP%\nfc2.vbs" echo SC.WorkingDirectory = "%SCRIPT_DIR%"
>> "%TEMP%\nfc2.vbs" echo SC.WindowStyle = 7
>> "%TEMP%\nfc2.vbs" echo SC.Save
cscript //nologo "%TEMP%\nfc2.vbs" >nul 2>&1
del "%TEMP%\nfc2.vbs" >nul 2>&1

:: Verificar que se crearon
if exist "%STARTUP%\NFC-Service.lnk" (
    echo [OK] Acceso NFC-Service creado
) else (
    echo [ERROR] No se pudo crear acceso NFC-Service
)
if exist "%STARTUP%\NFC-Watchdog.lnk" (
    echo [OK] Acceso NFC-Watchdog creado
) else (
    echo [ERROR] No se pudo crear acceso NFC-Watchdog
)

echo.
echo [4/4] Iniciando servicios...
cd /d "%SCRIPT_DIR%"

:: Verificar que existe node portable
if exist "%SCRIPT_DIR%node\node.exe" (
    echo      Node.js portable encontrado
) else (
    echo      [WARN] Node.js portable no encontrado, usando del sistema
)

:: Iniciar servicio OCULTO usando VBScript
cscript //nologo "%SCRIPT_DIR%iniciar-oculto.vbs"
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
:: Iniciar watchdog usando cmd /c para que persista
cmd /c start "" wscript.exe "%SCRIPT_DIR%watchdog.vbs"
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
