#!/bin/bash
# Copia el DMG macOS al frontend (public/, no src/).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

FRONTEND_PUBLIC="${1:-${HOME}/Proyects_JornalPro/JornalPro-AdminAgricola-Front/public/installers-NFC/MACOS}"

DMG="${PROJECT_DIR}/dist-macos/NFC-Service-Installer.dmg"
PAYLOAD="${PROJECT_DIR}/dist-macos/nfc-service-payload.tar.gz"

if [[ ! -f "${DMG}" ]]; then
  echo "[ERROR] Genera el DMG primero: bash macos/build-dmg.command"
  exit 1
fi

mkdir -p "${FRONTEND_PUBLIC}"
cp "${DMG}" "${FRONTEND_PUBLIC}/"
cp "${PAYLOAD}" "${FRONTEND_PUBLIC}/"

echo "[OK] Copiado a ${FRONTEND_PUBLIC}:"
ls -lh "${FRONTEND_PUBLIC}/NFC-Service-Installer.dmg" "${FRONTEND_PUBLIC}/nfc-service-payload.tar.gz"
