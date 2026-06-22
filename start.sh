#!/bin/bash
set -e

echo "=== GPU Info ==="
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader || echo "No GPU detected"

# -------------------------------------------------------------------------
# 1. Ensure Persistent Storage Target Directories Exist
# -------------------------------------------------------------------------
echo "=== Creating persistent directories ==="
mkdir -p /workspace/logs \
         /workspace/config \
         /workspace/datasets \
         /workspace/audios \
         /workspace/presets \
         /workspace/models/pretraineds \
         /workspace/models/embedders \
         /workspace/models/predictors

# -------------------------------------------------------------------------
# 2. Seed Default Log Assets (first run on a new volume)
# -------------------------------------------------------------------------
if [ ! "$(ls -A /workspace/logs 2>/dev/null)" ] && [ -d /app/logs ]; then
    echo "=== New volume detected: seeding base log assets ==="
    cp -r /app/logs/* /workspace/logs/ 2>/dev/null || true
fi

# -------------------------------------------------------------------------
# 3. Seed Default Config
# -------------------------------------------------------------------------
if [ ! -f /workspace/config/config.json ] && [ -f /app/assets/config.json ]; then
    echo "=== Seeding config ==="
    cp /app/assets/config.json /workspace/config/config.json
fi

# -------------------------------------------------------------------------
# 4. Determine Mount Strategy (bindfs vs symlink fallback)
# -------------------------------------------------------------------------
if [ -c /dev/fuse ]; then
    echo "=== FUSE available, using bindfs mounts ==="

    assert_mounted() {
        local dir="$1"
        if ! mountpoint -q "$dir"; then
            echo "FATAL: bindfs mount failed for $dir. Aborting to prevent data loss."
            exit 1
        fi
    }

    do_bindfs() {
        local src="$1"
        local dst="$2"

        mkdir -p "$dst"

        if mountpoint -q "$dst"; then
            echo "  Already mounted: $dst"
            return
        fi

        echo "  Mounting $src -> $dst"
        bindfs --no-allow-other "$src" "$dst"

        assert_mounted "$dst"
    }

    do_bindfs /workspace/logs               /app/logs
    do_bindfs /workspace/datasets           /app/assets/datasets
    do_bindfs /workspace/audios             /app/assets/audios
    do_bindfs /workspace/presets            /app/assets/presets
    do_bindfs /workspace/models/pretraineds /app/rvc/models/pretraineds
    do_bindfs /workspace/models/embedders   /app/rvc/models/embedders
    do_bindfs /workspace/models/predictors  /app/rvc/models/predictors

    # -----------------------------------------------------------------
    # Canary test: verify writes go to the volume, not ephemeral disk
    # -----------------------------------------------------------------
    echo "=== Verifying persistence ==="
    CANARY=".volumetest_$$"
    date > "/app/logs/$CANARY"
    if [ -f "/workspace/logs/$CANARY" ]; then
        rm -f "/workspace/logs/$CANARY"
        echo "  Persistence verified: writes reach the volume."
    else
        echo "FATAL: Write test failed — files are NOT reaching the volume. Aborting."
        exit 1
    fi

else
    # -----------------------------------------------------------------
    # FALLBACK: symlinks (no FUSE available)
    # -----------------------------------------------------------------
    echo "=== WARNING: /dev/fuse not found, falling back to symlinks ==="
    echo "=== Persistence depends on symlinks working correctly       ==="

    do_symlink() {
        local src="$1"
        local dst="$2"
        if [ -d "$dst" ]; then rm -rf "$dst"; fi
        ln -sf "$src" "$dst"
        echo "  Symlinked $src -> $dst"
    }

    do_symlink /workspace/logs               /app/logs
    do_symlink /workspace/datasets           /app/assets/datasets
    do_symlink /workspace/audios             /app/assets/audios
    do_symlink /workspace/presets            /app/assets/presets
    do_symlink /workspace/models/pretraineds /app/rvc/models/pretraineds
    do_symlink /workspace/models/embedders   /app/rvc/models/embedders
    do_symlink /workspace/models/predictors  /app/rvc/models/predictors
fi

# -------------------------------------------------------------------------
# 6. Config (always a symlink — it's a single file)
# -------------------------------------------------------------------------
rm -f /app/assets/config.json
ln -sf /workspace/config/config.json /app/assets/config.json

echo "=== All mounts configured ==="
echo "=== Starting Applio on port 6969 ==="

cd /app
exec python3.11 app.py --server-name 0.0.0.0 --port 6969
