# NemoClaw Hardware Requirements

This guide helps you understand what hardware you need to run NemoClaw and what performance to expect.

## Understanding the Requirements

Running large language models locally requires significant GPU memory (VRAM). The Nemotron 3 Nano model has 30 billion parameters, and each parameter needs to be stored in memory during inference. The amount of VRAM you need depends on the precision (format) of the model weights.

At full BF16 precision, each parameter uses 2 bytes, so the model requires roughly 60GB just for the weights. That's why we use quantization for consumer GPUs. Quantization reduces the precision of the weights (from 16-bit to 4-bit or 8-bit), which dramatically reduces memory requirements at the cost of slightly lower quality.

## Recommended Configurations

### Tier 1: Best Experience (24GB+ VRAM)

GPUs in this tier include the NVIDIA RTX 4090, RTX 3090, A100, and professional cards like the A6000.

With 24GB of VRAM, you can run Nemotron 3 Nano with vLLM using optimizations like tensor parallelism and efficient attention. The vLLM backend provides the fastest inference speeds and best compatibility with OpenClaw's tool calling features.

Expected performance on an RTX 4090:
- First token latency: 400-600ms
- Generation speed: 40-60 tokens per second
- Maximum context: 128K tokens comfortably, up to 256K with reduced batch size

This tier provides a "cloud-like" experience where the local model feels as responsive as an API call.

### Tier 2: Good Experience (16-20GB VRAM)

GPUs in this tier include the NVIDIA RTX 4080 (16GB), RTX 4080 Super (16GB), and RTX A4000 (16GB).

With 16GB of VRAM, you'll run a quantized version of the model (Q4_K_XL or Q5_K_M) using llama.cpp. Quantization reduces the model's memory footprint by storing weights in 4-bit or 5-bit format instead of 16-bit.

Expected performance on an RTX 4080:
- First token latency: 800-1200ms
- Generation speed: 25-40 tokens per second
- Maximum context: 32K tokens comfortably, up to 64K with some slowdown

This tier is perfectly usable for most tasks. You'll notice slightly longer response times compared to cloud APIs, but it's still practical for daily use.

### Tier 3: Functional (12GB VRAM)

GPUs in this tier include the NVIDIA RTX 4070 Ti (12GB), RTX 3080 (12GB), and similar cards.

With 12GB of VRAM, you'll need aggressive quantization (Q4_K_M or Q4_K_S) and reduced context lengths. This is at the edge of what's practical for Nemotron 3 Nano specifically.

Expected performance on an RTX 4070 Ti:
- First token latency: 1000-1500ms
- Generation speed: 15-25 tokens per second
- Maximum context: 8K-16K tokens

This tier works but involves tradeoffs. Consider smaller models (7B-14B parameters) if your primary concern is responsiveness rather than capability.

### Not Recommended (<12GB VRAM)

GPUs with less than 12GB VRAM (RTX 4060, RTX 3070, GTX series) cannot run Nemotron 3 Nano effectively. The model simply won't fit in memory even with aggressive quantization while maintaining reasonable context length.

If you have less than 12GB VRAM, consider running a smaller model like Llama 3 8B or Mistral 7B. These provide good capabilities and fit comfortably in 8GB VRAM.

## Other Hardware Considerations

### CPU

While inference happens on the GPU, the CPU handles tokenization, scheduling, and other overhead. Any modern multi-core CPU (Intel 10th gen or newer, AMD Ryzen 3000 series or newer) works fine. You don't need a high-end CPU for local inference.

### System RAM

You should have at least 32GB of system RAM. While the model runs on GPU memory, the system still needs RAM for the operating system, Docker, and data processing. 16GB is the absolute minimum and may cause issues with longer contexts.

### Storage

The model files are large. The full BF16 model is approximately 60GB. Quantized GGUF files range from 15GB (Q4) to 30GB (Q8). You should have at least 100GB of free space on an SSD (not HDD) for model storage and Docker operations.

An NVMe SSD provides faster model loading times compared to SATA SSDs. Model loading is a one-time operation at startup, so this mainly affects how quickly you can restart NemoClaw.

### Power Supply

High-end GPUs like the RTX 4090 can draw 450W or more under load. Ensure your power supply can handle your GPU's requirements plus headroom for the rest of your system. A quality 850W+ PSU is recommended for RTX 4090 setups.

### Cooling

Extended inference sessions generate significant heat. Ensure your case has adequate airflow and your GPU cooling is working properly. Throttling due to heat will reduce inference speed.

## Apple Silicon

Apple Silicon Macs (M1, M2, M3 series) can run local LLMs using MLX, Apple's machine learning framework. However, NemoClaw currently focuses on NVIDIA GPUs.

If you're on Apple Silicon, consider using LM Studio or Ollama directly with Nemotron or other models. A future version of NemoClaw may include MLX support.

The M2 Max and M3 Max with 64GB+ unified memory can run larger models effectively. The M2 Pro/M3 Pro with 32GB can run quantized versions of Nemotron 3 Nano, though performance will be slower than NVIDIA GPUs.

## Cloud GPU Options

If you don't have a suitable local GPU, you can rent cloud GPU instances:

RunPod offers RTX 4090 instances starting around $0.40/hour. This is cost-effective for occasional use.

Lambda Labs provides A100 instances for more demanding workloads.

Vast.ai has a marketplace model with competitive pricing for longer-term rentals.

You can run NemoClaw on these cloud instances and access them remotely. This provides a middle ground between local hardware investment and monthly API subscriptions.

## Checking Your Hardware

Run this command to see your GPU information:

```bash
nvidia-smi
```

This shows your GPU model, total VRAM, current usage, and driver version. Make sure you have the latest NVIDIA drivers installed for best compatibility and performance.
