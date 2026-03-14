#!/usr/bin/env bash
set -euo pipefail

SERVICE="${SERVICE:-trtllm-openai-8355.service}"
CONTAINER="${CONTAINER:-trtllm_llm_server}"

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    SUDO="sudo"
  else
    SUDO=""
  fi
fi

if [[ -n "${SUDO}" ]]; then
  echo "Stopping ${SERVICE}"
  ${SUDO} systemctl stop "${SERVICE}" || true
else
  echo "Skipping systemd stop for ${SERVICE} because passwordless sudo is unavailable"
fi

if docker ps -a --format '{{.Names}}' | {
  if command -v rg >/dev/null 2>&1; then
    rg -x "${CONTAINER}"
  else
    grep -Fx "${CONTAINER}"
  fi
} >/dev/null; then
  echo
  echo "Stopping Docker container ${CONTAINER}"
  docker stop -t 30 "${CONTAINER}" >/dev/null 2>&1 || true
  docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true
fi

echo
echo "systemd state:"
${SUDO} systemctl is-active "${SERVICE}" 2>/dev/null || true

echo
echo "Docker container state:"
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' | {
  head -n 1
  if command -v rg >/dev/null 2>&1; then
    rg "^${CONTAINER}\\b" || true
  else
    grep -E "^${CONTAINER}[[:space:]]" || true
  fi
}
