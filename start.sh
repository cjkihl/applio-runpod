#!/bin/bash
set -e

source /app/.venv/bin/activate

echo "=== GPU Info ==="
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader || echo "No GPU detected"

mkdir -p /workspace/logs /workspace/config /workspace/datasets

if [ -d /app/logs ]; then
    rm -rf /app/logs
fi
ln -sf /workspace/logs /app/logs

if [ ! -f /workspace/config/config.json ]; then
    cp /app/assets/config.json /workspace/config/config.json
fi
ln -sf /workspace/config/config.json /app/assets/config.json

echo "=== Starting Applio on port 6969 ==="
exec python /app/app.py --server-name 0.0.0.0 --port 6969
