#!/bin/bash
# Firma y notariza el DMG para distribución web (evita alerta de Gatekeeper).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DMG_PATH="${1:-${PROJECT_DIR}/dist-macos/NFC-Service-Installer.dmg}"
STAGING_DIR="${PROJECT_DIR}/dist-macos/staging"

if ! command -v codesign >/dev/null 2>&1; then
  echo "[ERROR] codesign no disponible. Instala Xcode Command Line Tools."
  exit 1
fi

resolve_sign_identity() {
  if [[ -n "${MACOS_SIGN_IDENTITY:-}" ]]; then
    echo "${MACOS_SIGN_IDENTITY}"
    return 0
  fi

  local found
  found="$(security find-identity -v -p codesigning 2>/dev/null | rg 'Developer ID Application' | head -1 | sed -E 's/.*\"([^\"]+)\".*/\1/' || true)"
  if [[ -n "${found}" ]]; then
    echo "${found}"
    return 0
  fi

  echo "-"
}

sign_path() {
  local target="$1"
  local identity="$2"

  if [[ "${target}" == *.app ]]; then
    xattr -cr "${target}" 2>/dev/null || true
    codesign --force --deep --sign "${identity}" --timestamp --options runtime "${target}"
  else
    codesign --force --sign "${identity}" --timestamp --options runtime "${target}"
  fi
}

sign_staging_tree() {
  local root="$1"
  local identity="$2"

  while IFS= read -r -d '' f; do
    sign_path "${f}" "${identity}"
  done < <(find "${root}" -type f \( -name "*.command" -o -name "*.sh" \) -perm -111 -print0)

  while IFS= read -r -d '' app; do
    sign_path "${app}" "${identity}"
  done < <(find "${root}" -name "*.app" -print0)
}

notarize_dmg() {
  local dmg="$1"

  if [[ -z "${APPLE_NOTARIZE_APPLE_ID:-}" || -z "${APPLE_NOTARIZE_TEAM_ID:-}" ]]; then
    echo "[WARN] Notarización omitida (faltan APPLE_NOTARIZE_APPLE_ID / APPLE_NOTARIZE_TEAM_ID)."
    return 0
  fi

  local password="${APPLE_NOTARIZE_PASSWORD:-${APPLE_NOTARIZE_APP_SPECIFIC_PASSWORD:-}}"
  if [[ -z "${password}" ]]; then
    echo "[WARN] Notarización omitida (falta APPLE_NOTARIZE_PASSWORD o APPLE_NOTARIZE_APP_SPECIFIC_PASSWORD)."
    return 0
  fi

  if ! command -v xcrun >/dev/null 2>&1; then
    echo "[WARN] xcrun no disponible; no se puede notarizar."
    return 0
  fi

  echo "[INFO] Enviando DMG a Apple para notarización (puede tardar varios minutos)..."
  xcrun notarytool submit "${dmg}" \
    --apple-id "${APPLE_NOTARIZE_APPLE_ID}" \
    --team-id "${APPLE_NOTARIZE_TEAM_ID}" \
    --password "${password}" \
    --wait

  xcrun stapler staple "${dmg}"
  echo "[OK] DMG notarizado y staple aplicado."
}

main() {
  local identity
  identity="$(resolve_sign_identity)"

  if [[ "${identity}" == "-" ]]; then
    echo "[WARN] Sin certificado Developer ID: se usa firma ad-hoc."
    echo "       macOS bloqueará el archivo al descargarlo de internet."
    echo "       Configura MACOS_SIGN_IDENTITY y notarización para distribución web."
  else
    echo "[INFO] Firmando con: ${identity}"
  fi

  if [[ ! -f "${DMG_PATH}" ]]; then
    if [[ -d "${STAGING_DIR}" ]]; then
      sign_staging_tree "${STAGING_DIR}" "${identity}"
      echo "[OK] Staging firmado."
    fi
    echo "[INFO] DMG aún no generado; se omitió firma/notarización del DMG."
    return 0
  fi

  if [[ "${identity}" != "-" ]]; then
    codesign --force --sign "${identity}" --timestamp "${DMG_PATH}"
    echo "[OK] DMG firmado."
  fi

  notarize_dmg "${DMG_PATH}"
}

main "$@"
