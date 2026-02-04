# NemoClaw Quick Reference Cheat Sheet

A quick reference for common NemoClaw commands and information.

---

## SSH Connection

```bash
ssh -i ~/.ssh/nemoclaw-key.pem ec2-user@YOUR_EC2_IP
```

---

## Service Management

**Check status:** `sudo systemctl status nemoclaw`

**Start server:** `sudo systemctl start nemoclaw`

**Stop server:** `sudo systemctl stop nemoclaw`

**Restart server:** `sudo systemctl restart nemoclaw`

**Enable auto-start:** `sudo systemctl enable nemoclaw`

**Disable auto-start:** `sudo systemctl disable nemoclaw`

---

## Viewing Logs

**Live logs:** `sudo journalctl -u nemoclaw -f`

**Last 100 lines:** `sudo journalctl -u nemoclaw -n 100`

**Logs from today:** `sudo journalctl -u nemoclaw --since today`

**Logs from last hour:** `sudo journalctl -u nemoclaw --since "1 hour ago"`

---

## Health Checks

**API responding:** `curl http://localhost:8001/v1/models`

**GPU status:** `nvidia-smi`

**Service status:** `sudo systemctl status nemoclaw`

**Disk space:** `df -h`

**Memory usage:** `free -h`

---

## API Testing

**List models:**
```bash
curl http://localhost:8001/v1/models
```

**Chat completion:**
```bash
curl http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

**With custom parameters:**
```bash
curl http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron",
    "messages": [{"role": "user", "content": "Write a poem about coding"}],
    "temperature": 0.7,
    "max_tokens": 500
  }'
```

---

## Important Paths

**Model file:** `~/models/Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf`

**llama.cpp:** `~/llama.cpp/`

**Server binary:** `~/llama.cpp/build/bin/llama-server`

**Service file:** `/etc/systemd/system/nemoclaw.service`

---

## Specifications

**Model:** Nemotron 3 Nano 30B

**Parameters:** 31.58B total, 3.5B active

**Quantization:** Q4_K_XL (4-bit)

**Model size:** 21.3 GB

**Max context:** 1,048,576 tokens

**Default context:** 32,768 tokens

**Inference speed:** ~120 tokens/sec

**GPU memory used:** ~21.5 GB

---

## Cost Reference

**1 hr/day (30 hrs/month):** ~$38

**2 hr/day (60 hrs/month):** ~$68

**4 hr/day (120 hrs/month):** ~$129

**24/7 (720 hrs/month):** ~$733

Note: Includes ~$8/month for 100GB storage.

---

## Emergency Commands

**Kill stuck process:**
```bash
sudo pkill -9 llama-server
```

**Full service reset:**
```bash
sudo systemctl stop nemoclaw
sudo pkill -9 llama-server
sudo systemctl start nemoclaw
```

**Manual server start (for debugging):**
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

---

## Don't Forget!

**Stop your EC2 instance when not in use to save money!**

AWS Console → EC2 → Instances → Select instance → Instance state → Stop instance
