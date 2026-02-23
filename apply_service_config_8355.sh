#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_SRC="${ROOT_DIR}/systemd/trtllm-openai-8355.env"
ENV_DST="/etc/default/trtllm-openai-8355"
SERVICE="trtllm-openai-8355.service"

if [[ ! -f "${ENV_SRC}" ]]; then
  echo "Error: missing env template: ${ENV_SRC}" >&2
  exit 1
fi

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo is required to update ${ENV_DST} and restart ${SERVICE}." >&2
    exit 1
  fi
  SUDO="sudo"
fi

echo "Applying ${ENV_SRC} -> ${ENV_DST}"
${SUDO} cp "${ENV_SRC}" "${ENV_DST}"

RESTART_TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "Restarting ${SERVICE}"
${SUDO} systemctl restart "${SERVICE}"

echo
echo "Effective service env settings:"
${SUDO} awk -F= '/^(MODEL|BACKEND|PORT|MAX_INPUT_LEN|MAX_SEQ_LEN|MAX_BATCH_SIZE|KV_CACHE_FREE_GPU_MEMORY_FRACTION|EXTRA_SERVE_ARGS|HF_TOKEN)=/ {print}' "${ENV_DST}"

echo
echo "Startup log highlights since restart (${RESTART_TS}):"
if command -v rg >/dev/null 2>&1; then
  ${SUDO} journalctl -u "${SERVICE}" --since "${RESTART_TS}" --no-pager \
    | rg -i "model=|max_seq_len|max_input_len|inferred value|started server|error" || true
else
  ${SUDO} journalctl -u "${SERVICE}" --since "${RESTART_TS}" --no-pager \
    | grep -Ei "model=|max_seq_len|max_input_len|inferred value|started server|error" || true
fi
