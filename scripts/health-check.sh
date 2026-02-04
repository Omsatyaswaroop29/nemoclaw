#!/bin/bash

# NemoClaw Health Check Script
# Monitors the status of your local inference server

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

NEMOCLAW_URL="${NEMOCLAW_URL:-http://localhost:8001}"

echo -e "${CYAN}NemoClaw Health Check${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check 1: Is Docker container running?
echo -e "${BLUE}[1/4] Docker Container Status${NC}"
if docker ps --format '{{.Names}}' | grep -q "nemoclaw"; then
    CONTAINER_STATUS=$(docker ps --filter "name=nemoclaw" --format "{{.Status}}")
    echo -e "  ${GREEN}✓${NC} Container running: $CONTAINER_STATUS"
else
    echo -e "  ${RED}✗${NC} Container not running"
    echo "  Start with: docker compose up -d"
    exit 1
fi

# Check 2: Is the health endpoint responding?
echo ""
echo -e "${BLUE}[2/4] Health Endpoint${NC}"
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$NEMOCLAW_URL/health" 2>/dev/null || echo "000")

if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo -e "  ${GREEN}✓${NC} Health endpoint responding (HTTP $HEALTH_RESPONSE)"
else
    echo -e "  ${RED}✗${NC} Health endpoint not responding (HTTP $HEALTH_RESPONSE)"
    echo "  The model may still be loading. Check logs: docker compose logs -f"
    exit 1
fi

# Check 3: Can we get model info?
echo ""
echo -e "${BLUE}[3/4] Model Information${NC}"
MODEL_INFO=$(curl -s "$NEMOCLAW_URL/v1/models" 2>/dev/null)

if echo "$MODEL_INFO" | grep -q "data"; then
    MODEL_NAME=$(echo "$MODEL_INFO" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "  ${GREEN}✓${NC} Model loaded: ${CYAN}$MODEL_NAME${NC}"
else
    echo -e "  ${YELLOW}⚠${NC} Could not retrieve model info"
fi

# Check 4: Test inference
echo ""
echo -e "${BLUE}[4/4] Inference Test${NC}"
echo -e "  Sending test prompt..."

START_TIME=$(date +%s%N)
TEST_RESPONSE=$(curl -s "$NEMOCLAW_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "nemotron-3-nano",
        "messages": [{"role": "user", "content": "Say hello in exactly 3 words."}],
        "max_tokens": 20
    }' 2>/dev/null)
END_TIME=$(date +%s%N)

# Calculate latency in milliseconds
LATENCY=$(( (END_TIME - START_TIME) / 1000000 ))

if echo "$TEST_RESPONSE" | grep -q "choices"; then
    RESPONSE_TEXT=$(echo "$TEST_RESPONSE" | grep -o '"content":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "  ${GREEN}✓${NC} Inference working"
    echo -e "  Response: ${CYAN}$RESPONSE_TEXT${NC}"
    echo -e "  Latency: ${CYAN}${LATENCY}ms${NC}"
else
    echo -e "  ${RED}✗${NC} Inference test failed"
    echo "  Response: $TEST_RESPONSE"
    exit 1
fi

# Summary
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}All checks passed! NemoClaw is healthy.${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "API Endpoint: $NEMOCLAW_URL/v1/chat/completions"
echo ""

# GPU stats if available
if command -v nvidia-smi &> /dev/null; then
    echo -e "${BLUE}GPU Status:${NC}"
    nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader
fi
