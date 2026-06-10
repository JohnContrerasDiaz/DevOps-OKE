#!/usr/bin/env bash
set -euo pipefail

COMPARTMENT_ID="${WORKSHOP_COMPARTMENT_OCID:-}"
REPOSITORY_PREFIX="${REPOSITORY_PREFIX:-devops-oke}"

usage() {
  cat <<USAGE
Usage: WORKSHOP_COMPARTMENT_OCID=<compartment_ocid> [REPOSITORY_PREFIX=devops-oke] bash scripts/create-ocir-repositories.sh
USAGE
}

if [[ -z "$COMPARTMENT_ID" ]]; then
  usage
  exit 1
fi

create_repo() {
  local repo_name="$1"
  echo "Creating private OCIR repository: ${repo_name}"
  if ! oci artifacts container repository create \
    --display-name "${repo_name}" \
    --compartment-id "${COMPARTMENT_ID}" \
    --is-public false; then
    echo "Repository ${repo_name} might already exist. Review the OCI CLI message above."
  fi
}

create_repo "${REPOSITORY_PREFIX}/backend"
create_repo "${REPOSITORY_PREFIX}/frontend"