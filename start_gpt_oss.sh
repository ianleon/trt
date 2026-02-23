#!/usr/bin/env bash
set -euo pipefail

# Launch OpenAI gpt-oss-20b on port 8355 via the shared TRT-LLM wrapper.

export MODEL="${MODEL:-openai/gpt-oss-20b}"
export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-8355}"
export TRUST_REMOTE_CODE="${TRUST_REMOTE_CODE:-1}"
export MAX_BATCH_SIZE="${MAX_BATCH_SIZE:-64}"
export KV_CACHE_FREE_GPU_MEMORY_FRACTION="${KV_CACHE_FREE_GPU_MEMORY_FRACTION:-0.9}"

exec "$(dirname "$0")/serve_openai_8355.sh"
