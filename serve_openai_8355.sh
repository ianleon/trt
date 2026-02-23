#!/usr/bin/env bash
set -euo pipefail

# Start a TensorRT-LLM OpenAI-compatible server on port 8355 by default.
# Usage:
#   ./serve_openai_8355.sh
#   MODEL=<hf_name_or_path> ./serve_openai_8355.sh
#   ./serve_openai_8355.sh <hf_name_or_path>
# Optional env:
#   DOCKER_IMAGE=<image> HF_TOKEN=<token>
#   HOST=0.0.0.0 PORT=8355 BACKEND=pytorch|tensorrt|trt|_autodeploy
#   TP_SIZE=<int> PP_SIZE=<int> EP_SIZE=<int>
#   TOKENIZER=<path_or_name>   # only needed for TensorRT engine path
#   MAX_BATCH_SIZE=64 TRUST_REMOTE_CODE=1
#   KV_CACHE_FREE_GPU_MEMORY_FRACTION=0.25
#   EXTRA_LLM_API_OPTIONS=/path/to/config.yml  # if unset, a default config is generated in-container

DEFAULT_MODEL="TinyLlama/TinyLlama-1.1B-Chat-v1.0"
MODEL="${MODEL:-${1:-${DEFAULT_MODEL}}}"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8355}"
DOCKER_IMAGE="${DOCKER_IMAGE:-nvcr.io/nvidia/tensorrt-llm/release:1.2.0rc6}"
HF_TOKEN="${HF_TOKEN:-}"
MAX_BATCH_SIZE="${MAX_BATCH_SIZE:-64}"
TRUST_REMOTE_CODE="${TRUST_REMOTE_CODE:-1}"
KV_CACHE_FREE_GPU_MEMORY_FRACTION="${KV_CACHE_FREE_GPU_MEMORY_FRACTION:-0.25}"
EXTRA_LLM_API_OPTIONS="${EXTRA_LLM_API_OPTIONS:-}"
BACKEND="${BACKEND:-}"
TP_SIZE="${TP_SIZE:-}"
PP_SIZE="${PP_SIZE:-}"
EP_SIZE="${EP_SIZE:-}"
TOKENIZER="${TOKENIZER:-}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found in PATH." >&2
  exit 1
fi

# If docker socket isn't accessible, re-exec with sudo preserving env.
if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1; then
    echo "Docker access requires elevated privileges; re-running with sudo..." >&2
    exec sudo --preserve-env=MODEL,HOST,PORT,DOCKER_IMAGE,HF_TOKEN,MAX_BATCH_SIZE,TRUST_REMOTE_CODE,KV_CACHE_FREE_GPU_MEMORY_FRACTION,EXTRA_LLM_API_OPTIONS,BACKEND,TP_SIZE,PP_SIZE,EP_SIZE,TOKENIZER,HOME \
      /usr/bin/env bash "$0"
  else
    echo "Error: docker access denied and sudo not available." >&2
    exit 1
  fi
fi

DOCKER_ENV=()
if [[ -n "${HF_TOKEN}" ]]; then DOCKER_ENV+=(-e "HF_TOKEN=${HF_TOKEN}"); fi

TMP_SCRIPT="$(mktemp)"
trap 'rm -f "${TMP_SCRIPT}"' EXIT

cat > "${TMP_SCRIPT}" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

hf download "$MODEL_HANDLE"

EXTRA_ARGS=()
if [[ -n "${BACKEND:-}" ]]; then EXTRA_ARGS+=(--backend "${BACKEND}"); fi
if [[ -n "${TP_SIZE:-}" ]]; then EXTRA_ARGS+=(--tp_size "${TP_SIZE}"); fi
if [[ -n "${PP_SIZE:-}" ]]; then EXTRA_ARGS+=(--pp_size "${PP_SIZE}"); fi
if [[ -n "${EP_SIZE:-}" ]]; then EXTRA_ARGS+=(--ep_size "${EP_SIZE}"); fi
if [[ -n "${TOKENIZER:-}" ]]; then EXTRA_ARGS+=(--tokenizer "${TOKENIZER}"); fi
if [[ -n "${MAX_BATCH_SIZE:-}" ]]; then EXTRA_ARGS+=(--max_batch_size "${MAX_BATCH_SIZE}"); fi
if [[ "${TRUST_REMOTE_CODE:-0}" == "1" ]]; then EXTRA_ARGS+=(--trust_remote_code); fi

if [[ -n "${EXTRA_LLM_API_OPTIONS:-}" ]]; then
  EXTRA_ARGS+=(--extra_llm_api_options "${EXTRA_LLM_API_OPTIONS}")
else
  cat > /tmp/extra-llm-api-config.yml <<EOF
print_iter_log: false
kv_cache_config:
  dtype: "auto"
  free_gpu_memory_fraction: ${KV_CACHE_FREE_GPU_MEMORY_FRACTION}
cuda_graph_config:
  enable_padding: true
disable_overlap_scheduler: true
EOF
  EXTRA_ARGS+=(--extra_llm_api_options /tmp/extra-llm-api-config.yml)
fi

trtllm-serve "$MODEL_HANDLE" \
  --host "$HOST" \
  --port "$PORT" \
  "${EXTRA_ARGS[@]}"
EOS

chmod +x "${TMP_SCRIPT}"

DOCKER_TTY_ARGS=()
if [[ -t 0 && -t 1 ]]; then
  DOCKER_TTY_ARGS=(-it)
fi

exec docker run --name trtllm_llm_server --rm "${DOCKER_TTY_ARGS[@]}" \
  --gpus all --ipc host --network host \
  -e "MODEL_HANDLE=${MODEL}" \
  -e "HOST=${HOST}" \
  -e "PORT=${PORT}" \
  -e "BACKEND=${BACKEND}" \
  -e "TP_SIZE=${TP_SIZE}" \
  -e "PP_SIZE=${PP_SIZE}" \
  -e "EP_SIZE=${EP_SIZE}" \
  -e "TOKENIZER=${TOKENIZER}" \
  -e "MAX_BATCH_SIZE=${MAX_BATCH_SIZE}" \
  -e "TRUST_REMOTE_CODE=${TRUST_REMOTE_CODE}" \
  -e "KV_CACHE_FREE_GPU_MEMORY_FRACTION=${KV_CACHE_FREE_GPU_MEMORY_FRACTION}" \
  -e "EXTRA_LLM_API_OPTIONS=${EXTRA_LLM_API_OPTIONS}" \
  "${DOCKER_ENV[@]}" \
  -v "${HOME}/.cache/huggingface/:/root/.cache/huggingface/" \
  -v "${TMP_SCRIPT}:/tmp/run_trtllm.sh:ro" \
  "${DOCKER_IMAGE}" \
  /tmp/run_trtllm.sh
