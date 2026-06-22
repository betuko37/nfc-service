#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

BUILD_DIR="${PROJECT_DIR}/dist-macos"
STAGING_DIR="${BUILD_DIR}/staging"
HELPER_APP_NAME="INSTALAR.app"
HELPER_APP_PATH="${STAGING_DIR}/${HELPER_APP_NAME}"
PAYLOAD_DIR="${STAGING_DIR}/.payload"
PAYLOAD_ARCHIVE_NAME="nfc-service-payload.tar.gz"
ASSETS_DIR="${PROJECT_DIR}/macos/assets"
BACKGROUND_PATH="${ASSETS_DIR}/dmg-background.png"
VOLUME_ICON_PATH="${ASSETS_DIR}/dmg-volume-icon.icns"

DMG_NAME="NFC-Service-Installer.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
VOL_NAME="NFC Service Installer"
RW_DMG="${BUILD_DIR}/rw-temp.dmg"

require_file() {
  local f="$1"
  if [[ ! -e "${f}" ]]; then
    echo "[ERROR] Falta archivo requerido: ${f}"
    exit 1
  fi
}

find_create_dmg_support_dir() {
  if command -v brew >/dev/null 2>&1; then
    local prefix
    prefix="$(brew --prefix create-dmg 2>/dev/null || true)"
    if [[ -n "${prefix}" && -f "${prefix}/share/create-dmg/support/template.applescript" ]]; then
      echo "${prefix}/share/create-dmg/support"
      return 0
    fi
  fi

  if [[ -f "/opt/homebrew/share/create-dmg/support/template.applescript" ]]; then
    echo "/opt/homebrew/share/create-dmg/support"
    return 0
  fi

  if [[ -f "/usr/local/share/create-dmg/support/template.applescript" ]]; then
    echo "/usr/local/share/create-dmg/support"
    return 0
  fi

  return 1
}

create_installer_app() {
  rm -rf "${HELPER_APP_PATH}"
  mkdir -p "${HELPER_APP_PATH}/Contents/MacOS"
  mkdir -p "${HELPER_APP_PATH}/Contents/Resources"

  # Payload empaquetado en tar.gz (un solo archivo): menos bloqueos por antivirus
  # que scripts .command sueltos dentro del bundle.
  rm -f "${HELPER_APP_PATH}/Contents/Resources/${PAYLOAD_ARCHIVE_NAME}"
  tar -czf "${HELPER_APP_PATH}/Contents/Resources/${PAYLOAD_ARCHIVE_NAME}" -C "${PAYLOAD_DIR}" .
  cp "${HELPER_APP_PATH}/Contents/Resources/${PAYLOAD_ARCHIVE_NAME}" \
    "${HELPER_APP_PATH}/Contents/MacOS/${PAYLOAD_ARCHIVE_NAME}"

  cat > "${HELPER_APP_PATH}/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>launch-installer</string>
  <key>CFBundleIdentifier</key>
  <string>com.jornalpro.nfcservice.installer</string>
  <key>CFBundleName</key>
  <string>INSTALAR</string>
  <key>CFBundleDisplayName</key>
  <string>INSTALAR</string>
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

  cat > "${HELPER_APP_PATH}/Contents/MacOS/launch-installer" <<'EOF'
#!/bin/bash
set -euo pipefail

BUNDLE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MACOS_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_STAGING="${HOME}/.nfc-service-install-staging"
ARCHIVE=""

show_error() {
  local detail="$1"
  /usr/bin/osascript -e "display alert \"NFC Service Installer\" message \"${detail}\" as critical"
}

find_archive() {
  local volume_root
  volume_root="$(cd "${MACOS_DIR}/../../.." && pwd)"
  local candidates=(
    "${MACOS_DIR}/nfc-service-payload.tar.gz"
    "${BUNDLE_ROOT}/Resources/nfc-service-payload.tar.gz"
    "${BUNDLE_ROOT}/MacOS/nfc-service-payload.tar.gz"
    "${volume_root}/nfc-service-payload.tar.gz"
    "${HOME}/Downloads/nfc-service-payload.tar.gz"
  )
  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "${candidate}" ]]; then
      ARCHIVE="${candidate}"
      return 0
    fi
  done
  return 1
}

xattr -cr "${BUNDLE_ROOT}" 2>/dev/null || true

if ! find_archive; then
  show_error "No se encontró el paquete de instalación. Descarga el DMG completo desde la web (carpeta public/, no src/) y haz doble clic en INSTALAR dentro del DMG, sin arrastrar solo la app."
  exit 1
fi

rm -rf "${INSTALL_STAGING}"
mkdir -p "${INSTALL_STAGING}"

if ! tar -xzf "${ARCHIVE}" -C "${INSTALL_STAGING}" 2>/dev/null; then
  show_error "El paquete de instalación está dañado. El DMG puede haberse corrompido al subirlo al frontend: usa la carpeta public/ y enlace directo, no src/."
  exit 1
fi

INSTALL_SCRIPT="${INSTALL_STAGING}/macos/install-macos.command"
if [[ ! -f "${INSTALL_SCRIPT}" ]]; then
  show_error "Faltan archivos del instalador tras extraer. macOS o un antivirus puede haberlos bloqueado."
  exit 1
fi

chmod +x "${INSTALL_SCRIPT}" "${INSTALL_STAGING}/macos/"*.command 2>/dev/null || true
xattr -cr "${INSTALL_STAGING}" 2>/dev/null || true

RUNNER="${INSTALL_STAGING}/run-install.command"
cat > "${RUNNER}" <<RUNNER_EOF
#!/bin/bash
exec bash "${INSTALL_STAGING}/macos/install-macos.command"
RUNNER_EOF
chmod +x "${RUNNER}"
xattr -cr "${RUNNER}" 2>/dev/null || true

# Abrir Terminal con el instalador (no borrar staging aquí: Terminal arranca después).
open -a Terminal "${RUNNER}"
EOF

  chmod +x "${HELPER_APP_PATH}/Contents/MacOS/launch-installer"

  if [[ -f "${ASSETS_DIR}/dmg-volume-icon.icns" ]]; then
    cp "${ASSETS_DIR}/dmg-volume-icon.icns" "${HELPER_APP_PATH}/Contents/Resources/icon.icns"
  fi

  if [[ ! -f "${HELPER_APP_PATH}/Contents/Resources/${PAYLOAD_ARCHIVE_NAME}" ]]; then
    echo "[ERROR] No se generó ${PAYLOAD_ARCHIVE_NAME} dentro de ${HELPER_APP_NAME}"
    exit 1
  fi

  if ! tar -tzf "${HELPER_APP_PATH}/Contents/Resources/${PAYLOAD_ARCHIVE_NAME}" | rg -q 'macos/install-macos.command'; then
    echo "[ERROR] El archivo ${PAYLOAD_ARCHIVE_NAME} no contiene install-macos.command"
    exit 1
  fi

  echo "[OK] App instaladora creada: ${HELPER_APP_NAME} (payload empaquetado)"
}

build_dmg() {
  local support_dir
  support_dir="$(find_create_dmg_support_dir || true)"

  if [[ -z "${support_dir}" ]]; then
    echo "[ERROR] No se encontro template.applescript de create-dmg."
    echo "Instala con: brew install create-dmg"
    exit 1
  fi

  echo "[3/4] Generando DMG..."
  rm -f "${DMG_PATH}" "${RW_DMG}"

  hdiutil create \
    -volname "${VOL_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -fs HFS+ \
    -format UDRW \
    -ov \
    "${RW_DMG}"

  local dev_name mount_dir
  dev_name="$(hdiutil attach -readwrite -noverify -noautoopen "${RW_DMG}" | rg '^/dev/' | sed 1q | awk '{print $1}')"
  mount_dir="/Volumes/${VOL_NAME}"

  if [[ ! -d "${mount_dir}" ]]; then
    echo "[ERROR] No se pudo montar el DMG temporal en ${mount_dir}"
    exit 1
  fi

  local win_x=190 win_y=90 win_w=500 win_h=500 icon_size=64 text_size=11
  local position_clause application_clause hiding_clause background_clause="" reposition_clause ql_clause=""
  position_clause="set position of item \"${HELPER_APP_NAME}\" of container window to {370, 240}
"
  application_clause=""
  hiding_clause=""
  reposition_clause="set position of item \"${PAYLOAD_ARCHIVE_NAME}\" to {900, 900}
set the extension hidden of item \"${PAYLOAD_ARCHIVE_NAME}\" to true
"

  if [[ -f "${BACKGROUND_PATH}" ]]; then
    local bg_name
    bg_name="$(basename "${BACKGROUND_PATH}")"
    mkdir -p "${mount_dir}/.background"
    cp "${BACKGROUND_PATH}" "${mount_dir}/.background/${bg_name}"
    background_clause="set background picture of opts to file \".background:${bg_name}\""
  fi

  local applescript_file
  applescript_file="$(mktemp -t createdmg.tmp.XXXXXXXXXX)"
  cat "${support_dir}/template.applescript" \
    | sed -e "s/WINX/${win_x}/g" -e "s/WINY/${win_y}/g" -e "s/WINW/${win_w}/g" \
          -e "s/WINH/${win_h}/g" -e "s/BACKGROUND_CLAUSE/${background_clause}/g" \
          -e "s/ICON_SIZE/${icon_size}/g" -e "s/TEXT_SIZE/${text_size}/g" \
    | perl -pe "s:POSITION_CLAUSE:${position_clause}:g" \
    | perl -pe "s:REPOSITION_HIDDEN_FILES_CLAUSE:${reposition_clause}:g" \
    | perl -pe "s/APPLICATION_CLAUSE/${application_clause}/g" \
    | perl -pe "s:HIDING_CLAUSE:${hiding_clause}:" \
    | perl -pe "s/QL_CLAUSE/${ql_clause}/g" \
    > "${applescript_file}"

  echo "Configurando vista del Finder..."
  sleep 2
  /usr/bin/osascript "${applescript_file}" "${VOL_NAME}"
  rm -f "${applescript_file}"

  chmod -Rf go-w "${mount_dir}" >/dev/null 2>&1 || true

  if [[ -f "${VOLUME_ICON_PATH}" ]]; then
    cp "${VOLUME_ICON_PATH}" "${mount_dir}/.VolumeIcon.icns"
    if command -v SetFile >/dev/null 2>&1; then
      SetFile -c icnC "${mount_dir}/.VolumeIcon.icns" || true
      SetFile -a C "${mount_dir}" || true
    fi
  fi

  echo "Configurando auto-open al montar DMG..."
  if [[ "$(uname -m)" == "arm64" ]]; then
    bless --folder "${mount_dir}"
  else
    bless --folder "${mount_dir}" --openfolder "${mount_dir}"
  fi
  echo "[OK] Auto-open configurado"

  rm -rf "${mount_dir}/.fseventsd" || true

  hdiutil detach "${dev_name}" || hdiutil detach -force "${dev_name}"
  hdiutil convert "${RW_DMG}" -format UDZO -o "${DMG_PATH}"
  rm -f "${RW_DMG}"

  echo "[OK] DMG generado: ${DMG_PATH}"
}

echo "==============================================="
echo "   EMPAQUETADOR DMG - NFC SERVICE"
echo "==============================================="
echo

require_file "${PROJECT_DIR}/nfc-service.js"
require_file "${PROJECT_DIR}/console.html"
require_file "${PROJECT_DIR}/package.json"
require_file "${PROJECT_DIR}/macos/install-macos.command"
require_file "${PROJECT_DIR}/macos/generate-dmg-assets.py"

echo "[1/4] Preparando estructura..."
rm -rf "${BUILD_DIR}"
mkdir -p "${PAYLOAD_DIR}/macos"
echo "[OK] Directorios listos"

echo
echo "[1.5/4] Generando assets visuales del DMG..."
python3 "${PROJECT_DIR}/macos/generate-dmg-assets.py" >/dev/null
echo "[OK] Assets visuales listos"

echo
echo "[2/4] Copiando instalador..."
cp "${PROJECT_DIR}/nfc-service.js" "${PAYLOAD_DIR}/"
cp "${PROJECT_DIR}/console.html" "${PAYLOAD_DIR}/"
cp "${PROJECT_DIR}/package.json" "${PAYLOAD_DIR}/"
if [[ -f "${PROJECT_DIR}/package-lock.json" ]]; then
  cp "${PROJECT_DIR}/package-lock.json" "${PAYLOAD_DIR}/"
fi

cp "${PROJECT_DIR}/macos/install-macos.command" "${PAYLOAD_DIR}/macos/"
cp "${PROJECT_DIR}/macos/uninstall-macos.command" "${PAYLOAD_DIR}/macos/"
cp "${PROJECT_DIR}/macos/remove-applications-copy.command" "${PAYLOAD_DIR}/macos/"
chmod +x "${PAYLOAD_DIR}/macos/install-macos.command" \
  "${PAYLOAD_DIR}/macos/uninstall-macos.command" \
  "${PAYLOAD_DIR}/macos/remove-applications-copy.command"

if [[ -d "${PROJECT_DIR}/acsccid-macosx-bin-1.1.11.1-20240826" ]]; then
  cp -R "${PROJECT_DIR}/acsccid-macosx-bin-1.1.11.1-20240826" "${PAYLOAD_DIR}/"
else
  echo "[WARN] No se encontro carpeta de drivers ACS, se genera instalador sin driver embebido."
fi

create_installer_app
cp "${HELPER_APP_PATH}/Contents/Resources/${PAYLOAD_ARCHIVE_NAME}" "${STAGING_DIR}/${PAYLOAD_ARCHIVE_NAME}"
rm -rf "${PAYLOAD_DIR}"
echo "[OK] Payload empaquetado en ${HELPER_APP_NAME} + copia en volumen DMG"

echo
echo "[2.5/4] Firmando app y scripts del staging..."
chmod +x "${PROJECT_DIR}/macos/sign-and-notarize.command"
bash "${PROJECT_DIR}/macos/sign-and-notarize.command"

echo
build_dmg

echo
echo "[4/4] Firma y notarización del DMG para distribución web..."
bash "${PROJECT_DIR}/macos/sign-and-notarize.command" "${DMG_PATH}"

echo
echo "==============================================="
echo " DMG LISTO"
echo "==============================================="
echo "Salida: ${DMG_PATH}"
echo "Contenido principal:"
echo "  - ${HELPER_APP_NAME}"
echo
echo "Para tu frontend, copia a public/ (NO src/):"
echo "  ${DMG_PATH}"
echo "  ${BUILD_DIR}/${PAYLOAD_ARCHIVE_NAME}"
cp "${STAGING_DIR}/${PAYLOAD_ARCHIVE_NAME}" "${BUILD_DIR}/${PAYLOAD_ARCHIVE_NAME}" 2>/dev/null || \
  cp "${HELPER_APP_PATH}/Contents/Resources/${PAYLOAD_ARCHIVE_NAME}" "${BUILD_DIR}/${PAYLOAD_ARCHIVE_NAME}" 2>/dev/null || true
echo
