#!/usr/bin/env bash
set -euo pipefail

# Serve NVIDIA Nemotron Nano v3 NVFP4 on OpenAI-compatible API port 8355.

MODEL_HANDLE="nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8355}"
DOCKER_IMAGE="${DOCKER_IMAGE:-nvcr.io/nvidia/tensorrt-llm/release:1.3.0rc4}"
HF_TOKEN="${HF_TOKEN:-${HUGGING_FACE_HUB_TOKEN:-}}"
MAX_BATCH_SIZE="${MAX_BATCH_SIZE:-8}"
MAX_INPUT_LEN="${MAX_INPUT_LEN:-32768}"
MAX_SEQ_LEN="${MAX_SEQ_LEN:-32768}"
KV_CACHE_FREE_GPU_MEMORY_FRACTION="${KV_CACHE_FREE_GPU_MEMORY_FRACTION:-0.18}"

is_positive_int() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

is_fraction_0_1() {
  [[ "$1" =~ ^0(\.[0-9]+)?$|^1(\.0+)?$ ]]
}

if ! is_positive_int "${MAX_BATCH_SIZE}"; then
  echo "Error: MAX_BATCH_SIZE must be a positive integer, got '${MAX_BATCH_SIZE}'." >&2
  exit 1
fi

if ! is_positive_int "${MAX_INPUT_LEN}"; then
  echo "Error: MAX_INPUT_LEN must be a positive integer, got '${MAX_INPUT_LEN}'." >&2
  exit 1
fi

if ! is_positive_int "${MAX_SEQ_LEN}"; then
  echo "Error: MAX_SEQ_LEN must be a positive integer, got '${MAX_SEQ_LEN}'." >&2
  exit 1
fi

if ! is_fraction_0_1 "${KV_CACHE_FREE_GPU_MEMORY_FRACTION}"; then
  echo "Error: KV_CACHE_FREE_GPU_MEMORY_FRACTION must be between 0.0 and 1.0, got '${KV_CACHE_FREE_GPU_MEMORY_FRACTION}'." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found in PATH." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1; then
    echo "Docker access requires elevated privileges; re-running with sudo..." >&2
    exec sudo --preserve-env=HOST,PORT,DOCKER_IMAGE,HF_TOKEN,HUGGING_FACE_HUB_TOKEN,MAX_BATCH_SIZE,MAX_INPUT_LEN,MAX_SEQ_LEN,KV_CACHE_FREE_GPU_MEMORY_FRACTION,HOME \
      /usr/bin/env bash "$0"
  else
    echo "Error: docker access denied and sudo not available." >&2
    exit 1
  fi
fi

docker rm -f trtllm_llm_server >/dev/null 2>&1 || true

TMP_SCRIPT="$(mktemp)"
trap 'rm -f "${TMP_SCRIPT}"' EXIT

cat > "${TMP_SCRIPT}" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

hf download "$MODEL_HANDLE"

cat > /tmp/extra-llm-api-config.yml <<EOF
print_iter_log: false
max_input_len: ${MAX_INPUT_LEN}
kv_cache_config:
  dtype: "auto"
  free_gpu_memory_fraction: ${KV_CACHE_FREE_GPU_MEMORY_FRACTION}
cuda_graph_config:
  enable_padding: true
disable_overlap_scheduler: true
EOF

trtllm-serve serve "$MODEL_HANDLE" \
  --host "$HOST" \
  --port "$PORT" \
  --backend _autodeploy \
  --max_batch_size "$MAX_BATCH_SIZE" \
  --max_seq_len "$MAX_SEQ_LEN" \
  --trust_remote_code \
  --reasoning_parser nano-v3 \
  --extra_llm_api_options /tmp/extra-llm-api-config.yml
EOS

chmod +x "${TMP_SCRIPT}"

DOCKER_ENV=()
if [[ -n "${HF_TOKEN}" ]]; then
  DOCKER_ENV+=(-e "HF_TOKEN=${HF_TOKEN}")
fi

DOCKER_TTY_ARGS=()
if [[ -t 0 && -t 1 ]]; then
  DOCKER_TTY_ARGS=(-it)
fi

exec docker run --name trtllm_llm_server --rm "${DOCKER_TTY_ARGS[@]}" \
  --gpus all --ipc host --network host \
  -e "MODEL_HANDLE=${MODEL_HANDLE}" \
  -e "HOST=${HOST}" \
  -e "PORT=${PORT}" \
  -e "MAX_BATCH_SIZE=${MAX_BATCH_SIZE}" \
  -e "MAX_INPUT_LEN=${MAX_INPUT_LEN}" \
  -e "MAX_SEQ_LEN=${MAX_SEQ_LEN}" \
  -e "KV_CACHE_FREE_GPU_MEMORY_FRACTION=${KV_CACHE_FREE_GPU_MEMORY_FRACTION}" \
  "${DOCKER_ENV[@]}" \
  -v "${HOME}/.cache/huggingface/:/root/.cache/huggingface/" \
  -v "${TMP_SCRIPT}:/tmp/run_trtllm.sh:ro" \
  "${DOCKER_IMAGE}" \
  /tmp/run_trtllm.sh
