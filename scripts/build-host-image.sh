#!/usr/bin/env bash
set -euo pipefail

HOST="$1"

ansible-playbook -i inventory/hosts.yml playbooks/render-host-overlays.yml --limit "$HOST"

podman build \
  -t registry.example.com/configs/${HOST}:latest \
  -f - . <<EOF
FROM scratch
COPY build/${HOST}/usr/ /usr/
EOF

podman push registry.example.com/configs/${HOST}:latest
