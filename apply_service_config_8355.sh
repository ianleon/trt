#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_SRC="${ROOT_DIR}/systemd/trtllm-openai-8355.env"
ENV_DST="/etc/default/trtllm-openai-8355"
SERVICE="trtllm-openai-8355.service"
UNIT_DST="/etc/systemd/system/${SERVICE}"

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
${SUDO} awk -F= '/^(HOST|PORT|DOCKER_IMAGE|MAX_INPUT_LEN|MAX_SEQ_LEN|MAX_BATCH_SIZE|KV_CACHE_FREE_GPU_MEMORY_FRACTION|HF_TOKEN)=/ {print}' "${ENV_DST}"

echo
echo "Installed service ExecStart:"
EXEC_START="$(${SUDO} awk -F= '/^ExecStart=/{print $2}' "${UNIT_DST}" 2>/dev/null || true)"
echo "${EXEC_START:-<missing>}"
if [[ "${EXEC_START}" != *"serve_nemotron_8355.sh"* ]]; then
  echo
  echo "WARNING: Service unit is not pointing to serve_nemotron_8355.sh."
  echo "Run: sudo ./install_trtllm_service.sh"
fi

echo
echo "Startup log highlights since restart (${RESTART_TS}):"
if command -v rg >/dev/null 2>&1; then
  ${SUDO} journalctl -u "${SERVICE}" --since "${RESTART_TS}" --no-pager \
    | rg -i "model=|max_seq_len|max_input_len|inferred value|started server|error" || true
else
  ${SUDO} journalctl -u "${SERVICE}" --since "${RESTART_TS}" --no-pager \
    | grep -Ei "model=|max_seq_len|max_input_len|inferred value|started server|error" || true
fi
