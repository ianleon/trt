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

INSTALL_USER="${SUDO_USER:-${USER}}"
if [[ -n "${SUDO_USER:-}" ]]; then
  USER_HOME="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
else
  USER_HOME="${HOME}"
fi

if [[ -z "${USER_HOME}" || ! -d "${USER_HOME}" ]]; then
  echo "Error: could not resolve home directory for ${INSTALL_USER}." >&2
  exit 1
fi

WORKDIR="${USER_HOME}/Server/trt"
if [[ ! -d "${WORKDIR}" ]]; then
  echo "Error: expected working directory not found: ${WORKDIR}" >&2
  exit 1
fi

TMP_UNIT="$(mktemp)"
trap 'rm -f "${TMP_UNIT}"' EXIT

sed "s|__TRTLLM_WORKDIR__|${WORKDIR}|g" "${UNIT_SRC}" > "${TMP_UNIT}"
install -m 0644 "${TMP_UNIT}" "${UNIT_DST}"

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
