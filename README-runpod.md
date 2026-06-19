# Applio on Runpod (Pod Mode)

Voice conversion training using Applio on Runpod GPU instances with persistent storage.

## Architecture

- Container runs Applio (Gradio web UI) on port 6969
- Pretrained models baked into the image (no cold-start download)
- Persistent data on `/workspace` network volume
- Trained models & datasets survive pod termination

## Runpod Template Setup

1. **Create a Network Volume** (recommended 50GB+ for training)
2. **Create a Pod Template:**
   - Container Image: `ghcr.io/cjkihl/applio-runpod:latest`
   - Expose HTTP Port: `6969`
   - Volume Mount: `/workspace`
   - Environment: (optional)
   - Container Disk: 20GB+

3. **Start a Pod with:**
   - GPU: RTX 3090 (24GB) minimum — A6000 (48GB) or A100 (40GB+80GB) recommended for training
   - Template from step 2
   - Network Volume from step 1

4. **Access** via Runpod HTTP proxy at:
   ```
   https://<pod-id>-6969.proxy.runpod.net
   ```

## How Training Works

Data is stored on the `/workspace` network volume:

```
/workspace/
├── logs/          # Training checkpoints, tensorboard logs, .pth/.index files
├── config/        # UI settings (persistent)
├── datasets/      # Uploaded audio for training
└── models/        # Trained model files
```

Training steps via the Gradio UI:
1. **Upload dataset** (zip of audio files or individual files)
2. **Preprocess** the dataset
3. **Train** the RVC model
4. **Extract index** file
5. **Inference** with your trained model

## GPU Recommendations for Training

| GPU | VRAM | Cost (Community Cloud) | Notes |
|-----|------|------------------------|-------|
| RTX 3090 | 24GB | ~$0.28/hr | Minimum viable |
| RTX 4090 | 24GB | ~$0.34/hr | Fastest consumer |
| RTX A6000 | 48GB | ~$0.33/hr | Solid for training |
| A100 SXM | 40GB | ~$1.00/hr | Best for production |

## Build Locally

```bash
./build.sh
```

Or push to trigger a GitHub Action build:

```bash
git push origin main
```
