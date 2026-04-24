#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJ_DIR="${ROOT_DIR}/rtl/vendor/aib-protocols"
GEN="${PROJ_DIR}/llink/script/llink_gen.py"

CFG_D32="${ROOT_DIR}/util/axi_mm_a32_d32.cfg"
CFG_D64="${ROOT_DIR}/util/axi_mm_a32_d64.cfg"

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [output_base_dir]"
  echo "Example: $0 ${ROOT_DIR}/build/generated_axi_mm/custom_run"
  exit 1
fi

if [[ $# -eq 1 ]]; then
  OUT_BASE="$1"
else
  TS="$(date +%Y%m%d_%H%M%S)"
  OUT_BASE="${ROOT_DIR}/build/generated_axi_mm/${TS}"
fi

OUT_D32="${OUT_BASE}/d32"
OUT_D64="${OUT_BASE}/d64"

mkdir -p "${OUT_D32}" "${OUT_D64}"

echo "Generating AXI-MM D32 bridge into: ${OUT_D32}"
python3 "${GEN}" --cfg "${CFG_D32}" --odir "${OUT_D32}"

echo "Generating AXI-MM D64 bridge into: ${OUT_D64}"
python3 "${GEN}" --cfg "${CFG_D64}" --odir "${OUT_D64}"

echo
echo "Done. Generated bridges at:"
echo "  ${OUT_D32}"
echo "  ${OUT_D64}"