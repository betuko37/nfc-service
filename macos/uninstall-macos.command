#!/bin/bash
set -euo pipefail

SERVICE_ROOT="${HOME}/.nfc-service"
PLIST_PATH="${HOME}/Library/LaunchAgents/com.nfcservice.agent.plist"
DRIVER_UNINSTALLER="$(cd "$(dirname "$0")/.." && pwd)/acsccid-macosx-bin-1.1.11.1-20240826/acsccid_uninstaller.pkg"
DESKTOP_SHORTCUT="${HOME}/Desktop/NFC-Service Console.url.webloc"
DESKTOP_LEGACY_HTML="${HOME}/Desktop/NFC-Service-Test.html"

echo "==============================================="
echo "   DESINSTALADOR NFC SERVICE PARA macOS"
echo "==============================================="
echo

echo "[1/3] Deteniendo servicio..."
launchctl unload "${PLIST_PATH}" >/dev/null 2>&1 || true
rm -f "${PLIST_PATH}"
echo "[OK] Servicio detenido"

echo
echo "[2/4] Eliminando archivos del servicio..."
rm -rf "${SERVICE_ROOT}"
echo "[OK] Archivos eliminados"

echo
echo "[3/4] Eliminando acceso directo del Desktop..."
rm -f "${DESKTOP_SHORTCUT}" "${DESKTOP_LEGACY_HTML}"
echo "[OK] Acceso directo eliminado"

echo
echo "[4/4] Driver ACS"
if [[ -f "${DRIVER_UNINSTALLER}" ]]; then
  echo "Para desinstalar el driver ACS ejecuta:"
  echo "  sudo installer -pkg \"${DRIVER_UNINSTALLER}\" -target /"
  echo "o abre el paquete manualmente."
else
  echo "[WARN] No se encontro acsccid_uninstaller.pkg en el proyecto."
fi

echo
echo "Desinstalacion completada."
echo
