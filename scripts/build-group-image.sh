#!/usr/bin/env bash
set -euo pipefail

GROUP="$1"
IMAGE_NAME="${2:-$GROUP}"
IMAGE_REPO="ghcr.io/bibsdb/sikker-selvbetjening-config-image"
BASE_IMAGE="ghcr.io/bibsdb/borgerpc-ublue"
DATE_TAG="$(date -u +%Y%m%d)"

if [[ -n "${GITHUB_SHA:-}" ]]; then
  SHA_TAG="sha-${GITHUB_SHA:0:7}"
elif command -v git >/dev/null 2>&1 && git rev-parse --short HEAD >/dev/null 2>&1; then
  SHA_TAG="sha-$(git rev-parse --short HEAD)"
else
  SHA_TAG=""
fi

TAGS=(
  "latest"
  "latest.${DATE_TAG}"
  "${DATE_TAG}"
)

if [[ -n "$SHA_TAG" ]]; then
  TAGS+=("$SHA_TAG")
fi

rm -rf "build/${IMAGE_NAME}"
ansible-playbook -i localhost, playbooks/render-host-overlays.yml -e "target_group=${GROUP}" -e "build_name=${IMAGE_NAME}"

podman build \
  -t ${IMAGE_REPO}/${IMAGE_NAME}:latest \
  -f - . <<EOF
FROM ${BASE_IMAGE}
COPY build/${IMAGE_NAME}/usr/ /usr/
EOF

for tag in "${TAGS[@]}"; do
  if [[ "$tag" != "latest" ]]; then
    podman tag "${IMAGE_REPO}/${IMAGE_NAME}:latest" "${IMAGE_REPO}/${IMAGE_NAME}:${tag}"
  fi
  podman push "${IMAGE_REPO}/${IMAGE_NAME}:${tag}"
done
