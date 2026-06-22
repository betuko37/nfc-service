#!/bin/bash
set -euo pipefail

APP_PATH="/Applications/NFC Service Installer.app"
PLIST_PATH="${HOME}/Library/LaunchAgents/com.nfcservice.agent.plist"

echo "==============================================="
echo "   QUITAR COPIA EN APPLICATIONS"
echo "==============================================="
echo

if [[ ! -d "${APP_PATH}" ]]; then
  echo "[INFO] No hay copia en Applications."
  exit 0
fi

echo "[1/2] Cerrando procesos del instalador..."
pkill -f "NFC Service Installer.app" >/dev/null 2>&1 || true
pkill -f "install-macos.command" >/dev/null 2>&1 || true
launchctl unload "${PLIST_PATH}" >/dev/null 2>&1 || true
sleep 1

echo "[2/2] Eliminando ${APP_PATH}..."
if rm -rf "${APP_PATH}"; then
  echo "[OK] Copia eliminada. Ahora puedes arrastrar de nuevo desde el DMG."
else
  echo "[ERROR] No se pudo eliminar. Intenta:"
  echo "  sudo rm -rf \"${APP_PATH}\""
  exit 1
fi

echo
