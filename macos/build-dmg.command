#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

BUILD_DIR="${PROJECT_DIR}/dist-macos"
STAGING_DIR="${BUILD_DIR}/staging"
HELPER_NAME="INSTALAR.command"
HELPER_PATH="${STAGING_DIR}/${HELPER_NAME}"
PAYLOAD_DIR="${STAGING_DIR}/.payload"
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

build_dmg() {
  local support_dir
  support_dir="$(find_create_dmg_support_dir || true)"

  if [[ -z "${support_dir}" ]]; then
    echo "[ERROR] No se encontro template.applescript de create-dmg."
    echo "Instala con: brew install create-dmg"
    exit 1
  fi

  echo "[3/3] Generando DMG..."
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
  position_clause="set position of item \"${HELPER_NAME}\" of container window to {370, 240}
"
  application_clause=""
  hiding_clause="set the extension hidden of item \"${HELPER_NAME}\" of container window to true
"
  reposition_clause="set position of item \".payload\" to {900, 900}
set the extension hidden of item \".payload\" to true
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

  hdiutil detach "${dev_name}"
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

echo "[1/3] Preparando estructura..."
rm -rf "${BUILD_DIR}"
mkdir -p "${PAYLOAD_DIR}/macos"
echo "[OK] Directorios listos"

echo
echo "[1.5/3] Generando assets visuales del DMG..."
python3 "${PROJECT_DIR}/macos/generate-dmg-assets.py" >/dev/null
echo "[OK] Assets visuales listos"

echo
echo "[2/3] Copiando instalador..."
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

cat > "${HELPER_PATH}" <<'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SCRIPT="${SCRIPT_DIR}/.payload/macos/install-macos.command"

if [[ ! -f "${INSTALL_SCRIPT}" ]]; then
  osascript -e 'display alert "NFC Service Installer" message "No se encontró install-macos.command dentro del DMG." as critical'
  exit 1
fi

# Ejecutar el instalador directamente en esta misma ventana de Terminal
exec bash "${INSTALL_SCRIPT}"
EOF
chmod +x "${HELPER_PATH}"
echo "[OK] Archivo principal creado: ${HELPER_NAME}"

echo
build_dmg

echo
echo "==============================================="
echo " DMG LISTO"
echo "==============================================="
echo "Salida: ${DMG_PATH}"
echo "Contenido principal:"
echo "  - ${HELPER_NAME}"
echo
