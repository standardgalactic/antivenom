#!/bin/bash
#
# ISM-Agent Kernel
# This file is intentionally minimal and stable.
#

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

FACTORY_DIR="$ROOT_DIR/factory"
LIVE_DIR="$ROOT_DIR/live"
LOG_DIR="$ROOT_DIR/logs"
MEMORY_DIR="$ROOT_DIR/memory"
PATCH_DIR="$ROOT_DIR/patches"

RESET=false

for arg in "$@"; do
    case "$arg" in
        --reset)
            RESET=true
            ;;
    esac
done

if $RESET; then
    if [ ! -f "$ROOT_DIR/reset.lock" ]; then
        echo "ERROR: reset.lock missing"
        exit 1
    fi

    cp "$FACTORY_DIR/config.factory" "$LIVE_DIR/config.live"
    cp "$FACTORY_DIR/policy.factory" "$LIVE_DIR/policy.live"

    VERSION=$(cat "$LIVE_DIR/version.txt")
    echo $((VERSION + 1)) > "$LIVE_DIR/version.txt"

    echo "$(date) RESET to factory state" >> "$LOG_DIR/runs.log"
    echo "Reset complete."
    exit 0
fi

# Load live configuration
source "$LIVE_DIR/config.live"

RUN_ID=$(printf "%04d" "$(ls "$MEMORY_DIR" 2>/dev/null | wc -l)")
MEMORY_FILE="$MEMORY_DIR/run_${RUN_ID}.memory"

echo "Run $RUN_ID started at $(date)" >> "$LOG_DIR/runs.log"
echo "Mode: $MODE" >> "$MEMORY_FILE"
echo "Chunk size: $CHUNK_SIZE" >> "$MEMORY_FILE"

echo "Agent run complete." >> "$MEMORY_FILE"
echo "Run $RUN_ID complete" >> "$LOG_DIR/runs.log"
