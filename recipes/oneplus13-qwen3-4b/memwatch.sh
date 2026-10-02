#!/data/data/com.termux/files/usr/bin/bash
# memwatch.sh — Thermal and memory watchdog for sustained mobile inference
# Monitors SoC temperature and available RAM, pauses/kills inference if limits hit
set -e

source "$(dirname "$0")/recipe.env"

export HOME=/data/data/com.termux/files/home
LOG="$(dirname "$0")/results/memwatch.log"
mkdir -p "$(dirname "$LOG")"

THROTTLE_C="${THERMAL_THROTTLE_C:-85}"
MIN_RAM="${MIN_RAM_MB:-1024}"
INTERVAL=5

echo "=== memwatch started ===" >> "$LOG"
echo "Thermal limit: ${THROTTLE_C}C | RAM floor: ${MIN_RAM}MB | Interval: ${INTERVAL}s" >> "$LOG"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) START" >> "$LOG"

get_temp() {
    local max_temp=0
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        [ -r "$zone" ] || continue
        local t=$(cat "$zone" 2>/dev/null || echo 0)
        local tc=$((t / 1000))
        [ $tc -gt $max_temp ] && max_temp=$tc
    done
    echo $max_temp
}

get_avail_ram_mb() {
    local avail=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
    echo $((${avail:-0} / 1024))
}

while true; do
    TEMP=$(get_temp)
    RAM=$(get_avail_ram_mb)
    TS=$(date +%H:%M:%S)

    if [ $TEMP -ge $THROTTLE_C ]; then
        echo "$TS THROTTLE temp=${TEMP}C >= ${THROTTLE_C}C — pausing inference" >> "$LOG"
        echo "[memwatch] THERMAL THROTTLE: ${TEMP}C — sending SIGSTOP to llama"
        pkill -STOP -f llama-cli 2>/dev/null || true
        pkill -STOP -f llama-server 2>/dev/null || true

        while [ $(get_temp) -ge $((THROTTLE_C - 10)) ]; do
            sleep 10
        done

        echo "$(date +%H:%M:%S) RESUME temp=$(get_temp)C" >> "$LOG"
        echo "[memwatch] Cooled to $(get_temp)C — resuming"
        pkill -CONT -f llama-cli 2>/dev/null || true
        pkill -CONT -f llama-server 2>/dev/null || true
    fi

    if [ $RAM -lt $MIN_RAM ]; then
        echo "$TS OOM_KILL avail=${RAM}MB < ${MIN_RAM}MB — killing inference" >> "$LOG"
        echo "[memwatch] LOW MEMORY: ${RAM}MB — killing llama to prevent OOM"
        pkill -9 -f llama-cli 2>/dev/null || true
        pkill -9 -f llama-server 2>/dev/null || true
        exit 1
    fi

    echo "$TS OK temp=${TEMP}C ram=${RAM}MB" >> "$LOG"
    sleep $INTERVAL
done
