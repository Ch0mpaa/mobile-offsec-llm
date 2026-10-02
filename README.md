# Mobile OffSec LLM - Local AI for Penetration Testing on Phones

Run offensive security LLMs **locally on your phone** - no cloud, no API keys, no internet required. Built for pentesters who need AI in the field.

## First Results

| Device | SoC | Model | Quantization | Speed | RAM Used |
|--------|-----|-------|-------------|-------|---------|
| OnePlus 13 | Snapdragon 8 Elite (SM8750) | Qwen3-4B | Q4_K_M | **14.3 tok/s** | ~3 GB |

> CPU-only. GPU (Adreno 830) and NPU (Hexagon) backends coming.

## What This Is

A recipe system for deploying abliterated, offensive-security-focused LLMs on mobile hardware via Termux. Inspired by [MiaAI-Lab's DGX Spark recipes](https://github.com/MiaAI-Lab) but for phones and portable devices.

**The idea:** A pentester walks into a client engagement with a phone running an uncensored exploit-generation model locally. No cloud dependency. Works air-gapped.

## Quick Start (OnePlus 13 / Snapdragon 8 Elite)

### Prerequisites
- [Termux](https://f-droid.org/en/packages/com.termux/) installed (F-Droid version)
- USB debugging enabled
- ADB access from your workstation

### Build

```bash
# In Termux on the phone:
pkg install cmake clang git make wget

git clone --depth 1 https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
mkdir build && cd build

# MUST use static build - Android linker ignores LD_LIBRARY_PATH
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_OPENMP=ON \
    -DGGML_CPU_AARCH64=OFF \
    -DGGML_NATIVE=OFF \
    -DBUILD_SHARED_LIBS=OFF

make -j$(nproc) llama-cli llama-server
```

### Download Model

```bash
mkdir -p ~/models && cd ~/models

# Qwen3-4B (2.4 GB) - good starting point
wget https://huggingface.co/unsloth/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf
```

### Run

```bash
cd ~/llama.cpp/build

# Interactive chat
./bin/llama-cli -m ~/models/Qwen3-4B-Q4_K_M.gguf -t 8

# API server (OpenAI-compatible)
./bin/llama-server -m ~/models/Qwen3-4B-Q4_K_M.gguf -t 8 --host 0.0.0.0 --port 8080
```

## Build Notes

### Android Linker Gotcha
Android's `/system/bin/linker64` **ignores `LD_LIBRARY_PATH`** for security. Default llama.cpp cmake builds produce tiny wrapper executables that load shared libraries at runtime - these will segfault on Android. Always build with `-DBUILD_SHARED_LIBS=OFF`.

### CPU Optimization Flags
`GGML_CPU_AARCH64=ON` and `GGML_NATIVE=ON` can cause segfaults on some Android devices. Start with both OFF, then test ON individually for better performance.

## Roadmap

- [ ] Vulkan backend (Adreno 830 GPU acceleration)
- [ ] Qualcomm QNN/HTP backend (Hexagon NPU - potential 220 tok/s)
- [ ] Runtime abliteration on mobile (direction projection, 18 KiB vector)
- [ ] Larger models: Gemma-4-26B-A4B Q2 quantization (~5-6 GB)
- [ ] Automated recipe scripts (prepare/start/stop/benchmark)
- [ ] Cross-device recipes (Samsung S25 Ultra, Pixel 9 Pro)
- [ ] Benchmark suite for offensive security tasks

## Tested Devices

| Device | SoC | RAM | Status | Notes |
|--------|-----|-----|--------|-------|
| OnePlus 13 | Snapdragon 8 Elite | 16 GB | Working | 14.3 tok/s CPU |

## Related Projects

- [MiaAI-Lab DGX Spark Recipes](https://github.com/MiaAI-Lab) - NVIDIA DGX Spark deployment recipes (inspiration)
- [llama.cpp](https://github.com/ggml-org/llama.cpp) - Inference engine
- [Screwed Up Tech](https://screwedup.tech) - Cybersecurity education + AI research collective

## License

MIT
