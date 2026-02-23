#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_SRC="${ROOT_DIR}/systemd/trtllm-openai-8355.service"
ENV_SRC="${ROOT_DIR}/systemd/trtllm-openai-8355.env"
UNIT_DST="/etc/systemd/system/trtllm-openai-8355.service"
ENV_DST="/etc/default/trtllm-openai-8355"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo $0" >&2
  exit 1
fi

install -m 0644 "${UNIT_SRC}" "${UNIT_DST}"

if [[ -f "${ENV_DST}" ]]; then
  echo "Keeping existing ${ENV_DST}"
else
  install -m 0644 "${ENV_SRC}" "${ENV_DST}"
fi

systemctl daemon-reload
systemctl enable --now trtllm-openai-8355.service

echo "Service installed and started."
echo "Check status: systemctl status trtllm-openai-8355.service"
echo "Logs: journalctl -u trtllm-openai-8355.service -f"
