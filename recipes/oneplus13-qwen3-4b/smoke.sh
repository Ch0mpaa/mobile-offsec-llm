#!/data/data/com.termux/files/usr/bin/bash
# Smoke test: verify model loads and generates
set -e

source "$(dirname "$0")/recipe.env"

export PREFIX=/data/data/com.termux/files/usr
export HOME=/data/data/com.termux/files/home
export PATH=$PREFIX/bin:$PATH

LLAMA_CLI=$HOME/llama.cpp/build/bin/llama-cli
MODEL=$HOME/models/$MODEL_FILE

echo "=== Smoke Test ==="
echo "Device: $DEVICE_NAME"
echo "SoC: $SOC"
echo "Model: $MODEL_NAME $QUANTIZATION"
echo ""

# Quick generation test
echo "[smoke] Running inference test..."
OUTPUT=$($LLAMA_CLI \
    -m "$MODEL" \
    -t $THREADS \
    -p "Explain what nmap -sV does in one sentence:" \
    -n 50 \
    --no-warmup \
    --log-disable \
    2>&1)

echo "$OUTPUT"

if echo "$OUTPUT" | grep -qi "tok/s"; then
    echo ""
    echo "[smoke] PASS - Model loaded and generated output"
else
    echo ""
    echo "[smoke] FAIL - No generation output detected"
    exit 1
fi
