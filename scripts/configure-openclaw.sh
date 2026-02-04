#!/bin/bash

# NemoClaw - OpenClaw Configuration Helper
# Automatically configures OpenClaw to use your local NemoClaw backend

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}NemoClaw - OpenClaw Configuration${NC}"
echo ""

# Find OpenClaw config file
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"

if [ ! -f "$OPENCLAW_CONFIG" ]; then
    echo -e "${YELLOW}OpenClaw config not found at $OPENCLAW_CONFIG${NC}"
    echo ""
    echo "Is OpenClaw installed? If not, install it with:"
    echo -e "  ${CYAN}npm install -g openclaw@latest${NC}"
    echo -e "  ${CYAN}openclaw onboard --install-daemon${NC}"
    echo ""
    
    read -p "Create a new config file? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$HOME/.openclaw"
        echo '{}' > "$OPENCLAW_CONFIG"
    else
        exit 1
    fi
fi

# Check if NemoClaw is running
echo -e "${BLUE}Checking NemoClaw server...${NC}"

if curl -s http://localhost:8001/health > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} NemoClaw is running on port 8001"
else
    echo -e "${YELLOW}  ⚠ NemoClaw doesn't appear to be running${NC}"
    echo "  Start it with: docker compose up -d"
    echo ""
    read -p "Continue with configuration anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Backup existing config
BACKUP_FILE="$OPENCLAW_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
cp "$OPENCLAW_CONFIG" "$BACKUP_FILE"
echo -e "  ${GREEN}✓${NC} Backed up existing config to $BACKUP_FILE"

# Check if jq is available for JSON manipulation
if command -v jq &> /dev/null; then
    # Use jq for clean JSON manipulation
    UPDATED_CONFIG=$(jq '. + {
        "agent": {
            "model": "nemoclaw/nemotron-3-nano",
            "modelEndpoint": "http://localhost:8001/v1",
            "maxTokens": 4096,
            "temperature": 0.7
        }
    }' "$OPENCLAW_CONFIG")
    
    echo "$UPDATED_CONFIG" > "$OPENCLAW_CONFIG"
else
    # Fallback: Create a simple config if jq not available
    echo -e "${YELLOW}jq not found, creating minimal config...${NC}"
    cat > "$OPENCLAW_CONFIG" << 'EOF'
{
  "agent": {
    "model": "nemoclaw/nemotron-3-nano",
    "modelEndpoint": "http://localhost:8001/v1",
    "maxTokens": 4096,
    "temperature": 0.7
  }
}
EOF
fi

echo -e "  ${GREEN}✓${NC} Updated OpenClaw configuration"

# Show the configuration
echo ""
echo -e "${BLUE}Current OpenClaw configuration:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
cat "$OPENCLAW_CONFIG"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}Configuration complete!${NC}"
echo ""
echo "OpenClaw will now use your local NemoClaw backend."
echo ""
echo "Test it by sending a message through OpenClaw."
echo ""
echo -e "To revert to cloud API, restore from backup:"
echo -e "  ${CYAN}cp $BACKUP_FILE $OPENCLAW_CONFIG${NC}"
