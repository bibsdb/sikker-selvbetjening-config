#!/usr/bin/env bash
set -euo pipefail

SOURCE_IMAGE="${1:?source image path required}"
OUTPUT_ROOT="${2:?output root required}"

[[ -f "${SOURCE_IMAGE}" ]] || { echo "Missing background image: ${SOURCE_IMAGE}" >&2; exit 1; }

mkdir -p "${OUTPUT_ROOT}/usr/share/backgrounds/sikker-selvbetjening"
cp -f "${SOURCE_IMAGE}" "${OUTPUT_ROOT}/usr/share/backgrounds/sikker-selvbetjening/default-background"

mkdir -p "${OUTPUT_ROOT}/etc/dconf/db/local.d"
cat > "${OUTPUT_ROOT}/etc/dconf/db/local.d/03-desktop-background" <<'EOF'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/sikker-selvbetjening/default-background'
picture-uri-dark='file:///usr/share/backgrounds/sikker-selvbetjening/default-background'
picture-options='zoom'
primary-color='#000000'
secondary-color='#000000'
EOF
