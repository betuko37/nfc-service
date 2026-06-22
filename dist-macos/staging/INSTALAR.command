#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SCRIPT="${SCRIPT_DIR}/.payload/macos/install-macos.command"

if [[ ! -f "${INSTALL_SCRIPT}" ]]; then
  osascript -e 'display alert "NFC Service Installer" message "No se encontro install-macos.command dentro del DMG." as critical'
  exit 1
fi

escape_for_applescript() {
  printf '%s' "$1" | sed "s/'/'\\\\''/g"
}

escaped_script="$(escape_for_applescript "${INSTALL_SCRIPT}")"

/usr/bin/osascript <<APPLESCRIPT
tell application "Terminal"
  activate
  do script "exec bash '${escaped_script}'"
end tell
APPLESCRIPT
