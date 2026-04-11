#!/usr/bin/env bash
set -euo pipefail

HOST="$1"
IMAGE_REPO="ghcr.io/bibsdb/sikker-selvbetjening-config-image"

ansible-playbook -i inventory/hosts.yml playbooks/render-host-overlays.yml --limit "$HOST"

podman build \
  -t ${IMAGE_REPO}/${HOST}:latest \
  -f - . <<EOF
FROM scratch
COPY build/${HOST}/usr/ /usr/
EOF

podman push ${IMAGE_REPO}/${HOST}:latest
