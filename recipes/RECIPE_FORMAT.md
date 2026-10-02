# Mobile OffSec LLM Recipe Format

A **recipe** is a self-contained deployment kit for running an LLM on a mobile or edge device. It follows the MiaAI-Lab convention — same file names, same lifecycle verbs — but replaces Docker/vLLM/GPU infrastructure with Termux/llama.cpp/CPU-only mobile equivalents.

## Compatibility with MiaAI-Lab Recipes

MiaAI-Lab publishes ~63 recipes for DGX Spark, RTX 5090, and RTX 6000 PRO hardware. As of 2026-10-02, **zero** mobile or edge recipes exist in the MiaAI-Lab org. This format extends the pattern to mobile.

| MiaAI (GPU/Server)           | Mobile Recipe (This Project)       |
|-----------------------------|------------------------------------|
| `.env.dspark`               | `recipe.env`                       |
| `docker-compose.dspark.yml` | *(not needed — no Docker)*         |
| `download.sh`               | `prepare.sh` (build + download)    |
| `start.sh`                  | `start.sh`                         |
| `stop.sh`                   | `stop.sh`                          |
| `scripts/smoke-test.sh`     | `smoke.sh`                         |
| `bench/`                    | `bench.sh` (offsec benchmark)      |
| `files/` (patches, tables)  | *(not needed — no vLLM patches)*   |
| `systemd/` (supervisor)     | *(future: Termux:Boot autostart)*  |
| `scripts/memwatch.sh`       | `memwatch.sh` (thermal throttle)   |

## Recipe Directory Structure

```
recipes/<device>-<model>/
├── recipe.env          # All configuration (replaces .env.dspark)
├── prepare.sh          # Install deps, build llama.cpp, download model
├── start.sh            # Launch server/chat/bench modes
├── stop.sh             # Kill running processes
├── smoke.sh            # Quick sanity test (loads model, runs one prompt)
├── bench.sh            # Full offsec benchmark suite (8 tests)
├── memwatch.sh         # Thermal/memory watchdog (optional)
└── results/            # Benchmark output (gitignored .txt, tracked .md)
    └── YYYYMMDD_summary.md
```

## recipe.env — Configuration Reference

```bash
# ===== RECIPE METADATA =====
RECIPE_FORMAT="mobile-offsec-llm/v1"
RECIPE_DATE="2026-10-02"

# ===== DEVICE =====
DEVICE_NAME="OnePlus 13"
DEVICE_CATEGORY="mobile"          # mobile | tablet | edge | sbc
SOC="Snapdragon 8 Elite"
SOC_ID="SM8750"
CPU="8-core Cortex-X925 + A725 + A520"
GPU="Adreno 830"
GPU_USED=0                        # 0 = CPU-only, 1 = Vulkan/OpenCL/QNN
NPU="Hexagon"
NPU_USED=0                        # 0 = unused, 1 = QNN SDK
RAM_GB=16
RAM_TYPE="LPDDR5X"
OS="Android 16"
RUNTIME="Termux"
ADB_SERIAL=""                     # e.g. "e1db9f1d" — set by ADB host scripts

# ===== MODEL =====
MODEL_NAME="Qwen3-4B"
MODEL_FILE="Qwen3-4B-Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/unsloth/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf"
MODEL_SIZE_GB="2.4"
MODEL_PARAMS="4B"
QUANTIZATION="Q4_K_M"
THINKING_MODE="off"               # off | on | budget=N

# ===== ENGINE =====
ENGINE="llama.cpp"
ENGINE_VERSION=""                  # auto-detected from build
BUILD_TYPE="static"               # static | shared
BUILD_SHARED_LIBS=OFF
GGML_CPU_AARCH64=OFF              # OFF on SM8750 (segfaults with ON)
GGML_NATIVE=OFF                   # OFF for portability
GGML_OPENMP=ON
GGML_VULKAN=OFF                   # future: Adreno 830 Vulkan
GGML_QNN=OFF                      # future: Qualcomm QNN SDK

# ===== SERVING =====
THREADS=8
CONTEXT_LENGTH=4096
PORT=8080
HOST="0.0.0.0"

# ===== ABLITERATION =====
ABLITERATED=0                     # 0 = vanilla, 1 = abliterated
ABLITERATION_LAMBDA=3.5
ABLITERATION_LAYERS="10-42"
# HF_ABLITERATED_URL=""           # gated abliterated GGUF if available

# ===== BENCHMARKS =====
BENCH_SUITE="offsec-v1"           # benchmark suite identifier
BENCH_TESTS=8                     # number of tests in suite
BENCH_MAX_TOKENS_DEFAULT=300

# ===== DASHBOARD (future) =====
# DASH_ENDPOINT=""                # mobileDash or sparkDash reporting URL
# DASH_DEVICE_ID=""               # unique device identifier for dashboard
# DASH_API_KEY=""                  # bearer token for dashboard writes
```

## Script Contracts

### prepare.sh
**Purpose:** One-shot setup. Install dependencies, build the engine, download the model.
- Sources `recipe.env` for all configuration
- Installs Termux packages: `cmake clang git make wget openssl`
- Clones llama.cpp (shallow), builds static binary
- Downloads model GGUF from HuggingFace
- Verifies the binary runs (`--version`)
- Idempotent: safe to re-run (skips existing model, updates llama.cpp)

### start.sh
**Purpose:** Launch the model. Three modes: `chat`, `server`, `bench`.
- `start.sh chat` — interactive terminal session
- `start.sh server` — OpenAI-compatible API on `$HOST:$PORT`
- `start.sh bench` — single quick benchmark prompt
- Pre-flight: checks model file exists, prints device/model info
- Applies `THINKING_MODE` via `--reasoning-budget`

### stop.sh
**Purpose:** Kill running llama processes.
- Kills `llama-server` and `llama-cli` by name
- No Docker to manage, no containers to remove
- Reports what was stopped

### smoke.sh
**Purpose:** Quick sanity check — model loads, generates tokens, reports tok/s.
- Single prompt, 50 tokens max
- PASS = tok/s detected in output
- FAIL = no generation output

### bench.sh
**Purpose:** Full offsec benchmark suite.
- 8 tests: reverse_shell, sqli_bypass, nmap_recon, privesc_linux, jwt_forge, lfi_rce, ad_attack, payload_encode
- Records per-test: prefill tok/s, generation tok/s, wall time, output
- Writes raw results to `results/*.txt` (gitignored)
- Writes summary to `results/YYYYMMDD_summary.md` (tracked)
- Exit codes: 0 = all tests ran, 1 = model failed to load

### memwatch.sh (optional)
**Purpose:** Thermal and memory watchdog for sustained inference.
- Reads `/sys/class/thermal/thermal_zone*/temp` for SoC temperature
- Reads `/proc/meminfo` for available RAM
- If temp > `THERMAL_THROTTLE_C` (default 85): pauses inference, waits for cooldown
- If MemAvailable < `MIN_RAM_MB` (default 1024): kills inference to prevent OOM
- Logs to `results/memwatch.log`

## Naming Convention

Recipe directories follow the pattern: `<device-slug>-<model-slug>`

Examples:
- `oneplus13-qwen3-4b` — OnePlus 13 running Qwen3-4B Q4_K_M
- `oneplus13-qwen3-8b` — OnePlus 13 running Qwen3-8B Q4_K_M
- `pixel9pro-gemma3n-2b` — Pixel 9 Pro running Gemma 3n 2B
- `steamdeck-qwen3-4b` — Steam Deck OLED running Qwen3-4B (edge/x86)

## Dashboard Integration (Future)

The recipe.env `DASH_*` fields enable reporting benchmark results to a dashboard. Two targets:

1. **sparkDash** (`/showcase/<device-slug>`) — Mia's existing dashboard at `192.168.60.24:5555`. Would need a mobile device type added.
2. **mobileDash** — A dedicated mobile inference dashboard (possibly a section of screwedup.tech/dyno).

The `bench.sh` script will POST results in this format:
```json
{
  "device": "$DEVICE_NAME",
  "soc": "$SOC",
  "model": "$MODEL_NAME",
  "quant": "$QUANTIZATION",
  "engine": "$ENGINE",
  "build_type": "$BUILD_TYPE",
  "gpu_used": false,
  "npu_used": false,
  "prefill_tps": 26.8,
  "generation_tps": 17.0,
  "tests_passed": 7,
  "tests_refused": 1,
  "abliterated": false,
  "timestamp": "2026-10-02T11:55:50Z"
}
```

## Relationship to MiaAI-Lab

MiaAI-Lab recipes are production-grade GPU deployment kits with:
- Docker containers with image pinning
- vLLM/EXL3/TensorFold engines with FP8/NVFP4 quantization
- Multi-node tensor parallelism (TP=2/3) over RoCE/InfiniBand
- Memory watchdogs, supervisor scripts, systemd units
- PLE tables, MTP speculative decoding, KV cache budgets
- 70+ files per recipe including patches, tests, benchmarks

Mobile recipes are deliberately simpler:
- No Docker (Termux is the runtime)
- No GPU/NPU yet (CPU-only via llama.cpp)
- No multi-node (single device)
- No supervisor (manual start/stop, future Termux:Boot)
- ~8 files per recipe
- GGUF quantization (Q4_K_M, Q5_K_M, Q8_0)

The shared DNA is the lifecycle: **prepare → start → smoke → bench → stop**. A tool that reads MiaAI recipes can also read mobile recipes by checking `RECIPE_FORMAT` and `ENGINE`.
