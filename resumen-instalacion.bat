@echo off
title Resumen Instalacion NFC Service
chcp 65001 >nul 2>&1
color 0A

set "SCRIPT_DIR=%~dp0"

echo.
echo ================================================
echo    VERIFICANDO INSTALACION NFC SERVICE
echo ================================================
echo.

:: Esperar un poco para que el servicio inicie
echo Esperando que el servicio inicie...
timeout /t 5 /nobreak >nul

echo.
echo VERIFICACION:
echo.

:: Verificar que existe node portable
if exist "%SCRIPT_DIR%node\node.exe" (
    echo   [OK] Node.js portable instalado
    "%SCRIPT_DIR%node\node.exe" --version 2>nul
) else (
    echo   [ERROR] Node.js portable NO encontrado
    echo          Ruta esperada: %SCRIPT_DIR%node\node.exe
    goto :error_encontrado
)

:: Verificar que existe nfc-service.js
if exist "%SCRIPT_DIR%nfc-service.js" (
    echo   [OK] nfc-service.js encontrado
) else (
    echo   [ERROR] nfc-service.js NO encontrado
    goto :error_encontrado
)

:: Verificar que existe node_modules
if exist "%SCRIPT_DIR%node_modules" (
    echo   [OK] node_modules encontrado
) else (
    echo   [ERROR] node_modules NO encontrado
    goto :error_encontrado
)

echo.
echo Intentando conectar al servicio...

:: Intentar conectar al servicio con curl o powershell
curl -s -o nul -w "%%{http_code}" http://127.0.0.1:47321/ping > "%TEMP%\nfc_status.txt" 2>nul
set /p HTTP_CODE=<"%TEMP%\nfc_status.txt"
del "%TEMP%\nfc_status.txt" 2>nul

if "%HTTP_CODE%"=="200" (
    echo   [OK] Servicio respondiendo en puerto 47321
    echo.
    echo ================================================
    echo    INSTALACION COMPLETADA EXITOSAMENTE
    echo ================================================
    color 0A
    goto :mostrar_info
)

:: Si curl no funciona, intentar con powershell
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:47321/ping' -UseBasicParsing -TimeoutSec 3; Write-Host 'OK' } catch { Write-Host 'ERROR' }" > "%TEMP%\nfc_ps.txt" 2>nul
set /p PS_RESULT=<"%TEMP%\nfc_ps.txt"
del "%TEMP%\nfc_ps.txt" 2>nul

if "%PS_RESULT%"=="OK" (
    echo   [OK] Servicio respondiendo en puerto 47321
    echo.
    echo ================================================
    echo    INSTALACION COMPLETADA EXITOSAMENTE
    echo ================================================
    color 0A
    goto :mostrar_info
)

:: El servicio no responde, intentar iniciarlo manualmente
echo   [WARN] Servicio no responde, intentando iniciar...
echo.

cd /d "%SCRIPT_DIR%"
start "" /B "%SCRIPT_DIR%node\node.exe" nfc-service.js
echo Esperando 8 segundos...
timeout /t 8 /nobreak >nul

:: Verificar de nuevo
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:47321/ping' -UseBasicParsing -TimeoutSec 3; Write-Host 'OK' } catch { Write-Host 'ERROR' }" > "%TEMP%\nfc_ps2.txt" 2>nul
set /p PS_RESULT2=<"%TEMP%\nfc_ps2.txt"
del "%TEMP%\nfc_ps2.txt" 2>nul

if "%PS_RESULT2%"=="OK" (
    echo   [OK] Servicio iniciado correctamente
    echo.
    echo ================================================
    echo    INSTALACION COMPLETADA EXITOSAMENTE
    echo ================================================
    color 0A
    goto :mostrar_info
)

:error_encontrado
color 0C
echo.
echo ================================================
echo    ERROR: EL SERVICIO NO PUDO INICIAR
echo ================================================
echo.
echo Posibles causas:
echo   - Archivos faltantes
echo   - Puerto 47321 en uso por otro programa
echo   - Error en el servicio
echo.
echo Para diagnosticar, ejecuta:
echo   %SCRIPT_DIR%diagnostico.bat
echo.
echo O intenta iniciar manualmente:
echo   cd "%SCRIPT_DIR%"
echo   node\node.exe nfc-service.js
echo.
goto :fin

:mostrar_info
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
echo   Estado:  http://127.0.0.1:47321/ping
echo   Logs:    http://127.0.0.1:47321/logs
echo.

:fin
echo ================================================
echo.
echo Presiona ENTER para cerrar esta ventana...
pause >nul
