@echo off
title Desinstalador Servicio NFC
chcp 65001 >nul 2>&1

echo.
echo ================================================
echo    DESINSTALADOR SERVICIO NFC
echo ================================================
echo.

echo [1/4] Deteniendo procesos...
taskkill /F /IM nfc-service.exe >nul 2>&1
taskkill /F /IM wscript.exe /FI "WINDOWTITLE eq watchdog*" >nul 2>&1

:: Matar cualquier wscript que este ejecutando watchdog.vbs
for /f "tokens=2" %%i in ('wmic process where "name='wscript.exe' and commandline like '%%watchdog%%'" get processid 2^>nul ^| findstr [0-9]') do (
    taskkill /F /PID %%i >nul 2>&1
)

:: Matar procesos node que ejecuten nfc-service
for /f "tokens=2" %%i in ('wmic process where "name='node.exe' and commandline like '%%nfc-service%%'" get processid 2^>nul ^| findstr [0-9]') do (
    taskkill /F /PID %%i >nul 2>&1
)

echo [OK] Procesos detenidos

echo.
echo [2/4] Eliminando tareas programadas...
schtasks /delete /tn "NFC-Service" /f >nul 2>&1
schtasks /delete /tn "NFC-Watchdog" /f >nul 2>&1
echo [OK] Tareas eliminadas

echo.
echo [3/4] Eliminando acceso directo de inicio...
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
del "%startupFolder%\NFC-Service.lnk" >nul 2>&1
del "%startupFolder%\NFC-Watchdog.lnk" >nul 2>&1
echo [OK] Accesos directos eliminados

echo.
echo [4/4] Limpiando archivos temporales...
del "%~dp0watchdog.log" >nul 2>&1
echo [OK] Archivos limpiados

echo.
echo ================================================
echo [OK] DESINSTALACION COMPLETADA
echo ================================================
echo.
echo El servicio NFC ha sido completamente removido.
echo Los archivos del programa NO fueron eliminados.
echo.
:: Solo pausar si se ejecuta manualmente
if "%1"=="" pause
