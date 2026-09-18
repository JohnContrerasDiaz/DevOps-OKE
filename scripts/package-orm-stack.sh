#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STACK_DIRECTORY="${REPOSITORY_ROOT}/terraform/oke-vcn-private-api"
OUTPUT_DIRECTORY="${REPOSITORY_ROOT}/dist"
OUTPUT_FILE="${OUTPUT_DIRECTORY}/oke-vcn-private-api-resource-manager.zip"

command -v zip >/dev/null 2>&1 || {
  echo "Error: zip no esta instalado." >&2
  exit 1
}

mkdir -p "${OUTPUT_DIRECTORY}"
(
  cd "${STACK_DIRECTORY}"
  zip -FSr "${OUTPUT_FILE}" . -x '.terraform/*' '*.tfstate*' '*.tfplan' '*.tfvars' '*.zip'
)
echo "Stack creado: ${OUTPUT_FILE}"
