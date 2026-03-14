# Nemotron Serve on DGX

This repo is intentionally focused on one job:
serve `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4` with TensorRT-LLM on port `8355`.

## Files You Actually Use

- `serve_nemotron_8355.sh`: run Nemotron manually
- `systemd/trtllm-openai-8355.env`: service runtime settings
- `systemd/trtllm-openai-8355.service`: systemd unit template
- `install_trtllm_service.sh`: install/enable service
- `apply_service_config_8355.sh`: copy env file + restart service
- `stop_8355.sh`: stop the systemd service
- `status_8355.sh`: quick health check

## Manual Run

```bash
cd "$HOME/Server/trt"
./serve_nemotron_8355.sh
```

## systemd Run (recommended)

Install once:

```bash
cd "$HOME/Server/trt"
sudo ./install_trtllm_service.sh
```

Apply updated config and restart:

```bash
cd "$HOME/Server/trt"
./apply_service_config_8355.sh
```

Stop the service:

```bash
cd "$HOME/Server/trt"
./stop_8355.sh
```

## Configure Runtime

Edit:

```bash
sudo nano /etc/default/trtllm-openai-8355
```

Key settings:
- `HF_TOKEN=...` (if model access requires it)
- `MAX_BATCH_SIZE=...`
- `MAX_INPUT_LEN=...`
- `MAX_SEQ_LEN=...`
- `KV_CACHE_FREE_GPU_MEMORY_FRACTION=...`

## Verify

```bash
./status_8355.sh
curl http://127.0.0.1:8355/v1/models
```

## Notes

- Manual and systemd runs use the same container name (`trtllm_llm_server`).
- Stop service before manual run:

```bash
./stop_8355.sh
```
