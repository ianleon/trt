# TensorRT-LLM Serve on DGX

This repo contains scripts to launch a TensorRT-LLM OpenAI-compatible API server.

## Quick Start

Start server manually on port `8355`:

```bash
cd "$HOME/Server/trt"
./serve_openai_8355.sh
```

Set a different model:

```bash
MODEL=meta-llama/Llama-3.1-8B-Instruct ./serve_openai_8355.sh
```

Lower VRAM reservation (useful for smaller models):

```bash
KV_CACHE_FREE_GPU_MEMORY_FRACTION=0.20 MAX_BATCH_SIZE=8 ./serve_openai_8355.sh
```

## Run As a Boot Service (systemd)

This project includes a `systemd` service that starts at boot, runs in the background, and auto-restarts on failure.

1. Install and start the service:

```bash
cd "$HOME/Server/trt"
sudo ./install_trtllm_service.sh
```

2. Edit runtime configuration:

```bash
sudo nano /etc/default/trtllm-openai-8355
```

Common settings:
- `MODEL=...`
- `PORT=8355`
- `DOCKER_IMAGE=...`
- `HF_TOKEN=...` (if needed)
- `KV_CACHE_FREE_GPU_MEMORY_FRACTION=0.25` (lower this to reduce VRAM use)

3. Restart after config changes:

```bash
sudo systemctl restart trtllm-openai-8355.service
```

4. Verify service health:

```bash
systemctl status trtllm-openai-8355.service
journalctl -u trtllm-openai-8355.service -f
```

### Service Files

- Unit file template: `systemd/trtllm-openai-8355.service`
- Env template: `systemd/trtllm-openai-8355.env`
- Installer: `install_trtllm_service.sh`
