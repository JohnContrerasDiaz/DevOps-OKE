#!/usr/bin/env bash
set -euo pipefail

: "${OCIR_REGION_KEY:?Set OCIR_REGION_KEY, for example ord, iad, phx, gru, bog}"
: "${TENANCY_NAMESPACE:?Set TENANCY_NAMESPACE or run: export TENANCY_NAMESPACE=$(oci os ns get --query data --raw-output)}"

REPOSITORY_PREFIX="${REPOSITORY_PREFIX:-devops-oke}"
TAG="${TAG:-1.0.0}"
CONTAINER_CLI="${CONTAINER_CLI:-docker}"
REGISTRY="${OCIR_REGION_KEY}.ocir.io"
BACKEND_IMAGE="${REGISTRY}/${TENANCY_NAMESPACE}/${REPOSITORY_PREFIX}/backend:${TAG}"
FRONTEND_IMAGE="${REGISTRY}/${TENANCY_NAMESPACE}/${REPOSITORY_PREFIX}/frontend:${TAG}"

if ! command -v "${CONTAINER_CLI}" >/dev/null 2>&1; then
  echo "Container CLI '${CONTAINER_CLI}' was not found. In OCI Cloud Shell, use docker or podman." >&2
  exit 1
fi

echo "Building backend: ${BACKEND_IMAGE}"
"${CONTAINER_CLI}" build \
  -f APP-DEMO/app/backend/Dockerfile.backend \
  -t "${BACKEND_IMAGE}" \
  APP-DEMO/app/backend

echo "Building frontend: ${FRONTEND_IMAGE}"
"${CONTAINER_CLI}" build \
  -f APP-DEMO/app/frontend/Dockerfile.front \
  -t "${FRONTEND_IMAGE}" \
  APP-DEMO/app/frontend

echo "Pushing backend"
"${CONTAINER_CLI}" push "${BACKEND_IMAGE}"

echo "Pushing frontend"
"${CONTAINER_CLI}" push "${FRONTEND_IMAGE}"

cat <<IMAGES
BACKEND_IMAGE=${BACKEND_IMAGE}
FRONTEND_IMAGE=${FRONTEND_IMAGE}
IMAGES