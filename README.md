# TensorRT-LLM Serve on DGX

Scripts in this repo run a TensorRT-LLM OpenAI-compatible server on port `8355`.

Current default service model:
- `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4` (via `_autodeploy`)

## Requirements

- Docker with GPU runtime support on the DGX host.
- Hugging Face token (`HF_TOKEN`) for gated models.
  - Manual run: if `HF_TOKEN` is exported in your bash profile, `serve_openai_8355.sh` will pick it up.
  - systemd service: set `HF_TOKEN=...` in `/etc/default/trtllm-openai-8355` (systemd does not load your shell profile).

## Manual Launch

Generic launcher:

```bash
cd "$HOME/Server/trt"
./serve_openai_8355.sh
```

Nemotron v3 preset:

```bash
./start_nemotron_v3_8355.sh
```

GPT-OSS preset:

```bash
./start_gpt_oss.sh
```

Override model directly:

```bash
MODEL=Qwen/Qwen2.5-7B-Instruct ./serve_openai_8355.sh
```

Quick status check:

```bash
./status_8355.sh
```

## systemd Service (Boot + Restart)

Install and start once:

```bash
cd "$HOME/Server/trt"
sudo ./install_trtllm_service.sh
```

Apply repo env template and restart service:

```bash
cd "$HOME/Server/trt"
./apply_service_config_8355.sh
```

Edit runtime config directly:

```bash
sudo nano /etc/default/trtllm-openai-8355
```

Common knobs:
- `MODEL=...`
- `BACKEND=...`
- `PORT=8355`
- `HF_TOKEN=...` (if needed)
- `MAX_BATCH_SIZE=...`
- `MAX_INPUT_LEN=...`
- `MAX_SEQ_LEN=...`
- `KV_CACHE_FREE_GPU_MEMORY_FRACTION=...`
- `EXTRA_SERVE_ARGS=...`

Restart and inspect:
```bash
sudo systemctl restart trtllm-openai-8355.service
systemctl status trtllm-openai-8355.service
journalctl -u trtllm-openai-8355.service -f
```

## Files

- `serve_openai_8355.sh`: main launcher wrapper
- `start_nemotron_v3_8355.sh`: Nemotron v3 preset
- `start_gpt_oss.sh`: GPT-OSS preset
- `status_8355.sh`: API/container/service status probe
- `systemd/trtllm-openai-8355.service`: service unit template
- `systemd/trtllm-openai-8355.env`: service env template

## Troubleshooting

Manual and systemd mode conflict if both are active because both use container name `trtllm_llm_server`.

```bash
sudo systemctl stop trtllm-openai-8355.service
```

`Qwen/Qwen3-Coder-Next-FP8` currently fails on TRT-LLM 1.2.0rc6 with:
- `KeyError: 'weight_scale'`

If you must run Qwen3 Coder Next on this stack, use:
```bash
MODEL=Qwen/Qwen3-Coder-Next ./serve_openai_8355.sh
```
