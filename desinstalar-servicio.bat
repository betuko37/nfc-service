@echo off
chcp 65001 >nul
title Desinstalador Servicio NFC
color 0E

echo.
echo ═══════════════════════════════════════
echo   DESINSTALADOR SERVICIO NFC ACR122U
echo ═══════════════════════════════════════
echo.

set "shortcutPath=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\NFC-Service.lnk"

:: Detener el servicio si está corriendo
echo [1/2] Deteniendo servicio...
taskkill /F /IM nfc-service.exe 2>nul
if %errorlevel%==0 (
    echo [√] Servicio detenido
) else (
    echo [!] Servicio no estaba corriendo
)

echo.
echo [2/2] Eliminando acceso directo...
if exist "%shortcutPath%" (
    del "%shortcutPath%"
    echo [√] Acceso directo eliminado
) else (
    echo [!] Acceso directo no encontrado
)

echo.
echo ═══════════════════════════════════════
echo [√] DESINSTALACIÓN COMPLETADA
echo ═══════════════════════════════════════
echo.
pause
```

## 4. Crear un README para el usuario

Crea `LEEME.txt`:
```
═══════════════════════════════════════════════════════════
  SERVICIO NFC ACR122U - INSTRUCCIONES DE INSTALACIÓN
═══════════════════════════════════════════════════════════

REQUISITOS PREVIOS:
------------------
1. Conectar el lector ACR122U al puerto USB
2. Instalar driver oficial de ACS desde:
   https://www.acs.com.hk/en/driver/3/acr122u-usb-nfc-reader/

INSTALACIÓN:
-----------
1. Hacer doble clic en "instalar-servicio.bat"
2. Esperar a que aparezca "INSTALACIÓN COMPLETADA"
3. ¡Listo! El servicio ya está funcionando

VERIFICACIÓN:
------------
Abre tu navegador y visita:
http://localhost:3001/status

Deberías ver:
{
  "status": "running",
  "readerConnected": true,
  "port": 3001
}

DESINSTALACIÓN:
--------------
Hacer doble clic en "desinstalar-servicio.bat"

SOLUCIÓN DE PROBLEMAS:
---------------------
- Si el servicio no inicia: Verificar que el driver esté instalado
- Si no detecta el lector: Reconectar el USB y reiniciar el servicio
- Puerto 3001 ocupado: Cerrar otras aplicaciones que usen ese puerto

═══════════════════════════════════════════════════════════
```

## 5. Estructura final para distribuir

Crea una carpeta `NFC-Service-Installer` con estos archivos:
```
NFC-Service-Installer/
  ├── nfc-service.exe
  ├── instalar-servicio.bat
  ├── desinstalar-servicio.bat
  └── LEEME.txt