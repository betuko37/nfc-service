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
