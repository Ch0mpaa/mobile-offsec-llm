#!/data/data/com.termux/files/usr/bin/bash
# start.sh — Launch llama.cpp in chat, server, or bench mode
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

REASONING_FLAG=""
if [ "$THINKING_MODE" = "off" ]; then
    REASONING_FLAG="--reasoning-budget 0"
elif [ "${THINKING_MODE#budget=}" != "$THINKING_MODE" ]; then
    REASONING_FLAG="--reasoning-budget ${THINKING_MODE#budget=}"
fi

MODE="${1:-chat}"

echo "[start] $RECIPE_FORMAT | $DEVICE_NAME ($SOC)"
echo "[start] $MODEL_NAME $QUANTIZATION ($MODEL_SIZE_GB GB) | $ENGINE $BUILD_TYPE | ${THREADS}t"
echo "[start] GPU: $([ "$GPU_USED" = "1" ] && echo "$GPU" || echo "off") | NPU: $([ "$NPU_USED" = "1" ] && echo "$NPU" || echo "off")"
echo ""

case "$MODE" in
    chat)
        echo "[start] Interactive chat mode"
        $LLAMA_CLI \
            -m "$MODEL" \
            -t $THREADS \
            -c $CONTEXT_LENGTH \
            $REASONING_FLAG \
            --no-warmup
        ;;
    server)
        echo "[start] API server on $HOST:$PORT"
        $LLAMA_SERVER \
            -m "$MODEL" \
            -t $THREADS \
            -c $CONTEXT_LENGTH \
            --host $HOST \
            --port $PORT
        ;;
    bench)
        echo "[start] Quick benchmark (single prompt)"
        $LLAMA_CLI \
            -m "$MODEL" \
            -t $THREADS \
            -p "Write a Python script that performs a port scan on 10.10.10.5 ports 1-1024 using sockets:" \
            -n 300 \
            $REASONING_FLAG \
            --no-warmup \
            --log-disable
        ;;
    *)
        echo "Usage: start.sh [chat|server|bench]"
        exit 1
        ;;
esac
