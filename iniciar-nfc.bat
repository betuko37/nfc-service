@echo off
cd /d "%~dp0"

:: Intentar usar Node.js primero
where node >nul 2>&1
if %errorlevel% equ 0 (
    start "" /B node nfc-service.js
    exit /b 0
)

:: Si no hay Node.js, intentar con el ejecutable
if exist "%~dp0nfc-service.exe" (
    start "" /B "%~dp0nfc-service.exe"
    exit /b 0
)

echo [ERROR] No se encontro Node.js ni nfc-service.exe
exit /b 1
