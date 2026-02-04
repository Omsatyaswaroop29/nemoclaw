<p align="center">
  <h1 align="center">🦞 NemoClaw</h1>
</p>

<p align="center">
  <strong>Self-Hosted AI Inference Server for OpenClaw</strong><br>
  Run Nemotron 3 Nano locally • Cut API costs by 90% • Keep your data private
</p>

<p align="center">
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-configuration">Configuration</a> •
  <a href="#-api-reference">API Reference</a> •
  <a href="#-troubleshooting">Troubleshooting</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Model-Nemotron%203%20Nano%2030B-green?style=flat-square" alt="Model"/>
  <img src="https://img.shields.io/badge/Context-1M%20Tokens-blue?style=flat-square" alt="Context"/>
  <img src="https://img.shields.io/badge/Speed-120%2B%20tok%2Fs-orange?style=flat-square" alt="Speed"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="License"/>
</p>

---

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Why NemoClaw?](#-why-nemoclaw)
3. [Quick Start](#-quick-start)
4. [System Requirements](#-system-requirements)
5. [Installation](#-installation)
6. [Configuration](#-configuration)
7. [API Reference](#-api-reference)
8. [Management Commands](#-management-commands)
9. [Cost Analysis](#-cost-analysis)
10. [Troubleshooting](#-troubleshooting)
11. [Contributing](#-contributing)
12. [License](#-license)

---

## 🎯 Overview

**NemoClaw** is a production-ready deployment package that runs NVIDIA's Nemotron 3 Nano model on your own AWS infrastructure. It provides an OpenAI-compatible API endpoint that integrates seamlessly with OpenClaw, eliminating expensive cloud API subscriptions while keeping your data completely private.

### What You Get

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR APPLICATIONS                         │
│          (OpenClaw, ChatUI, Custom Apps, etc.)              │
└─────────────────────────────┬───────────────────────────────┘
                              │ HTTP/REST API
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      NEMOCLAW SERVER                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │            OpenAI-Compatible API Layer               │   │
│  │              http://your-ip:8001/v1                  │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              llama.cpp Inference Engine              │   │
│  │          (Optimized for NVIDIA GPUs + CUDA)          │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Nemotron 3 Nano Model                   │   │
│  │     30B Parameters • 1M Context • Q4 Quantized       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     AWS EC2 g5.xlarge                        │
│              NVIDIA A10G GPU (24GB VRAM)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 💡 Why NemoClaw?

### The Problem

OpenClaw users typically spend **$300-750/month** on Claude or GPT-4 API costs. For heavy users, costs can exceed $1000/month. Your sensitive data also gets sent to third-party servers.

### The Solution

NemoClaw runs a powerful open-source model on your own infrastructure:

| Aspect | Cloud APIs (Claude/GPT-4) | NemoClaw |
|--------|---------------------------|----------|
| **Monthly Cost** | $300 - $750+ | **$30 - $60** |
| **Cost per Token** | $0.003 - $0.015 | **$0** |
| **Data Privacy** | Sent to third parties | **100% on your server** |
| **Context Window** | 128K - 200K tokens | **1,000,000 tokens** |
| **Rate Limits** | Yes, can interrupt workflows | **None** |
| **Uptime Dependency** | Relies on provider | **You control it** |

### Who Is This For?

- ✅ **OpenClaw users** wanting to reduce API costs
- ✅ **Developers** building AI applications without per-token fees
- ✅ **Privacy-conscious users** who can't send data to external APIs
- ✅ **Teams** needing unlimited AI access without budget constraints
- ✅ **Researchers** processing large documents (1M token context!)

---

## ⚡ Quick Start

For experienced users who want to get running in 10 minutes:

```bash
# 1. Launch EC2 g5.xlarge with "Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.9 (Amazon Linux 2023)"
# 2. Open ports 22 (SSH) and 8001 (API) in security group
# 3. SSH into your instance:
ssh -i your-key.pem ec2-user@YOUR_INSTANCE_IP

# 4. Run the one-line installer:
curl -sSL https://raw.githubusercontent.com/Omsatyaswaroop29/nemoclaw/main/scripts/install.sh | bash

# 5. Wait ~20 minutes for download and setup, then test:
curl http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"nemotron","messages":[{"role":"user","content":"Hello! Who are you?"}]}'
```

**New to AWS or want detailed guidance?** See the [full installation guide](docs/AWS_SETUP_GUIDE.md).

---

## 💻 System Requirements

### AWS Infrastructure (Recommended)

| Component | Specification | Why |
|-----------|---------------|-----|
| **Instance Type** | g5.xlarge | Best price/performance for 30B models |
| **GPU** | NVIDIA A10G (24GB VRAM) | Fits the 21GB quantized model |
| **vCPUs** | 4 | Sufficient for inference workloads |
| **RAM** | 16 GB | Handles model loading and requests |
| **Storage** | 100 GB gp3 SSD | Model (21GB) + system + logs |
| **AMI** | Amazon Linux 2023 Deep Learning | Pre-installed NVIDIA drivers |

### Alternative Hardware

NemoClaw can run on any system with:

- **Minimum 24GB VRAM** (RTX 4090, RTX 6000, A10G, A100)
- **NVIDIA GPU with CUDA support** (Compute capability 7.0+)
- **50GB free disk space** (for model + llama.cpp)
- **Linux operating system** (Ubuntu 22.04 or Amazon Linux 2023 recommended)

---

## 🚀 Installation

### Step 1: AWS Account Setup

**Request GPU Quota (First-Time Only):**

1. Sign in to the AWS Console
2. Navigate to **Service Quotas** → **Amazon EC2**
3. Search for **"Running On-Demand G and VT instances"**
4. Request increase to **4** vCPUs
5. Wait for approval (usually 15-30 minutes)

**Create SSH Key Pair:**

1. Go to **EC2 → Key Pairs**
2. Create key pair named `nemoclaw-key`
3. Download the `.pem` file
4. Set permissions: `chmod 400 ~/.ssh/nemoclaw-key.pem`

### Step 2: Launch EC2 Instance

1. Go to **EC2 → Launch Instance**
2. **Name:** `nemoclaw-server`
3. **AMI:** Search for "Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.9 (Amazon Linux 2023)"
4. **Instance type:** `g5.xlarge`
5. **Key pair:** Select `nemoclaw-key`
6. **Security group:** Create new with:
   - SSH (port 22) from My IP
   - Custom TCP (port 8001) from My IP
7. **Storage:** 100 GiB gp3
8. Click **Launch Instance**

### Step 3: Install NemoClaw

```bash
# Connect to your instance
ssh -i ~/.ssh/nemoclaw-key.pem ec2-user@YOUR_INSTANCE_IP

# Run the installer
curl -sSL https://raw.githubusercontent.com/Omsatyaswaroop29/nemoclaw/main/scripts/install.sh | bash
```

The installer will:
1. Install CUDA Toolkit 12.4
2. Clone and build llama.cpp with GPU support
3. Download Nemotron 3 Nano (21GB)
4. Create and start the systemd service

**Expected time:** 20-30 minutes (model download is the longest step)

### Step 4: Verify Installation

```bash
# Check service status
sudo systemctl status nemoclaw

# Test the API (wait 60-90 seconds for model to load)
curl http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"nemotron","messages":[{"role":"user","content":"Hello!"}]}'
```

For detailed step-by-step instructions with screenshots, see [AWS Setup Guide](docs/AWS_SETUP_GUIDE.md).

---

## ⚙️ Configuration

### OpenClaw Integration

Edit your OpenClaw config file:

```bash
nano ~/.openclaw/config.json
```

Add the NemoClaw provider:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "provider": "openai-compatible",
        "baseUrl": "http://YOUR_INSTANCE_IP:8001/v1",
        "model": "nemotron",
        "apiKey": "not-needed"
      }
    }
  }
}
```

### Server Configuration

The NemoClaw server supports various configuration options. To modify, edit the service file:

```bash
sudo nano /etc/systemd/system/nemoclaw.service
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-m` | (required) | Path to the model file |
| `--host` | `0.0.0.0` | Bind address |
| `--port` | `8001` | API server port |
| `-ngl` | `99` | GPU layers (99 = all) |
| `-c` | `32768` | Context size (max 1048576) |

After editing:
```bash
sudo systemctl daemon-reload
sudo systemctl restart nemoclaw
```

---

## 📡 API Reference

NemoClaw provides a fully OpenAI-compatible API.

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/models` | GET | List available models |
| `/v1/chat/completions` | POST | Generate chat completions |
| `/v1/completions` | POST | Generate text completions |
| `/health` | GET | Health check endpoint |

### Chat Completions

```bash
curl http://YOUR_IP:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Explain quantum computing in simple terms."}
    ],
    "temperature": 0.7,
    "max_tokens": 500
  }'
```

### Streaming Responses

```bash
curl http://YOUR_IP:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron",
    "messages": [{"role": "user", "content": "Write a haiku about coding."}],
    "stream": true
  }'
```

---

## 🛠️ Management Commands

### Service Control

```bash
sudo systemctl start nemoclaw      # Start the server
sudo systemctl stop nemoclaw       # Stop the server
sudo systemctl restart nemoclaw    # Restart the server
sudo systemctl status nemoclaw     # Check status
```

### Viewing Logs

```bash
sudo journalctl -u nemoclaw -f           # Stream live logs
sudo journalctl -u nemoclaw -n 100       # Last 100 lines
sudo journalctl -u nemoclaw --since today # Today's logs
```

### Health Monitoring

```bash
curl http://localhost:8001/v1/models     # Check API
nvidia-smi                                # Check GPU
```

---

## 💰 Cost Analysis

### AWS Running Costs

| Usage Pattern | Hours/Month | Monthly Cost |
|---------------|-------------|--------------|
| Light (1 hr/day) | 30 | ~$38 |
| Moderate (2 hr/day) | 60 | ~$68 |
| Heavy (4 hr/day) | 120 | ~$129 |
| Always On (24/7) | 720 | ~$733 |

(Includes ~$8/month for 100GB storage)

### ⚠️ Cost Management

**CRITICAL: Stop your instance when not in use!**

```bash
# From AWS Console:
# EC2 → Instances → Select instance → Instance state → Stop instance
```

| Instance State | EC2 Charge | Storage Charge |
|----------------|------------|----------------|
| Running | ✅ Yes ($1.01/hr) | ✅ Yes |
| Stopped | ❌ No | ✅ Yes |

---

## 🔍 Troubleshooting

### Common Issues

**SSH Connection Timeout:**
- Your IP may have changed. Update security group with current IP.
- Check instance is "Running" in EC2 console.

**"Loading model" Error (503):**
- Model takes 60-90 seconds to load. Wait and retry.
- Monitor with: `sudo journalctl -u nemoclaw -f`

**CUDA Out of Memory:**
- Reduce context size: Change `-c 32768` to `-c 16384` in service file.

**Service Won't Start:**
- Check logs: `sudo journalctl -u nemoclaw -n 50`
- Verify model file exists: `ls -la ~/models/`

For detailed solutions, see [Troubleshooting Guide](docs/TROUBLESHOOTING.md).

---

## 📊 Performance Benchmarks

| Metric | Value |
|--------|-------|
| **Model** | Nemotron 3 Nano 30B (Q4_K_XL) |
| **Total Parameters** | 31.58 billion |
| **Active Parameters** | 3.5 billion (MoE architecture) |
| **Inference Speed** | 120+ tokens/second |
| **Prompt Processing** | 85+ tokens/second |
| **GPU Memory Usage** | 21.5 GB / 24 GB |
| **Max Context Length** | 1,048,576 tokens |

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas where help is needed:
- Docker containerization
- Terraform/CloudFormation templates
- Multi-cloud support (GCP, Azure)
- Monitoring dashboards

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**Model License:** Nemotron 3 Nano is released by NVIDIA under the [NVIDIA Open Model License](https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-license/).

---

## 🙏 Acknowledgments

- [**NVIDIA**](https://www.nvidia.com/) for releasing Nemotron 3 Nano
- [**ggerganov**](https://github.com/ggerganov) and the llama.cpp community
- [**Unsloth**](https://github.com/unslothai) for optimized GGUF quantizations
- [**OpenClaw**](https://github.com/openclaw/openclaw) for the AI agent framework

---

<p align="center">
  <strong>Built by <a href="https://github.com/Omsatyaswaroop29">Om Satya</a></strong>
</p>

<p align="center">
  <a href="https://github.com/Omsatyaswaroop29/nemoclaw">⭐ Star this repo</a> •
  <a href="https://github.com/Omsatyaswaroop29/nemoclaw/issues">🐛 Report Bug</a> •
  <a href="https://github.com/Omsatyaswaroop29/nemoclaw/issues">💡 Request Feature</a>
</p>
