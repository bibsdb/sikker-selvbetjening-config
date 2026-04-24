#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_CONFIG_FILE="${IMAGE_CONFIG_FILE:-$REPO_ROOT/.env}"

if [[ -f "$IMAGE_CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$IMAGE_CONFIG_FILE"
fi

TARGET_GROUPS_CSV="$1"
FIRST_GROUP="${TARGET_GROUPS_CSV%%,*}"
IMAGE_NAME="${2:-$FIRST_GROUP}"
IMAGE_REPO="${IMAGE_REPO:-ghcr.io/bibsdb/sikker-selvbetjening-config}"
BASE_IMAGE="${BASE_IMAGE:-ghcr.io/bibsdb/sikker-selvbetjening:latest}"
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
ansible-playbook -i localhost, playbooks/render-host-overlays.yml -e "target_groups=${TARGET_GROUPS_CSV}" -e "build_name=${IMAGE_NAME}"

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
