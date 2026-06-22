#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESOURCES_DIR="$(cd "${SCRIPT_DIR}/../Resources" && pwd)"
INSTALL_SCRIPT="${RESOURCES_DIR}/payload/macos/install-macos.command"
APP_BUNDLE="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SERVICE_MARKER="${HOME}/.nfc-service/app/nfc-service.js"
CONSOLE_URL="http://127.0.0.1:47321/console"
DESKTOP_SHORTCUT="${HOME}/Desktop/NFC-Service Console.url.webloc"
APPLICATIONS_APP="/Applications/NFC Service Installer.app"

escape_for_applescript() {
  printf '%s' "$1" | sed "s/'/'\\\\''/g"
}

run_install_in_terminal() {
  local cleanup_target="${1:-}"
  local escaped_script
  escaped_script="$(escape_for_applescript "${INSTALL_SCRIPT}")"
  local command
  command="exec bash '${escaped_script}'"

  if [[ -n "${cleanup_target}" ]]; then
    local escaped_cleanup
    escaped_cleanup="$(escape_for_applescript "${cleanup_target}")"
    command="${command} --cleanup-app '${escaped_cleanup}'"
  fi

  osascript <<APPLESCRIPT
tell application "Terminal"
  activate
  do script "${command}"
end tell
APPLESCRIPT
}

create_desktop_shortcut() {
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
}

if [[ ! -f "${INSTALL_SCRIPT}" ]]; then
  osascript -e 'display alert "NFC Service Installer" message "No se encontro el script de instalacion." as critical'
  exit 1
fi

# Servicio ya instalado: acceso directo + consola (igual que install-macos.command al final).
if [[ -f "${SERVICE_MARKER}" ]]; then
  create_desktop_shortcut
  open "${CONSOLE_URL}" >/dev/null 2>&1 || true
  exit 0
fi

# Desde el DMG: instalar directo (no hace falta arrastrar a Applications).
if [[ "${APP_BUNDLE}" == /Volumes/* ]]; then
  run_install_in_terminal
  exit 0
fi

# Desde Applications: instalar igual que install-macos.command.
if [[ "${APP_BUNDLE}" == "${APPLICATIONS_APP}" ]] || [[ "${APP_BUNDLE}" == /Applications/* ]]; then
  run_install_in_terminal "${APP_BUNDLE}"
  exit 0
fi

run_install_in_terminal
