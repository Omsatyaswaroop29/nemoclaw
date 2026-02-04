# Changelog

All notable changes to NemoClaw will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-02-04

### 🎉 Initial Release

The first public release of NemoClaw — a self-hosted AI inference backend for OpenClaw.

### Added

**Core Features**
- One-command installer script with progress indicators and error handling
- Automated CUDA Toolkit 12.4 installation
- Automated llama.cpp compilation with CUDA support
- Automatic download of Nemotron 3 Nano 30B (Q4_K_XL quantization)
- Systemd service with auto-start on boot and crash recovery
- OpenAI-compatible REST API on port 8001

**Documentation**
- Comprehensive README with architecture diagrams
- Step-by-step AWS Setup Guide
- Troubleshooting guide covering 15+ common issues
- Quick reference cheat sheet
- OpenClaw integration guide with full configuration examples

**Configuration**
- Example systemd service file with security hardening
- Example OpenClaw configuration for easy integration
- Configurable context size (default 32K, max 1M tokens)
- Configurable GPU layer offloading

### Performance

Benchmarks on AWS g5.xlarge (NVIDIA A10G, 24GB VRAM):

| Metric | Value |
|--------|-------|
| Generation Speed | 120+ tokens/sec |
| Prompt Processing | 85+ tokens/sec |
| Time to First Token | ~200ms |
| Model Load Time | ~90 seconds |
| GPU Memory Usage | 21.5GB / 24GB |

### Compatibility

- **Operating Systems:** Amazon Linux 2023, Ubuntu 22.04
- **GPU Requirements:** NVIDIA A10G (24GB+), RTX 4090, A100
- **OpenClaw Versions:** 2026.2.x and later

---

## [Unreleased]

### Planned Features

- Docker containerization for easier deployment
- Terraform/CloudFormation infrastructure templates
- Multi-model support (hot-swap different models)
- Web dashboard for monitoring and configuration
- GCP and Azure deployment guides
- Automatic cost estimation and alerts
- Model performance comparison benchmarks

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to propose changes and submit pull requests.

## Questions?

- **Bug reports:** [Open an issue](https://github.com/Omsatyaswaroop29/nemoclaw/issues)
- **Feature requests:** [Start a discussion](https://github.com/Omsatyaswaroop29/nemoclaw/discussions)
- **General help:** Join the [OpenClaw Discord](https://discord.gg/openclaw)
