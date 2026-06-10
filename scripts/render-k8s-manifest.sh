#!/usr/bin/env bash
set -euo pipefail

: "${OCI_REGION:?Set OCI_REGION, for example us-chicago-1}"
: "${WORKSHOP_COMPARTMENT_OCID:?Set WORKSHOP_COMPARTMENT_OCID}"
: "${BACKEND_IMAGE:?Set BACKEND_IMAGE}"
: "${FRONTEND_IMAGE:?Set FRONTEND_IMAGE}"

PYTHON_BIN="${PYTHON_BIN:-python3}"
OCI_GENAI_MODEL_ID="${OCI_GENAI_MODEL_ID:-meta.llama-4-maverick-17b-128e-instruct-fp8}"
TEMPLATE_PATH="${TEMPLATE_PATH:-APP-DEMO/k8s/aplicaciones-demo.template.yaml}"
OUTPUT_PATH="${OUTPUT_PATH:-APP-DEMO/k8s/aplicaciones-demo.rendered.yaml}"

"${PYTHON_BIN}" - "$TEMPLATE_PATH" "$OUTPUT_PATH" <<'PY'
import os
import sys
from pathlib import Path

template_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])
content = template_path.read_text(encoding="utf-8")
replacements = {
    "__OCI_REGION__": os.environ["OCI_REGION"],
    "__OCI_COMPARTMENT_ID__": os.environ["WORKSHOP_COMPARTMENT_OCID"],
    "__OCI_GENAI_MODEL_ID__": os.environ.get("OCI_GENAI_MODEL_ID", "meta.llama-4-maverick-17b-128e-instruct-fp8"),
    "__BACKEND_IMAGE__": os.environ["BACKEND_IMAGE"],
    "__FRONTEND_IMAGE__": os.environ["FRONTEND_IMAGE"],
}
for token, value in replacements.items():
    content = content.replace(token, value)
output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text(content, encoding="utf-8")
PY

echo "Rendered ${OUTPUT_PATH}"