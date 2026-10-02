#!/data/data/com.termux/files/usr/bin/bash
# Stop: kill running llama-server or llama-cli
echo "[stop] Stopping any running llama processes..."
pkill -f llama-server 2>/dev/null && echo "[stop] llama-server stopped" || echo "[stop] no llama-server running"
pkill -f llama-cli 2>/dev/null && echo "[stop] llama-cli stopped" || echo "[stop] no llama-cli running"
echo "[stop] Done."
