# Troubleshooting Guide for NemoClaw

This guide covers common issues you may encounter when setting up or running NemoClaw, along with detailed solutions.

---

## Connection Issues

### SSH Connection Timeout

**Symptom:**
```
ssh: connect to host XX.XX.XX.XX port 22: Operation timed out
```

**Solutions:**

**Your IP address has changed.** Your home or office IP address can change, especially if you're on a residential internet connection. When this happens, the security group blocks your connection. Visit https://whatismyip.com to find your current IP, then update your security group inbound rules with your new IP address.

**Instance is not running.** Check the EC2 console to verify the instance state shows "Running" with a green indicator. If it's stopped, select the instance and choose Instance state and then Start instance.

**Wrong IP address.** EC2 public IP addresses change every time you stop and start an instance. Get the current Public IPv4 address from the EC2 console instance details page.

---

### SSH Permission Denied

**Symptom:**
```
Permission denied (publickey,gssapi-keyex,gssapi-with-mic)
```

**Solutions:**

**Wrong key file permissions.** SSH requires that your private key file has restrictive permissions. Fix the permissions by running:

```bash
chmod 400 ~/.ssh/nemoclaw-key.pem
```

**Wrong username.** Amazon Linux 2023 uses "ec2-user" as the default username. Make sure you're using the correct command:

```bash
ssh -i ~/.ssh/nemoclaw-key.pem ec2-user@YOUR_IP
```

**Wrong key file.** Verify you're using the key pair that was selected when launching the instance. You can check which key pair is associated with the instance in the EC2 console under the instance details.

---

### Cannot Connect to API Port 8001

**Symptom:**
```
curl: (7) Failed to connect to XX.XX.XX.XX port 8001: Connection refused
```

**Solutions:**

**Security group doesn't allow port 8001.** Go to EC2, then Security Groups, select nemoclaw-sg, and verify there's an inbound rule for Custom TCP on port 8001 from your IP. If not, add it.

**NemoClaw service isn't running.** SSH into the instance and check the service status:

```bash
sudo systemctl status nemoclaw
```

If it's not running, start it:

```bash
sudo systemctl start nemoclaw
```

**Server is still loading the model.** The 21GB model takes 60-90 seconds to load into GPU memory after the service starts. Wait a couple of minutes after starting the service, then try again. You can monitor the loading progress by watching the logs:

```bash
sudo journalctl -u nemoclaw -f
```

Look for the message "server is listening on http://0.0.0.0:8001" which indicates the server is ready.

---

## Installation Issues

### CUDA Toolkit Installation Fails

**Symptom:**
```
Error: Unable to find a match: cuda-toolkit-12-4
```

**Solution:**

The NVIDIA repository might not have been added correctly. Run these commands manually:

```bash
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/amzn2023/x86_64/cuda-amzn2023.repo
sudo dnf clean all
sudo dnf install -y cuda-toolkit-12-4
```

---

### llama.cpp Build Fails with CMake Errors

**Symptom:**
```
CMake Error: CUDA Toolkit not found
```

**Solution:**

The CUDA environment variables aren't set. Set them explicitly before building:

```bash
export CUDA_HOME=/usr/local/cuda-12.4
export PATH=$CUDA_HOME/bin:$PATH

cd ~/llama.cpp/build
rm -rf *

cmake .. -DGGML_CUDA=ON -DCUDAToolkit_ROOT=/usr/local/cuda-12.4
cmake --build . --config Release -j4
```

---

### Model Download Fails or Is Incomplete

**Symptom:** The download stops partway through, or the file size is smaller than expected (should be approximately 21GB).

**Solution:**

Delete the incomplete file and restart the download:

```bash
cd ~/models
rm -f Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf

wget -O Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf "https://huggingface.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF/resolve/main/Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf"
```

---

## Server Startup Issues

### Service Fails to Start

**Symptom:**
```
● nemoclaw.service - NemoClaw - Nemotron Inference Server
     Active: failed (Result: exit-code)
```

**Solution:**

Check the detailed logs to see what went wrong:

```bash
sudo journalctl -u nemoclaw -n 100
```

Verify the model file exists and has the correct size:

```bash
ls -la ~/models/Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf
```

The file should be approximately 21GB (around 22,833,947,424 bytes). If it's significantly smaller, the download was incomplete.

---

### "Loading Model" Error Persists

**Symptom:** The API returns `{"error":{"message":"Loading model"}}` for more than 2-3 minutes.

**Solution:**

The model loading might have stalled. Check the logs for errors:

```bash
sudo journalctl -u nemoclaw -f
```

If you see errors related to memory or CUDA, restart the service:

```bash
sudo systemctl restart nemoclaw
```

If the problem persists, try running the server manually to see detailed output:

```bash
sudo systemctl stop nemoclaw

cd ~/llama.cpp/build/bin
./llama-server \
  -m ~/models/Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf \
  --host 0.0.0.0 \
  --port 8001 \
  -ngl 99 \
  -c 32768
```

Watch the output for any error messages that indicate what's failing.

---

### CUDA Out of Memory

**Symptom:**
```
CUDA out of memory. Tried to allocate X MiB.
```

**Solution:**

The context size is too large for the available GPU memory. The A10G has 24GB, and the model uses about 21.5GB, leaving limited room for context.

Reduce the context size in the service file:

```bash
sudo nano /etc/systemd/system/nemoclaw.service
```

Find the ExecStart line and change `-c 32768` to `-c 16384` or even `-c 8192`. Then reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart nemoclaw
```

Also check if other processes are using GPU memory:

```bash
nvidia-smi
```

Kill any processes that shouldn't be running on the GPU.

---

## Performance Issues

### Slow Inference Speed

**Symptom:** Responses are much slower than the expected 120+ tokens per second.

**Solution:**

First, verify that the model is running on the GPU, not CPU:

```bash
nvidia-smi
```

During inference, you should see GPU utilization increase. If GPU-Util stays at 0%, the model might be running on CPU instead.

Check the logs to verify all layers were offloaded to GPU:

```bash
sudo journalctl -u nemoclaw | grep "offloaded"
```

You should see "offloaded 53/53 layers to GPU". If fewer layers are offloaded, the `-ngl` parameter might not be set correctly.

---

## API Issues

### Invalid JSON Response

**Symptom:** The API returns malformed JSON or the response is cut off.

**Solution:**

This can happen if the max_tokens parameter is set too low. Increase max_tokens in your request:

```bash
curl http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 1000
  }'
```

---

## OpenClaw Integration Issues

### OpenClaw Can't Connect to NemoClaw

**Symptom:** OpenClaw shows connection errors when trying to use the NemoClaw backend.

**Solution:**

First, test that NemoClaw is accessible from your local machine:

```bash
curl http://YOUR_EC2_IP:8001/v1/models
```

If this works, the issue is likely in the OpenClaw configuration. Check your config file at `~/.openclaw/config.json` and ensure it matches this structure:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "provider": "openai-compatible",
        "baseUrl": "http://YOUR_EC2_IP:8001/v1",
        "model": "nemotron",
        "apiKey": "not-needed"
      }
    }
  }
}
```

Common mistakes include forgetting the `/v1` at the end of the baseUrl, using `https` instead of `http`, or having a trailing slash.

---

## Getting Help

If you've tried the solutions in this guide and are still experiencing issues, here's how to get additional help.

### Information to Include When Asking for Help

When reporting an issue, include the exact error message or symptom, the output of `sudo systemctl status nemoclaw`, relevant log lines from `sudo journalctl -u nemoclaw -n 50`, the output of `nvidia-smi`, your AWS region and instance type, and any recent changes you made before the issue started.

### Where to Get Help

Open an issue at https://github.com/Omsatyaswaroop29/nemoclaw/issues with the information listed above.
