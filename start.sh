#!/bin/bash
set -e

echo "=== GPU Info ==="
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader || echo "No GPU detected"

# -------------------------------------------------------------------------
# 1. Ensure Persistent Storage Target Directories Exist
# -------------------------------------------------------------------------
mkdir -p /workspace/logs \
         /workspace/config \
         /workspace/datasets \
         /workspace/audios \
         /workspace/presets \
         /workspace/models/pretraineds \
         /workspace/models/embedders \
         /workspace/models/predictors

# -------------------------------------------------------------------------
# 2. Seed Default Log Assets (New Volume)
# -------------------------------------------------------------------------
if [ ! "$(ls -A /workspace/logs 2>/dev/null)" ] && [ -d /app/logs ]; then
    echo "=== Initializing persistent log directory with base assets ==="
    cp -r /app/logs/* /workspace/logs/ 2>/dev/null || true
fi

# -------------------------------------------------------------------------
# 3. Seed Default Config (New Volume)
# -------------------------------------------------------------------------
if [ ! -f /workspace/config/config.json ] && [ -f /app/assets/config.json ]; then
    cp /app/assets/config.json /workspace/config/config.json
fi

# -------------------------------------------------------------------------
# 4. Safe Bind Mount Function (prevents double-mounting on restart)
# -------------------------------------------------------------------------
safe_bind_mount() {
    local source_dir="$1"
    local target_dir="$2"

    mkdir -p "$target_dir"

    if mountpoint -q "$target_dir"; then
        echo "Already mounted: $target_dir. Skipping."
    else
        echo "Bind-mounting $source_dir -> $target_dir"
        bindfs --no-allow-other "$source_dir" "$target_dir"
    fi
}

# -------------------------------------------------------------------------
# 5. Mount Persistent Storage Over Local Paths
# -------------------------------------------------------------------------
safe_bind_mount /workspace/logs              /app/logs
safe_bind_mount /workspace/datasets          /app/assets/datasets
safe_bind_mount /workspace/audios            /app/assets/audios
safe_bind_mount /workspace/presets           /app/assets/presets
safe_bind_mount /workspace/models/pretraineds /app/rvc/models/pretraineds
safe_bind_mount /workspace/models/embedders   /app/rvc/models/embedders
safe_bind_mount /workspace/models/predictors  /app/rvc/models/predictors

# Config is a file (not a dir), use symlink
if [ -f /app/assets/config.json ]; then rm -f /app/assets/config.json; fi
ln -sf /workspace/config/config.json /app/assets/config.json

echo "=== All Bind Mounts Configured ==="
echo "=== Starting Applio on port 6969 ==="

cd /app
exec python3.11 app.py --server-name 0.0.0.0 --port 6969
