#!/usr/bin/env bash
set -euo pipefail

# Capture plain HTTP request bodies hitting port 8355.
# Requires Docker and host networking.

PORT="${PORT:-8355}"
IMAGE="${IMAGE:-nicolaka/netshoot:latest}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found in PATH." >&2
  exit 1
fi

# If docker socket isn't accessible, re-exec with sudo preserving env.
if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1; then
    echo "Docker access requires elevated privileges; re-running with sudo..." >&2
    exec sudo --preserve-env=PORT,IMAGE /usr/bin/env bash "$0"
  else
    echo "Error: docker access denied and sudo not available." >&2
    exit 1
  fi
fi

exec docker run --rm -it \
  --net host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  "$IMAGE" \
  ngrep -d any -W byline "POST /v1/chat/completions" tcp port "$PORT"
