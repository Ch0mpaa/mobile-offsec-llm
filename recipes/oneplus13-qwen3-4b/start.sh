#!/data/data/com.termux/files/usr/bin/bash
# Start: launch llama.cpp server or interactive chat
set -e

source "$(dirname "$0")/recipe.env"

export PREFIX=/data/data/com.termux/files/usr
export HOME=/data/data/com.termux/files/home
export PATH=$PREFIX/bin:$PATH

LLAMA_CLI=$HOME/llama.cpp/build/bin/llama-cli
LLAMA_SERVER=$HOME/llama.cpp/build/bin/llama-server
MODEL=$HOME/models/$MODEL_FILE

if [ ! -f "$MODEL" ]; then
    echo "[start] Model not found. Run prepare.sh first."
    exit 1
fi

MODE="${1:-chat}"

case "$MODE" in
    chat)
        echo "[start] Interactive chat mode"
        echo "[start] Device: $DEVICE_NAME | SoC: $SOC | Model: $MODEL_NAME $QUANTIZATION"
        echo ""
        $LLAMA_CLI \
            -m "$MODEL" \
            -t $THREADS \
            -c $CONTEXT_LENGTH \
            --no-warmup
        ;;
    server)
        echo "[start] API server mode on $HOST:$PORT"
        echo "[start] Device: $DEVICE_NAME | SoC: $SOC | Model: $MODEL_NAME $QUANTIZATION"
        $LLAMA_SERVER \
            -m "$MODEL" \
            -t $THREADS \
            -c $CONTEXT_LENGTH \
            --host $HOST \
            --port $PORT
        ;;
    bench)
        echo "[start] Benchmark mode"
        echo "[start] Device: $DEVICE_NAME | SoC: $SOC | Model: $MODEL_NAME $QUANTIZATION"
        $LLAMA_CLI \
            -m "$MODEL" \
            -t $THREADS \
            -p "Write a Python script that performs a port scan on 10.10.10.5 ports 1-1024 using sockets:" \
            -n 300 \
            --no-warmup
        ;;
    *)
        echo "Usage: start.sh [chat|server|bench]"
        exit 1
        ;;
esac
