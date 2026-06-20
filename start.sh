#!/bin/bash
set -e

echo "=== GPU Info ==="
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader || echo "No GPU detected"

# Ensure RunPod persistent directories exist in the mounted volume
mkdir -p /workspace/logs \
         /workspace/config \
         /workspace/datasets \
         /workspace/models/pretraineds \
         /workspace/models/embedders \
         /workspace/models/predictors \
         /workspace/audios \
         /workspace/presets

# --- Clean and Link Logs ---
if [ -d /app/logs ]; then rm -rf /app/logs; fi
ln -sf /workspace/logs /app/logs

# --- Clean and Link Config ---
if [ ! -f /workspace/config/config.json ] && [ -f /app/assets/config.json ]; then
    cp /app/assets/config.json /workspace/config/config.json
fi
if [ -f /app/assets/config.json ]; then rm -f /app/assets/config.json; fi
ln -sf /workspace/config/config.json /app/assets/config.json

# --- Clean and Link Datasets ---
if [ -d /app/assets/datasets ]; then rm -rf /app/assets/datasets; fi
ln -sf /workspace/datasets /app/assets/datasets

# --- Clean and Link Audio Inputs/Outputs ---
if [ -d /app/assets/audios ]; then rm -rf /app/assets/audios; fi
ln -sf /workspace/audios /app/assets/audios

# --- Clean and Link Presets ---
if [ -d /app/assets/presets ]; then rm -rf /app/assets/presets; fi
ln -sf /workspace/presets /app/assets/presets

# --- Clean and Link RVC Models ---
if [ -d /app/rvc/models/pretraineds ]; then rm -rf /app/rvc/models/pretraineds; fi
ln -sf /workspace/models/pretraineds /app/rvc/models/pretraineds

if [ -d /app/rvc/models/embedders ]; then rm -rf /app/rvc/models/embedders; fi
ln -sf /workspace/models/embedders /app/rvc/models/embedders

if [ -d /app/rvc/models/predictors ]; then rm -rf /app/rvc/models/predictors; fi
ln -sf /workspace/models/predictors /app/rvc/models/predictors

echo "=== Symlinks configured successfully ==="
echo "=== Starting Applio on port 6969 ==="

# CRITICAL FIX: Run from /app where the codebase resides, not the empty /workspace volume
cd /app
exec python app.py --port 6969