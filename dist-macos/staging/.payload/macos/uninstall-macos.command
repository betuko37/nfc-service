#!/bin/bash
set -euo pipefail

SERVICE_ROOT="${HOME}/.nfc-service"
PLIST_PATH="${HOME}/Library/LaunchAgents/com.nfcservice.agent.plist"
DRIVER_UNINSTALLER="$(cd "$(dirname "$0")/.." && pwd)/acsccid-macosx-bin-1.1.11.1-20240826/acsccid_uninstaller.pkg"
DESKTOP_SHORTCUT="${HOME}/Desktop/NFC-Service Console.url.webloc"
DESKTOP_LEGACY_HTML="${HOME}/Desktop/NFC-Service-Test.html"
APPLICATIONS_APP="/Applications/NFC Service Installer.app"

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
echo "[3/5] Eliminando acceso directo del Desktop..."
rm -f "${DESKTOP_SHORTCUT}" "${DESKTOP_LEGACY_HTML}"
echo "[OK] Acceso directo eliminado"

echo
echo "[4/5] Eliminando app del instalador en Applications..."
pkill -f "NFC Service Installer.app" >/dev/null 2>&1 || true
pkill -f "install-macos.command" >/dev/null 2>&1 || true
rm -rf "${APPLICATIONS_APP}"
echo "[OK] App de instalador eliminada (si existia)"

echo
echo "[5/5] Driver ACS"
if [[ -f "${DRIVER_UNINSTALLER}" ]]; then
  AUTO_REMOVE_DRIVER="n"

  if [[ -t 0 ]]; then
    read -r -p "Deseas desinstalar tambien el driver ACS? (pedira password) [s/N]: " AUTO_REMOVE_DRIVER
  fi

  case "${AUTO_REMOVE_DRIVER:-n}" in
    s|S|y|Y)
      sudo installer -pkg "${DRIVER_UNINSTALLER}" -target /
      echo "[OK] Driver ACS desinstalado"
      ;;
    *)
      echo "[INFO] Driver ACS no removido."
      echo "      Si luego quieres quitarlo, ejecuta:"
      echo "      sudo installer -pkg \"${DRIVER_UNINSTALLER}\" -target /"
      ;;
  esac
else
  echo "[WARN] No se encontro acsccid_uninstaller.pkg en el proyecto."
fi

echo
echo "Desinstalacion completada."
echo
