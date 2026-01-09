@echo off
cd /d "%~dp0"

:: SIEMPRE usar Node.js portable primero (version correcta)
if exist "%~dp0node\node.exe" (
    echo Usando Node.js portable...
    start "" /B "%~dp0node\node.exe" nfc-service.js
    exit /b 0
)

:: Solo si no existe el portable, intentar con el del sistema
where node >nul 2>&1
if %errorlevel% equ 0 (
    echo [WARN] Usando Node.js del sistema - puede haber problemas de version
    start "" /B node nfc-service.js
    exit /b 0
)

echo [ERROR] No se encontro Node.js portable ni del sistema
echo         Reinstala el servicio NFC
pause
exit /b 1
