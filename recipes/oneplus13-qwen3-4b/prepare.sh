#!/data/data/com.termux/files/usr/bin/bash
# Prepare: install deps, build llama.cpp, download model
set -e

source "$(dirname "$0")/recipe.env"

export PREFIX=/data/data/com.termux/files/usr
export HOME=/data/data/com.termux/files/home
export PATH=$PREFIX/bin:$PATH

echo "[prepare] Installing build dependencies..."
pkg install -y cmake clang git make wget openssl

echo "[prepare] Cloning llama.cpp..."
cd $HOME
if [ ! -d "llama.cpp" ]; then
    git clone --depth 1 https://github.com/ggml-org/llama.cpp.git
else
    cd llama.cpp && git pull && cd ..
fi

echo "[prepare] Building llama.cpp (static, CPU)..."
cd llama.cpp
rm -rf build && mkdir build && cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_OPENMP=$GGML_OPENMP \
    -DGGML_CPU_AARCH64=$GGML_CPU_AARCH64 \
    -DGGML_NATIVE=$GGML_NATIVE \
    -DBUILD_SHARED_LIBS=$BUILD_SHARED_LIBS

make -j$(nproc) llama-cli llama-server

echo "[prepare] Verifying build..."
./bin/llama-cli --version || { echo "BUILD FAILED"; exit 1; }

echo "[prepare] Downloading model: $MODEL_NAME ($MODEL_SIZE_GB GB)..."
mkdir -p $HOME/models
cd $HOME/models
if [ ! -f "$MODEL_FILE" ]; then
    wget -q --show-progress "$MODEL_URL" -O "$MODEL_FILE"
else
    echo "[prepare] Model already exists, skipping download"
fi

echo "[prepare] Done. Run start.sh to begin inference."
