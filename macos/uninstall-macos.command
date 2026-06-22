#!/bin/bash
set -euo pipefail

SERVICE_ROOT="${HOME}/.nfc-service"
PLIST_PATH="${HOME}/Library/LaunchAgents/com.nfcservice.agent.plist"
DRIVER_PKG_DIR="${SERVICE_ROOT}/acsccid-macosx-bin-1.1.11.1-20240826"
DRIVER_UNINSTALLER="${DRIVER_PKG_DIR}/acsccid_uninstaller.pkg"
DESKTOP_SHORTCUT="${HOME}/Desktop/NFC-Service Console.url.webloc"
DESKTOP_LEGACY_HTML="${HOME}/Desktop/NFC-Service-Test.html"
APPLICATIONS_APP="/Applications/NFC Service Installer.app"

echo "==============================================="
echo "   DESINSTALADOR NFC SERVICE PARA macOS"
echo "==============================================="
echo

echo "[1/5] Deteniendo servicio..."
launchctl unload "${PLIST_PATH}" >/dev/null 2>&1 || true
rm -f "${PLIST_PATH}"
echo "[OK] Servicio detenido"

echo
echo "[2/5] Driver ACS"
if [[ -f "${DRIVER_UNINSTALLER}" ]]; then
  AUTO_REMOVE_DRIVER="n"

  if [[ -t 0 ]]; then
    read -r -p "Deseas desinstalar tambien el driver ACS? (pedira password) [s/N]: " AUTO_REMOVE_DRIVER
  else
    AUTO_REMOVE_DRIVER="$(/usr/bin/osascript <<'APPLESCRIPT'
set answer to button returned of (display dialog "¿Desinstalar también el driver ACS del lector NFC?\n\nSe pedirá la contraseña de administrador." buttons {"No", "Sí"} default button "No" with icon caution)
if answer is "Sí" then
  return "s"
else
  return "n"
end if
APPLESCRIPT
)"
  fi

  case "${AUTO_REMOVE_DRIVER:-n}" in
    s|S|y|Y)
      echo "[INFO] Desinstalando driver ACS (se pedirá contraseña)..."
      sudo installer -pkg "${DRIVER_UNINSTALLER}" -target /
      echo "[OK] Driver ACS desinstalado"
      ;;
    *)
      echo "[INFO] Driver ACS no removido."
      echo "      Si luego quieres quitarlo manualmente:"
      echo "      sudo installer -pkg \"${DRIVER_UNINSTALLER}\" -target /"
      ;;
  esac
else
  echo "[WARN] No se encontro acsccid_uninstaller.pkg en:"
  echo "       ${DRIVER_UNINSTALLER}"
  echo "[INFO] Si el driver ACS sigue instalado, reinstala el servicio y vuelve a desinstalar,"
  echo "       o elimínalo manualmente desde la carpeta acsccid del proyecto."
fi

echo
echo "[3/5] Eliminando acceso directo del Desktop..."
rm -f "${DESKTOP_SHORTCUT}" "${DESKTOP_LEGACY_HTML}"
echo "[OK] Acceso directo eliminado"

echo
echo "[4/5] Eliminando accesos directos y apps en Applications..."
pkill -f "NFC Service Installer.app" >/dev/null 2>&1 || true
pkill -f "Desinstalar NFC Service.app" >/dev/null 2>&1 || true
pkill -f "install-macos.command" >/dev/null 2>&1 || true
rm -rf "${APPLICATIONS_APP}"
rm -rf "/Applications/Desinstalar NFC Service.app"
rm -f "/Applications/Desinstalar NFC Service.command"
echo "[OK] Accesos directos y apps en Applications eliminados"

echo
echo "[5/5] Eliminando archivos del servicio..."
rm -rf "${SERVICE_ROOT}"
echo "[OK] Archivos eliminados"

echo
echo "Desinstalacion completada."
echo

if [[ -t 0 ]]; then
  read -r -p "Presiona ENTER para cerrar esta ventana..."
fi
