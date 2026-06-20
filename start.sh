#!/bin/bash
set -e

cd /workspace

echo "=== GPU Info ==="
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader || echo "No GPU detected"

mkdir -p /workspace/logs /workspace/config

echo "=== Starting Applio on port 6969 ==="
exec python /workspace/app.py --server-name 0.0.0.0 --port 6969
