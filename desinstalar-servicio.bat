@echo off
title Desinstalador Servicio NFC

echo.
echo =======================================
echo   DESINSTALADOR SERVICIO NFC ACR122U
echo =======================================
echo.

set "shortcutPath=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\NFC-Service.lnk"

:: Detener el servicio si esta corriendo
echo [1/2] Deteniendo servicio...
taskkill /F /IM nfc-service.exe 2>nul
if %errorlevel%==0 (
    echo [OK] Servicio detenido
) else (
    echo [INFO] Servicio no estaba corriendo
)

echo.
echo [2/2] Eliminando acceso directo...
if exist "%shortcutPath%" (
    del "%shortcutPath%"
    echo [OK] Acceso directo eliminado
) else (
    echo [INFO] Acceso directo no encontrado
)

echo.
echo =======================================
echo [OK] DESINSTALACION COMPLETADA
echo =======================================
echo.
pause