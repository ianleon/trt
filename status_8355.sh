#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8355}"
SERVICE="${SERVICE:-trtllm-openai-8355.service}"

echo "== API probe =="
if curl -sS -m 3 "http://127.0.0.1:${PORT}/v1/models"; then
  echo
else
  echo "API not reachable on 127.0.0.1:${PORT}"
fi

echo
echo "== Docker containers =="
if command -v rg >/dev/null 2>&1; then
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' \
    | { head -n 1; rg 'trtllm_llm_server|open-webui' || true; }
else
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' \
    | { head -n 1; grep -E 'trtllm_llm_server|open-webui' || true; }
fi

if command -v systemctl >/dev/null 2>&1; then
  echo
  echo "== systemd (${SERVICE}) =="
  systemctl is-enabled "${SERVICE}" 2>/dev/null || true
  systemctl is-active "${SERVICE}" 2>/dev/null || true
fi
