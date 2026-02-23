# TensorRT-LLM Serve on DGX

This repo contains scripts to launch a TensorRT-LLM OpenAI-compatible API server.

## Requirements

- Docker with GPU runtime support on the DGX host.
- Hugging Face token (`HF_TOKEN`) for downloading gated models (for example `meta-llama/*`).
  - Manual run: if `HF_TOKEN` is exported in your bash profile, `serve_openai_8355.sh` will pick it up.
  - systemd service: set `HF_TOKEN=...` in `/etc/default/trtllm-openai-8355` (systemd does not load your shell profile).

## Quick Start

Start server manually on port `8355`:

```bash
cd "$HOME/Server/trt"
./serve_openai_8355.sh
```

Set a different model:

```bash
MODEL=Qwen/Qwen2.5-7B-Instruct ./serve_openai_8355.sh
```

Start Nemotron v3 (NVFP4):

```bash
./start_nemotron_v3_8355.sh
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
- `MAX_SEQ_LEN=16384`
- `KV_CACHE_FREE_GPU_MEMORY_FRACTION=0.25` (lower this to reduce VRAM use)

3. Restart after config changes:

```bash
sudo systemctl restart trtllm-openai-8355.service
```

Or run the helper script to apply env + restart + show verification logs:

```bash
cd "$HOME/Server/trt"
./apply_service_config_8355.sh
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

## Troubleshooting

If startup fails with `KeyError: 'weight_scale'` while loading
`Qwen/Qwen3-Coder-Next-FP8`, switch to:

```bash
MODEL=Qwen/Qwen3-Coder-Next
```

Then restart:

```bash
sudo systemctl restart trtllm-openai-8355.service
```

If `trtllm-openai-8355.service` is enabled, it will auto-recreate
`trtllm_llm_server` and override manual model launches. Stop it before
starting a manual container:

```bash
sudo systemctl stop trtllm-openai-8355.service
```
