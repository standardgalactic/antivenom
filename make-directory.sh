#!/bin/bash
#
# =============================================================================
# NAME
#   make-directory.sh
#
# PURPOSE
#   Initialize the Incremental Self-Modifying Agent (ISM-Agent) project
#   directory structure and seed all required files.
#
# BEHAVIOR
#   - Creates factory, live, memory, patches, logs directories
#   - Writes immutable factory configuration and policy
#   - Writes mutable live copies
#   - Creates reset lock file (trust anchor)
#   - Computes and stores factory checksums
#
# SAFETY
#   This script should be run ONCE.
#   Re-running may overwrite existing files.
#
# =============================================================================

set -e

ROOT_DIR="agent"

echo "Initializing ISM-Agent project in ./$ROOT_DIR"

# ===============================
# Directory structure
# ===============================
mkdir -p "$ROOT_DIR"/{factory,live,memory,patches,logs}

# ===============================
# Factory files (IMMUTABLE)
# ===============================

cat > "$ROOT_DIR/factory/config.factory" <<'EOF'
MODEL=granite3.2:8b
CHUNK_SIZE=2000
MODE=summarize
ALLOW_PATCH=true
MAX_PATCH_SIZE=20
EOF

cat > "$ROOT_DIR/factory/policy.factory" <<'EOF'
- Do not modify traversal or reset logic
- Do not modify factory or reset files
- Only one patch proposal per run
- Prefer minimal, reversible changes
- Configuration changes are preferred over code changes
EOF

# ===============================
# Reset lock (IMMUTABLE)
# ===============================
cat > "$ROOT_DIR/reset.lock" <<'EOF'
FACTORY_RESET_REQUIRED
DO NOT MODIFY THIS FILE
THIS FILE IS A TRUST ANCHOR
EOF

# Make reset.lock read-only
chmod 444 "$ROOT_DIR/reset.lock"

# ===============================
# Live files (MUTABLE)
# ===============================

cp "$ROOT_DIR/factory/config.factory" "$ROOT_DIR/live/config.live"
cp "$ROOT_DIR/factory/policy.factory" "$ROOT_DIR/live/policy.live"

cat > "$ROOT_DIR/live/version.txt" <<'EOF'
0
EOF

# ===============================
# Agent kernel (STABLE)
# ===============================

cat > "$ROOT_DIR/agent.sh" <<'EOF'
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
EOF

chmod +x "$ROOT_DIR/agent.sh"

# ===============================
# Factory checksums
# ===============================

(
    cd "$ROOT_DIR/factory"
    sha256sum config.factory policy.factory > checksum.factory
)

chmod 444 "$ROOT_DIR/factory/checksum.factory"

# ===============================
# Initial log
# ===============================
cat > "$ROOT_DIR/logs/runs.log" <<'EOF'
ISM-Agent initialized
EOF

echo "Initialization complete."
echo "Project created at ./$ROOT_DIR"
echo
echo "Next steps:"
echo "  cd agent"
echo "  ./agent.sh        # run agent"
echo "  ./agent.sh --reset # reset to factory"

