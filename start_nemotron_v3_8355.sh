#!/usr/bin/env bash
set -euo pipefail

# Launch Nemotron Nano v3 NVFP4 via TRT-LLM OpenAI API on port 8355.
# This wraps serve_openai_8355.sh and sets model/backend-specific defaults.

export MODEL="${MODEL:-nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4}"
export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-8355}"
export BACKEND="${BACKEND:-_autodeploy}"
export MAX_BATCH_SIZE="${MAX_BATCH_SIZE:-8}"
export MAX_INPUT_LEN="${MAX_INPUT_LEN:-32768}"
export KV_CACHE_FREE_GPU_MEMORY_FRACTION="${KV_CACHE_FREE_GPU_MEMORY_FRACTION:-0.18}"
export TRUST_REMOTE_CODE="${TRUST_REMOTE_CODE:-1}"
export EXTRA_SERVE_ARGS="${EXTRA_SERVE_ARGS:---reasoning_parser nano-v3}"

exec "$(dirname "$0")/serve_openai_8355.sh"
