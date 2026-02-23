# Batch Size Tuning Plan (Saved for Later)

Goal: choose `MAX_BATCH_SIZE` and `KV_CACHE_FREE_GPU_MEMORY_FRACTION` for the best throughput without violating latency/stability targets.

## Why this is needed

`trtllm-serve` can pre-allocate KV cache, so high VRAM usage alone is not enough to judge efficiency. Tune based on service behavior and GPU utilization.

## Metrics to collect per test run

- End-to-end latency: `p50`, `p95`, `p99`
- Throughput: `tokens/sec` and/or `req/sec`
- Stability: OOM errors, server restarts, failed requests
- GPU signals: utilization (%), memory bandwidth, and memory allocated

## Sweep method

1. Pick a fixed model, prompt length, output length, and request concurrency.
2. Sweep `MAX_BATCH_SIZE` (example: `1, 2, 4, 8, 16, 32`).
3. For each batch size, try one or more `KV_CACHE_FREE_GPU_MEMORY_FRACTION` values (example: `0.10, 0.20, 0.30`).
4. Run each point long enough to stabilize (for example 3-5 minutes).
5. Record results in a table and rank by SLO compliance first, throughput second.

## Selection rule

- Keep only configurations with no OOM/restarts and acceptable error rate.
- From remaining configs, keep only those meeting latency targets.
- Choose the one with highest throughput.
- Keep one conservative fallback profile for production safety.

## Future implementation idea

Add a repo script (example: `scripts/tune_batch_size.sh`) that:

- Restarts server with each parameter set
- Runs a repeatable load test scenario
- Captures metrics into CSV/JSON
- Prints a recommended config for `/etc/default/trtllm-openai-8355`

