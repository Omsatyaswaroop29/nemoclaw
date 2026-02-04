<div align="center">

# 🦞 NemoClaw

### **Self-Hosted AI That Lives in Your Pocket**

*Run a 30-billion parameter AI on your own server. Chat with it on Telegram. Pay $0 per token.*

[![Model](https://img.shields.io/badge/Model-Nemotron%203%20Nano%2030B-00D4AA?style=for-the-badge&logo=nvidia&logoColor=white)](https://huggingface.co/nvidia/Nemotron-3-Nano-30B-A3B)
[![Context](https://img.shields.io/badge/Context-1M%20Tokens-blue?style=for-the-badge&logo=openai&logoColor=white)](https://github.com/Omsatyaswaroop29/nemoclaw)
[![Speed](https://img.shields.io/badge/Speed-120%2B%20tok%2Fs-orange?style=for-the-badge&logo=lightning&logoColor=white)](https://github.com/Omsatyaswaroop29/nemoclaw)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/Powered%20by-OpenClaw-red?style=for-the-badge&logo=lobster&logoColor=white)](https://openclaw.ai)

<br/>

[**🚀 Quick Start**](#-quick-start) • [**📖 Documentation**](#-full-installation-guide) • [**💬 Join Discord**](https://discord.gg/openclaw) • [**🐛 Report Bug**](https://github.com/Omsatyaswaroop29/nemoclaw/issues)

<br/>

<img src="https://github.com/user-attachments/assets/nemoclaw-demo.gif" alt="NemoClaw Demo" width="600"/>

*Your AI assistant, running on your hardware, responding on Telegram*

</div>

---

## 🎯 What is NemoClaw?

**NemoClaw** transforms your AWS GPU instance into a personal AI powerhouse. It's a production-ready deployment that runs **NVIDIA's Nemotron 3 Nano** (30 billion parameters!) and connects it to messaging apps through **OpenClaw**.

**The result?** A ChatGPT-like assistant that:
- 💰 Costs **$0 per message** (just ~$30-60/month for AWS)
- 🔒 Keeps **100% of your data** on your own server
- 📱 Works on **Telegram, WhatsApp, Discord, Slack**, and 14+ platforms
- 🧠 Has a **1 million token context window** (process entire codebases!)
- ⚡ Responds at **120+ tokens per second**

---

## 💡 The Problem We're Solving

If you're using OpenClaw (the amazing open-source AI agent), you know the pain:

| The Reality of AI APIs | Monthly Cost |
|------------------------|--------------|
| Claude Opus for power users | $300 - $750+ |
| GPT-4 for daily use | $200 - $500 |
| "Light" API usage | Still $50 - $150 |

**That's $600 - $9,000 per year** just to chat with an AI.

### Enter NemoClaw

| NemoClaw | Monthly Cost |
|----------|--------------|
| Run 1 hour/day | ~$38 |
| Run 2 hours/day | ~$68 |
| Run 4 hours/day | ~$129 |
| **Cost per token** | **$0.00** |

**One-time setup. Unlimited conversations. Your data never leaves your server.**

---

## ⚡ Quick Start

Get your own AI assistant running in **under 30 minutes**.

### Prerequisites

- AWS account with ~$50 credits (or willingness to pay ~$1/hour while running)
- Basic terminal knowledge
- A Telegram account (for the easiest setup)

### Step 1: Launch AWS Instance

```bash
# Instance: g5.xlarge (NVIDIA A10G GPU, 24GB VRAM)
# AMI: Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.9 (Amazon Linux 2023)
# Storage: 100GB gp3
# Security Group: Open ports 22 (SSH) and 8001 (API) to your IP
```

### Step 2: Install NemoClaw (One Command!)

```bash
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Run the installer - it handles everything
curl -sSL https://raw.githubusercontent.com/Omsatyaswaroop29/nemoclaw/main/scripts/install.sh | bash
```

The installer will:
- ✅ Install CUDA Toolkit
- ✅ Build llama.cpp with GPU acceleration
- ✅ Download Nemotron 3 Nano (21GB model)
- ✅ Configure auto-starting systemd service
- ✅ Launch the API server

**Time:** ~20-25 minutes (mostly model download)

### Step 3: Connect OpenClaw

On your local machine:

```bash
# Install OpenClaw
npm install -g openclaw@latest

# Run setup wizard
openclaw onboard
```

When asked about the model provider, we'll configure it to use your NemoClaw server. See [OpenClaw Configuration](#-openclaw-configuration) below.

### Step 4: Chat on Telegram! 🎉

Create a bot with [@BotFather](https://t.me/botfather), connect it during OpenClaw setup, and start chatting!

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                        YOUR PHONE / DESKTOP                         │
│              Telegram • WhatsApp • Discord • Slack                  │
└────────────────────────────────┬───────────────────────────────────┘
                                 │
                                 │ Messages (encrypted)
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│                     OPENCLAW GATEWAY                                │
│                    (runs on your Mac/PC)                            │
│                                                                     │
│   • Receives messages from all platforms                            │
│   • Routes to AI backend                                            │
│   • Manages sessions & memory                                       │
│   • Returns responses                                               │
└────────────────────────────────┬───────────────────────────────────┘
                                 │
                                 │ OpenAI-compatible API
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│                     NEMOCLAW SERVER                                 │
│                   (AWS EC2 g5.xlarge)                               │
│                                                                     │
│   ┌──────────────────────────────────────────────────────────┐     │
│   │              llama.cpp + CUDA                             │     │
│   │         (GPU-accelerated inference engine)                │     │
│   └──────────────────────────────────────────────────────────┘     │
│                              │                                      │
│   ┌──────────────────────────────────────────────────────────┐     │
│   │           Nemotron 3 Nano 30B (Q4_K_XL)                   │     │
│   │                                                           │     │
│   │   • 31.58B total parameters                               │     │
│   │   • 3.5B active (MoE architecture)                        │     │
│   │   • 1M token context window                               │     │
│   │   • 120+ tokens/second generation                         │     │
│   └──────────────────────────────────────────────────────────┘     │
│                                                                     │
│                    NVIDIA A10G (24GB VRAM)                          │
└────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Performance

Real benchmarks from our production deployment:

| Metric | Value | Notes |
|--------|-------|-------|
| **Model** | Nemotron 3 Nano 30B | NVIDIA's latest open model |
| **Quantization** | Q4_K_XL (4-bit) | Best quality/size tradeoff |
| **Parameters** | 31.58B total, 3.5B active | Mixture of Experts |
| **Generation Speed** | 120+ tokens/sec | Tested on A10G |
| **Prompt Processing** | 85+ tokens/sec | Initial context |
| **Time to First Token** | ~200ms | After model loaded |
| **GPU Memory** | 21.5GB / 24GB | Leaves room for context |
| **Max Context** | 1,048,576 tokens | Yes, 1 MILLION |
| **Default Context** | 32,768 tokens | Adjustable |
| **Concurrent Users** | 4 slots | Configurable |

---

## 💰 Cost Breakdown

### AWS Costs (US East Region)

| Resource | Hourly | Monthly (2hr/day) | Monthly (24/7) |
|----------|--------|-------------------|----------------|
| g5.xlarge instance | $1.006 | ~$60 | ~$725 |
| 100GB gp3 storage | - | ~$8 | ~$8 |
| Data transfer | - | ~$2 | ~$10 |
| **Total** | - | **~$70** | **~$743** |

### Savings vs Cloud APIs

| Usage Level | Claude/GPT-4 Cost | NemoClaw Cost | Annual Savings |
|-------------|-------------------|---------------|----------------|
| Light | $150/mo | $38/mo | **$1,344/year** |
| Moderate | $400/mo | $70/mo | **$3,960/year** |
| Heavy | $750/mo | $129/mo | **$7,452/year** |

**💡 Pro Tip:** Stop your instance when not in use. The model reloads in ~90 seconds when you start it again.

---

## 🔧 OpenClaw Configuration

After running `openclaw onboard`, you need to point it to your NemoClaw server.

Edit `~/.openclaw/openclaw.json` and add this `models` section:

```json
{
  "models": {
    "providers": {
      "nemoclaw": {
        "baseUrl": "http://YOUR_EC2_IP:8001/v1",
        "apiKey": "not-needed",
        "api": "openai-completions",
        "models": [
          {
            "id": "nemotron",
            "name": "Nemotron 3 Nano 30B",
            "reasoning": false,
            "input": ["text"],
            "cost": {
              "input": 0,
              "output": 0,
              "cacheRead": 0,
              "cacheWrite": 0
            },
            "contextWindow": 32768,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "nemoclaw/nemotron"
      }
    }
  }
}
```

Then restart the gateway:

```bash
openclaw gateway restart
```

---

## 🛠️ Management Commands

### On Your EC2 Instance

```bash
# Check server status
sudo systemctl status nemoclaw

# View live logs
sudo journalctl -u nemoclaw -f

# Restart the server
sudo systemctl restart nemoclaw

# Stop the server
sudo systemctl stop nemoclaw

# Check GPU usage
nvidia-smi
```

### On Your Local Machine

```bash
# Test the API directly
curl http://YOUR_EC2_IP:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'

# OpenClaw commands
openclaw gateway status
openclaw gateway restart
openclaw pairing list
```

---

## 📁 Project Structure

```
nemoclaw/
├── 📄 README.md              # You are here!
├── 📄 LICENSE                # MIT License
├── 📄 CONTRIBUTING.md        # Contribution guidelines
├── 📄 CHANGELOG.md           # Version history
│
├── 📁 scripts/
│   ├── install.sh           # 🚀 One-command installer
│   ├── health-check.sh      # Server health monitoring
│   └── configure-openclaw.sh # OpenClaw setup helper
│
├── 📁 config/
│   ├── nemoclaw.service     # Systemd service file
│   └── openclaw-config.json # Example OpenClaw config
│
└── 📁 docs/
    ├── AWS_SETUP_GUIDE.md   # Detailed AWS walkthrough
    ├── TROUBLESHOOTING.md   # Common issues & fixes
    └── CHEAT_SHEET.md       # Quick reference card
```

---

## 🔍 Troubleshooting

<details>
<summary><b>❌ "Connection refused" when calling the API</b></summary>

**Cause:** Security group not configured or wrong IP.

**Fix:**
1. Check your EC2's current public IP in AWS Console
2. Update security group to allow your current IP on port 8001
3. Verify NemoClaw is running: `sudo systemctl status nemoclaw`
</details>

<details>
<summary><b>❌ "Loading model" error (503)</b></summary>

**Cause:** Model is still loading into GPU memory.

**Fix:** Wait 60-90 seconds after starting the service. Monitor with:
```bash
sudo journalctl -u nemoclaw -f
# Look for: "server is listening on http://0.0.0.0:8001"
```
</details>

<details>
<summary><b>❌ SSH connection timeout</b></summary>

**Cause:** Your IP changed since setting up security group.

**Fix:**
1. Find your current IP: https://whatismyip.com
2. AWS Console → EC2 → Security Groups → Edit inbound rules
3. Update SSH rule source to your current IP
</details>

<details>
<summary><b>❌ Out of memory errors</b></summary>

**Cause:** Context size too large for available VRAM.

**Fix:** Reduce context size in the service file:
```bash
sudo nano /etc/systemd/system/nemoclaw.service
# Change -c 32768 to -c 16384
sudo systemctl daemon-reload
sudo systemctl restart nemoclaw
```
</details>

**More issues?** See the full [Troubleshooting Guide](docs/TROUBLESHOOTING.md).

---

## 🗺️ Roadmap

- [x] Core NemoClaw server deployment
- [x] OpenClaw integration guide
- [x] Telegram bot support
- [x] One-command installer
- [ ] Docker containerization
- [ ] Terraform/CloudFormation templates
- [ ] WhatsApp setup guide
- [ ] Discord bot guide
- [ ] Multi-GPU support
- [ ] Model switching (use different models)
- [ ] Web dashboard for monitoring
- [ ] Mobile app for server control

**Want to contribute?** See [CONTRIBUTING.md](CONTRIBUTING.md)!

---

## 🤝 Contributing

We welcome contributions! Whether it's:

- 🐛 Bug reports
- 💡 Feature suggestions
- 📖 Documentation improvements
- 🔧 Code contributions

Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting PRs.

---

## 📜 License

This project is licensed under the **MIT License** - see [LICENSE](LICENSE) for details.

### Third-Party Licenses

- **Nemotron 3 Nano**: [NVIDIA Open Model License](https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-license/)
- **llama.cpp**: [MIT License](https://github.com/ggerganov/llama.cpp/blob/master/LICENSE)
- **OpenClaw**: [MIT License](https://github.com/openclaw/openclaw/blob/main/LICENSE)

---

## 🙏 Acknowledgments

This project stands on the shoulders of giants:

- [**NVIDIA**](https://www.nvidia.com/) for releasing Nemotron 3 Nano as an open model
- [**ggerganov**](https://github.com/ggerganov) for the incredible llama.cpp inference engine
- [**Unsloth**](https://github.com/unslothai) for optimized GGUF quantizations
- [**OpenClaw**](https://openclaw.ai) for the brilliant AI agent framework
- The open-source AI community for making this all possible

---

## ⭐ Star History

If this project helped you, consider giving it a star! It helps others discover it.

[![Star History Chart](https://api.star-history.com/svg?repos=Omsatyaswaroop29/nemoclaw&type=Date)](https://star-history.com/#Omsatyaswaroop29/nemoclaw&Date)

---

<div align="center">

### Built with ❤️ by [Om Satya](https://github.com/Omsatyaswaroop29)

**Questions?** [Open an issue](https://github.com/Omsatyaswaroop29/nemoclaw/issues) • **Ideas?** [Start a discussion](https://github.com/Omsatyaswaroop29/nemoclaw/discussions)

<br/>

*Stop paying per token. Start owning your AI.*

**[⬆ Back to Top](#-nemoclaw)**

</div>
