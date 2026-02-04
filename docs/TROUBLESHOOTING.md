# Troubleshooting Guide 🔧

This guide covers common issues you might encounter when setting up or running NemoClaw. Each section includes symptoms, causes, and step-by-step solutions.

---

## Quick Diagnostics

Before diving into specific issues, run these commands to gather system information:

```bash
# Check if NemoClaw is running
sudo systemctl status nemoclaw

# View recent logs
sudo journalctl -u nemoclaw -n 50

# Check GPU status
nvidia-smi

# Check disk space
df -h

# Check memory
free -h

# Test API locally
curl http://localhost:8001/v1/models
```

---

## Connection Issues

### SSH Connection Timeout

**Symptom:**
```
ssh: connect to host XX.XX.XX.XX port 22: Operation timed out
```

**Common Causes:**

This usually happens because your IP address has changed. Most home internet connections use dynamic IPs that change periodically. When your IP changes, the security group blocks your connection since it's configured to only allow your previous IP.

**Solution:**

First, find your current public IP by visiting https://whatismyip.com. Then go to the AWS Console, navigate to EC2, then Security Groups, and find your `nemoclaw-sg` security group. Edit the inbound rules and update the SSH rule's source to your current IP address (or select "My IP" which auto-detects it). Save the rules and try connecting again.

If the instance isn't running, go to EC2, then Instances, select your instance, and check if the state is "Running". If it's stopped, start it and note the new public IP address since EC2 instances get new public IPs each time they start.

---

### SSH Permission Denied

**Symptom:**
```
Permission denied (publickey,gssapi-keyex,gssapi-with-mic)
```

**Common Causes:**

This typically means the SSH key file has incorrect permissions, you're using the wrong key file, or you're using the wrong username.

**Solution:**

First, fix the key file permissions. The private key must be readable only by you:

```bash
chmod 400 ~/.ssh/nemoclaw-key.pem
```

Make sure you're using the correct username. For Amazon Linux 2023, the username is `ec2-user`:

```bash
ssh -i ~/.ssh/nemoclaw-key.pem ec2-user@YOUR_IP
```

If you're still having trouble, verify you're using the same key pair that was selected when launching the instance. You can check this in the EC2 console under the instance details.

---

### Cannot Connect to API (Port 8001)

**Symptom:**
```
curl: (7) Failed to connect to XX.XX.XX.XX port 8001: Connection refused
```

**Common Causes:**

This happens when the security group doesn't allow traffic on port 8001, the NemoClaw service isn't running, or the server is still loading the model.

**Solution:**

First, check if the security group allows port 8001. Go to EC2, then Security Groups, select `nemoclaw-sg`, and verify there's an inbound rule for Custom TCP on port 8001 from your IP. If not, add it.

Next, SSH into the instance and check if NemoClaw is running:

```bash
sudo systemctl status nemoclaw
```

If it's not running, start it:

```bash
sudo systemctl start nemoclaw
```

The model takes 60-90 seconds to load after the service starts. Watch the logs to see when it's ready:

```bash
sudo journalctl -u nemoclaw -f
```

Look for the message "server is listening on http://0.0.0.0:8001" which indicates the server is ready to accept requests.

---

## Installation Issues

### CUDA Toolkit Installation Fails

**Symptom:**
```
Error: Unable to find a match: cuda-toolkit-12-4
```

**Solution:**

The NVIDIA repository might not have been added correctly. Try adding it manually:

```bash
sudo dnf config-manager --add-repo \
    https://developer.download.nvidia.com/compute/cuda/repos/amzn2023/x86_64/cuda-amzn2023.repo
sudo dnf clean all
sudo dnf makecache
sudo dnf install -y cuda-toolkit-12-4
```

If you're on Ubuntu instead of Amazon Linux, use the appropriate repository:

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-4
```

---

### llama.cpp Build Fails

**Symptom:**
```
CMake Error: CUDA Toolkit not found
```

**Solution:**

The CUDA environment variables aren't set. Set them explicitly before building:

```bash
export CUDA_HOME=/usr/local/cuda-12.4
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Now rebuild
cd ~/llama.cpp
rm -rf build
mkdir build && cd build
cmake .. -DGGML_CUDA=ON -DCUDAToolkit_ROOT=/usr/local/cuda-12.4
cmake --build . --config Release -j$(nproc)
```

---

### Model Download Interrupted

**Symptom:** The download stopped partway through, or the model file is smaller than expected (should be ~21GB).

**Solution:**

Delete the incomplete file and restart the download:

```bash
cd ~/models
rm -f Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf

# Resume download (wget can resume interrupted downloads)
wget -c -O Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf \
    "https://huggingface.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF/resolve/main/Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf"
```

Verify the downloaded file size:

```bash
ls -lh ~/models/
# Should show approximately 21GB
```

---

## Server Issues

### Service Won't Start

**Symptom:**
```
● nemoclaw.service - NemoClaw - Nemotron Inference Server
     Active: failed (Result: exit-code)
```

**Solution:**

Check the detailed logs to understand what went wrong:

```bash
sudo journalctl -u nemoclaw -n 100 --no-pager
```

Common causes include the model file not existing (verify with `ls -la ~/models/`), incorrect paths in the service file, or insufficient GPU memory.

If the model file is missing or corrupted, re-download it. If paths are wrong, edit the service file:

```bash
sudo nano /etc/systemd/system/nemoclaw.service
# Verify all paths point to correct locations
sudo systemctl daemon-reload
sudo systemctl start nemoclaw
```

---

### "Loading Model" Error Persists

**Symptom:** The API keeps returning `{"error":{"message":"Loading model"}}` for more than 3 minutes.

**Solution:**

The model loading might have stalled. Check the logs for errors:

```bash
sudo journalctl -u nemoclaw -f
```

If you see memory-related errors, the model might not fit. The A10G has 24GB VRAM and the model uses about 21.5GB, leaving limited headroom. Try reducing the context size:

```bash
sudo nano /etc/systemd/system/nemoclaw.service
# Change -c 32768 to -c 16384 or -c 8192
sudo systemctl daemon-reload
sudo systemctl restart nemoclaw
```

---

### CUDA Out of Memory

**Symptom:**
```
CUDA out of memory. Tried to allocate X MiB.
```

**Solution:**

This happens when you try to use a context size that's too large for the remaining GPU memory. The model uses ~21.5GB, leaving about 2.5GB on a 24GB card.

Reduce the context size in the service configuration:

```bash
sudo nano /etc/systemd/system/nemoclaw.service
# Find the line with -c 32768
# Change to -c 16384 or -c 8192
sudo systemctl daemon-reload
sudo systemctl restart nemoclaw
```

Also check if other processes are using GPU memory:

```bash
nvidia-smi
```

Kill any unnecessary processes using GPU memory, or reboot the instance to clear everything.

---

## OpenClaw Integration Issues

### OpenClaw Can't Connect to NemoClaw

**Symptom:** OpenClaw shows connection errors or the bot doesn't respond on Telegram.

**Solution:**

First verify NemoClaw is accessible from your local machine:

```bash
curl http://YOUR_EC2_IP:8001/v1/models
```

If this times out, check your security group settings and your current IP address.

If the curl works but OpenClaw doesn't, check your OpenClaw configuration file at `~/.openclaw/openclaw.json`. Make sure you have the correct structure:

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
            "name": "Nemotron 3 Nano",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
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

Common mistakes include forgetting `/v1` at the end of the baseUrl, using `https` instead of `http`, having a trailing slash, or using incorrect provider name in the model primary field.

After fixing, restart OpenClaw:

```bash
openclaw gateway restart
```

---

### Slow Response Times

**Symptom:** The bot takes a long time to respond, much longer than expected.

**Solution:**

Some delay is normal due to network latency (your message travels from your phone to Telegram to your Mac to AWS and back). However, if responses are extremely slow:

Check GPU utilization during inference:

```bash
nvidia-smi -l 1  # Updates every second
```

During generation, GPU utilization should spike. If it stays at 0%, the model might not be using the GPU correctly.

Verify all layers are on GPU by checking the logs:

```bash
sudo journalctl -u nemoclaw | grep "offloaded"
# Should show: offloaded 53/53 layers to GPU
```

If network latency is the issue, consider whether your EC2 region is geographically far from you. Launching in a closer region could help.

---

## Cost Issues

### Unexpected High AWS Bill

**Solution:**

Remember that g5.xlarge costs ~$1/hour when running! If you left it running for a month, that's ~$730.

Always stop your instance when not in use:

AWS Console → EC2 → Instances → Select instance → Instance state → Stop instance

Set up billing alerts to get notified before costs get too high. Go to AWS Budgets and create a budget alert for your expected monthly spend.

The EBS storage (~$8/month for 100GB) continues to charge even when the instance is stopped. This is normal and expected since your data persists.

---

## Getting More Help

If you've tried the solutions in this guide and are still stuck, you can open an issue at https://github.com/Omsatyaswaroop29/nemoclaw/issues. When reporting issues, please include the exact error message, output of `sudo systemctl status nemoclaw`, relevant log lines from `sudo journalctl -u nemoclaw -n 50`, output of `nvidia-smi`, your AWS region and instance type, and what you were doing when the error occurred.
