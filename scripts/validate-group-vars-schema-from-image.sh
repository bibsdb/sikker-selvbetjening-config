#!/usr/bin/env bash
set -euo pipefail

BASE_IMAGE="${BASE_IMAGE:-ghcr.io/bibsdb/sikker-selvbetjening}"
SCHEMAS_PATH_IN_IMAGE="${SCHEMAS_PATH_IN_IMAGE:-/usr/share/sikker-selvbetjening/schemas}"
GROUP_VARS_GLOB="${GROUP_VARS_GLOB:-config/group_vars/*.yml}"

if ! command -v podman >/dev/null 2>&1; then
  echo "podman is required to extract schemas from the base image" >&2
  exit 1
fi

if ! command -v check-jsonschema >/dev/null 2>&1; then
  echo "check-jsonschema is required to validate group_vars" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
container_id=""

cleanup() {
  if [[ -n "$container_id" ]]; then
    podman rm -f "$container_id" >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "Pulling base image: $BASE_IMAGE"
if ! podman pull "$BASE_IMAGE" >/dev/null; then
  cat >&2 <<'EOF'
Failed to pull base image for schema validation.

The base image must be publicly readable in GHCR, or the runner token/user must
have package read access to that image.
EOF
  exit 1
fi

container_id="$(podman create "$BASE_IMAGE")"
mkdir -p "$tmp_dir/schemas"
podman cp "$container_id:$SCHEMAS_PATH_IN_IMAGE/." "$tmp_dir/schemas"
podman rm "$container_id" >/dev/null
container_id=""

schema_file="$tmp_dir/schemas/group-vars.schema.json"
if [[ ! -f "$schema_file" ]]; then
  echo "Expected schema not found in base image: $SCHEMAS_PATH_IN_IMAGE/group-vars.schema.json" >&2
  exit 1
fi

shopt -s nullglob
group_var_files=( $GROUP_VARS_GLOB )
shopt -u nullglob

if [[ ${#group_var_files[@]} -eq 0 ]]; then
  echo "No group_vars files found matching: $GROUP_VARS_GLOB" >&2
  exit 1
fi

echo "Validating ${#group_var_files[@]} group_vars file(s) against schema from base image"
check-jsonschema --schemafile "$schema_file" "${group_var_files[@]}"
