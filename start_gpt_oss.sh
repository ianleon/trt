#!/bin/bash

export MODEL_HANDLE="openai/gpt-oss-20b"

docker run --name trtllm_llm_server --rm -it --gpus all --ipc host --network host \
  -e HF_TOKEN=$HF_TOKEN \
  -e MODEL_HANDLE="$MODEL_HANDLE" \
  -v $HOME/.cache/huggingface/:/root/.cache/huggingface/ \
  $DOCKER_IMAGE \
  bash -c '
    export TIKTOKEN_ENCODINGS_BASE="/tmp/harmony-reqs" && \
    mkdir -p $TIKTOKEN_ENCODINGS_BASE && \
    wget -P $TIKTOKEN_ENCODINGS_BASE https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken && \
    wget -P $TIKTOKEN_ENCODINGS_BASE https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken && \
    hf download $MODEL_HANDLE && \
    cat > /tmp/extra-llm-api-config.yml <<EOF
print_iter_log: false
kv_cache_config:
  dtype: "auto"
  free_gpu_memory_fraction: 0.9
cuda_graph_config:
  enable_padding: true
disable_overlap_scheduler: true
EOF
    trtllm-serve "$MODEL_HANDLE" \
      --max_batch_size 64 \
      --trust_remote_code \
      --port 8355 \
      --extra_llm_api_options /tmp/extra-llm-api-config.yml
  '

