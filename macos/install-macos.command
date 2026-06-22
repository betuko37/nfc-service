#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SERVICE_ROOT="${HOME}/.nfc-service"
APP_DIR="${SERVICE_ROOT}/app"
LOG_DIR="${SERVICE_ROOT}/logs"
RUNTIME_DIR="${SERVICE_ROOT}/runtime"
RUNNER_PATH="${SERVICE_ROOT}/run-nfc-service.sh"
PLIST_PATH="${HOME}/Library/LaunchAgents/com.nfcservice.agent.plist"

DRIVER_PKG_DIR="${PROJECT_DIR}/acsccid-macosx-bin-1.1.11.1-20240826"
DRIVER_INSTALLER="${DRIVER_PKG_DIR}/acsccid_installer.pkg"
DESKTOP_SHORTCUT="${HOME}/Desktop/NFC-Service Console.url.webloc"
ACS_DRIVER_DIR="/usr/local/libexec/SmartCardServices/drivers"
CLEANUP_APP_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cleanup-app)
      if [[ $# -lt 2 ]]; then
        echo "[ERROR] Falta ruta para --cleanup-app"
        exit 1
      fi
      CLEANUP_APP_PATH="$2"
      shift 2
      ;;
    *)
      echo "[WARN] Argumento no reconocido: $1"
      shift
      ;;
  esac
done

echo "==============================================="
echo "   INSTALADOR NFC SERVICE PARA macOS"
echo "==============================================="
echo

if [[ ! -f "${PROJECT_DIR}/nfc-service.js" ]]; then
  echo "[ERROR] No se encontro nfc-service.js en el proyecto."
  exit 1
fi

has_acs_driver() {
  [[ -d "${ACS_DRIVER_DIR}" ]] || return 1
  ls "${ACS_DRIVER_DIR}" 2>/dev/null | grep -Eiq 'acs|ccid' || return 1
  return 0
}

echo "[1/7] Verificando driver ACS (modo sin admin por defecto)..."
if has_acs_driver; then
  echo "[OK] Driver ACS detectado en el sistema. No se requiere password."
else
  echo "[WARN] No se detecto driver ACS instalado."
  if [[ -f "${DRIVER_INSTALLER}" ]]; then
    if [[ -t 0 ]]; then
      read -r -p "Instalar driver ahora? (pedira password) [s/N]: " INSTALL_DRIVER_REPLY
    else
      INSTALL_DRIVER_REPLY="n"
    fi

    case "${INSTALL_DRIVER_REPLY:-n}" in
      s|S|y|Y)
        sudo installer -pkg "${DRIVER_INSTALLER}" -target /
        echo "[OK] Driver ACS instalado"
        ;;
      *)
        echo "[INFO] Se omite instalacion de driver por ahora."
        echo "       Si el lector no aparece, ejecuta luego:"
        echo "       sudo installer -pkg \"${DRIVER_INSTALLER}\" -target /"
        ;;
    esac
  else
    echo "[WARN] No se encontro el paquete de driver en:"
    echo "       ${DRIVER_INSTALLER}"
    echo "[INFO] Continuando solo con instalacion del servicio."
  fi
fi

echo
echo "[2/7] Preparando directorio de servicio..."
mkdir -p "${APP_DIR}" "${LOG_DIR}" "${RUNTIME_DIR}"
rm -rf "${APP_DIR:?}/"*
cp "${PROJECT_DIR}/nfc-service.js" "${APP_DIR}/"
cp "${PROJECT_DIR}/console.html" "${APP_DIR}/"
cp "${PROJECT_DIR}/package.json" "${APP_DIR}/"
if [[ -f "${PROJECT_DIR}/package-lock.json" ]]; then
  cp "${PROJECT_DIR}/package-lock.json" "${APP_DIR}/"
fi
echo "[OK] Archivos copiados en ${APP_DIR}"

echo
echo "[3/7] Descargando runtime Node.js LTS compatible..."
ARCH="$(uname -m)"
case "${ARCH}" in
  arm64) NODE_ARCH="arm64" ;;
  x86_64) NODE_ARCH="x64" ;;
  *)
    echo "[ERROR] Arquitectura no soportada: ${ARCH}"
    exit 1
    ;;
esac

NODE_VERSION="$(
  curl -fsSL "https://nodejs.org/dist/index.json" | python3 -c '
import json, sys
versions = json.load(sys.stdin)
for item in versions:
    v = item.get("version", "")
    if v.startswith("v20."):
        print(v)
        break
'
)"

if [[ -z "${NODE_VERSION}" ]]; then
  echo "[ERROR] No se pudo resolver una version LTS compatible de Node 20.x."
  exit 1
fi

NODE_TAR="node-${NODE_VERSION}-darwin-${NODE_ARCH}.tar.gz"
NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_TAR}"
TMP_TAR="${SERVICE_ROOT}/${NODE_TAR}"

echo "Descargando ${NODE_TAR}..."
curl -fL "${NODE_URL}" -o "${TMP_TAR}"
rm -rf "${RUNTIME_DIR:?}/"*
tar -xzf "${TMP_TAR}" -C "${RUNTIME_DIR}"
rm -f "${TMP_TAR}"

NODE_HOME="${RUNTIME_DIR}/node-${NODE_VERSION}-darwin-${NODE_ARCH}"
NODE_BIN="${NODE_HOME}/bin/node"
NPM_BIN="${NODE_HOME}/bin/npm"
NPM_CLI="${NODE_HOME}/lib/node_modules/npm/bin/npm-cli.js"
NODE_GYP_JS="${NODE_HOME}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js"

if [[ ! -x "${NODE_BIN}" || ! -x "${NPM_BIN}" || ! -f "${NPM_CLI}" ]]; then
  echo "[ERROR] Runtime Node descargado pero incompleto."
  exit 1
fi

echo "[OK] Runtime Node listo: ${NODE_VERSION} (${NODE_ARCH})"

echo
echo "[4/7] Instalando dependencias Node para macOS..."
cd "${APP_DIR}"
# Forzar que npm/node-gyp usen el runtime descargado y NO el Node global.
export PATH="${NODE_HOME}/bin:${PATH}"
export npm_config_nodedir="${NODE_HOME}"
export npm_config_node_gyp="${NODE_GYP_JS}"
export npm_config_cache="${SERVICE_ROOT}/npm-cache"
unset npm_config_prefix || true

if [[ -f "${APP_DIR}/package-lock.json" ]]; then
  "${NODE_BIN}" "${NPM_CLI}" ci --omit=dev --no-audit --no-fund
else
  "${NODE_BIN}" "${NPM_CLI}" install --omit=dev --no-audit --no-fund
fi
echo "[OK] Dependencias instaladas"

echo
echo "[5/7] Creando runner del servicio..."
cat > "${RUNNER_PATH}" <<EOF
#!/bin/bash
set -euo pipefail
cd "${APP_DIR}"
exec "${NODE_BIN}" "${APP_DIR}/nfc-service.js" >> "${LOG_DIR}/service.log" 2>&1
EOF
chmod +x "${RUNNER_PATH}"
echo "[OK] Runner creado en ${RUNNER_PATH}"

echo
echo "[6/7] Configurando auto inicio (launchd)..."
mkdir -p "${HOME}/Library/LaunchAgents"
cat > "${PLIST_PATH}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.nfcservice.agent</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${RUNNER_PATH}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>${APP_DIR}</string>
  <key>StandardOutPath</key>
  <string>${LOG_DIR}/launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/launchd.err.log</string>
</dict>
</plist>
EOF

launchctl unload "${PLIST_PATH}" >/dev/null 2>&1 || true
launchctl load "${PLIST_PATH}"
echo "[OK] Auto inicio configurado"

echo
echo "[7/7] Verificando servicio HTTP..."
ATTEMPT=0
MAX_ATTEMPTS=20
until curl -fsS "http://127.0.0.1:47321/ping" >/dev/null 2>&1; do
  ATTEMPT=$((ATTEMPT + 1))
  if [[ "${ATTEMPT}" -ge "${MAX_ATTEMPTS}" ]]; then
    echo "[WARN] El servicio no respondio en el puerto 47321 aun."
    echo "Revisa logs en: ${LOG_DIR}/service.log"
    break
  fi
  sleep 1
done

if [[ "${ATTEMPT}" -lt "${MAX_ATTEMPTS}" ]]; then
  echo "[OK] Servicio activo en http://127.0.0.1:47321"
fi

echo
echo "[INFO] Creando acceso directo en Desktop..."
cat > "${DESKTOP_SHORTCUT}" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>URL</key>
  <string>http://127.0.0.1:47321/console</string>
</dict>
</plist>
EOF
echo "[OK] Acceso directo creado: ${DESKTOP_SHORTCUT}"

echo
echo "[INFO] Copiando desinstalador para acceso futuro..."
UNINSTALL_DIR="${SERVICE_ROOT}/uninstall"
mkdir -p "${UNINSTALL_DIR}"
cp "${SCRIPT_DIR}/uninstall-macos.command" "${UNINSTALL_DIR}/"
chmod +x "${UNINSTALL_DIR}/uninstall-macos.command"

if [[ -d "${PROJECT_DIR}/acsccid-macosx-bin-1.1.11.1-20240826" ]]; then
  cp -R "${PROJECT_DIR}/acsccid-macosx-bin-1.1.11.1-20240826" "${SERVICE_ROOT}/"
fi

echo "[INFO] Creando acceso directo del desinstalador en Applications..."
pkill -f "Desinstalar NFC Service.app" >/dev/null 2>&1 || true
rm -rf "/Applications/Desinstalar NFC Service.app"

APP_BUNDLE="/Applications/Desinstalar NFC Service.app"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Escribir Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>launch-uninstaller</string>
  <key>CFBundleIdentifier</key>
  <string>com.nfcservice.uninstaller</string>
  <key>CFBundleName</key>
  <string>Desinstalar NFC Service</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.13</string>
  <key>CFBundleIconFile</key>
  <string>icon.icns</string>
  <key>LSUIElement</key>
  <false/>
</dict>
</plist>
EOF

# Escribir ejecutable del bundle
cat > "${APP_BUNDLE}/Contents/MacOS/launch-uninstaller" <<'EOF'
#!/bin/bash
set -euo pipefail

UNINSTALL_SCRIPT="${HOME}/.nfc-service/uninstall/uninstall-macos.command"

if [[ ! -f "${UNINSTALL_SCRIPT}" ]]; then
  /usr/bin/osascript -e 'display alert "Desinstalador NFC Service" message "No se encontró el script de desinstalación en ~/.nfc-service." as critical'
  exit 1
fi

/usr/bin/osascript <<APPLESCRIPT
tell application "Terminal"
  activate
  do script "exec bash '${UNINSTALL_SCRIPT}'"
end tell
APPLESCRIPT
EOF

chmod +x "${APP_BUNDLE}/Contents/MacOS/launch-uninstaller"

# Copiar el icono corporativo para que se vea hermoso en Launchpad/Applications
if [[ -f "${PROJECT_DIR}/macos/assets/dmg-volume-icon.icns" ]]; then
  cp "${PROJECT_DIR}/macos/assets/dmg-volume-icon.icns" "${APP_BUNDLE}/Contents/Resources/icon.icns"
fi

echo "[OK] App de desinstalación creada en /Applications"

echo "[INFO] Abriendo consola web..."
open "http://127.0.0.1:47321/console" >/dev/null 2>&1 || true

echo
echo "==============================================="
echo " INSTALACION COMPLETADA"
echo "==============================================="
echo "Consola web: http://127.0.0.1:47321/console"
echo "Estado:      http://127.0.0.1:47321/status"
echo "Logs:        ${LOG_DIR}/service.log"
echo "Node runtime:${NODE_HOME}"
echo "Acceso directo: ${DESKTOP_SHORTCUT}"
echo

if [[ -n "${CLEANUP_APP_PATH}" ]]; then
  if [[ "${CLEANUP_APP_PATH}" == /Applications/* ]] && [[ -d "${CLEANUP_APP_PATH}" ]]; then
    echo "[INFO] Se eliminara la app instaladora de Applications..."
    (sleep 2; rm -rf "${CLEANUP_APP_PATH}" >/dev/null 2>&1 || true) &
  fi
fi

if [[ -t 0 ]]; then
  read -r -p "Presiona ENTER para cerrar esta ventana..."
fi
