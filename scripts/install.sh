#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                       ║
# ║   ███╗   ██╗███████╗███╗   ███╗ ██████╗  ██████╗██╗      █████╗ ██╗    ██╗           ║
# ║   ████╗  ██║██╔════╝████╗ ████║██╔═══██╗██╔════╝██║     ██╔══██╗██║    ██║           ║
# ║   ██╔██╗ ██║█████╗  ██╔████╔██║██║   ██║██║     ██║     ███████║██║ █╗ ██║           ║
# ║   ██║╚██╗██║██╔══╝  ██║╚██╔╝██║██║   ██║██║     ██║     ██╔══██║██║███╗██║           ║
# ║   ██║ ╚████║███████╗██║ ╚═╝ ██║╚██████╔╝╚██████╗███████╗██║  ██║╚███╔███╔╝           ║
# ║   ╚═╝  ╚═══╝╚══════╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝            ║
# ║                                                                                       ║
# ║                    🦞 Self-Hosted AI Inference for OpenClaw 🦞                        ║
# ║                                                                                       ║
# ║   Automated deployment script for Nemotron 3 Nano inference server                   ║
# ║   Designed for AWS EC2 g5.xlarge with Amazon Linux 2023                              ║
# ║                                                                                       ║
# ║   Repository: https://github.com/Omsatyaswaroop29/nemoclaw                           ║
# ║   License: MIT                                                                        ║
# ║                                                                                       ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════╝

set -e  # Exit immediately if a command exits with a non-zero status

# ============================================================================
# CONFIGURATION VARIABLES
# ============================================================================
# These can be modified if you need to customize the installation

CUDA_VERSION="12-4"
CUDA_HOME="/usr/local/cuda-12.4"
MODEL_URL="https://huggingface.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF/resolve/main/Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf"
MODEL_NAME="Nemotron-3-Nano-30B-A3B-UD-Q4_K_XL.gguf"
MODEL_DIR="$HOME/models"
LLAMA_CPP_DIR="$HOME/llama.cpp"
SERVER_PORT="8001"
CONTEXT_SIZE="32768"
GPU_LAYERS="99"

# ============================================================================
# TERMINAL COLORS AND FORMATTING
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_banner() {
    echo ""
    echo -e "${PURPLE}"
    echo "  ███╗   ██╗███████╗███╗   ███╗ ██████╗  ██████╗██╗      █████╗ ██╗    ██╗"
    echo "  ████╗  ██║██╔════╝████╗ ████║██╔═══██╗██╔════╝██║     ██╔══██╗██║    ██║"
    echo "  ██╔██╗ ██║█████╗  ██╔████╔██║██║   ██║██║     ██║     ███████║██║ █╗ ██║"
    echo "  ██║╚██╗██║██╔══╝  ██║╚██╔╝██║██║   ██║██║     ██║     ██╔══██║██║███╗██║"
    echo "  ██║ ╚████║███████╗██║ ╚═╝ ██║╚██████╔╝╚██████╗███████╗██║  ██║╚███╔███╔╝"
    echo "  ╚═╝  ╚═══╝╚══════╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝ "
    echo -e "${NC}"
    echo ""
    echo -e "  ${CYAN}🦞 Self-Hosted AI Inference Server for OpenClaw${NC}"
    echo -e "  ${WHITE}Nemotron 3 Nano • 30B Parameters • 1M Token Context • 120+ tok/s${NC}"
    echo ""
    echo -e "  ${BLUE}GitHub: https://github.com/Omsatyaswaroop29/nemoclaw${NC}"
    echo ""
}

print_header() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║  $1${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}  ➜${NC} $1"
}

print_info() {
    echo -e "${BLUE}  ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}  ✔${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}  ⚠${NC} $1"
}

print_error() {
    echo -e "${RED}  ✖${NC} $1"
}

print_progress() {
    echo -e "${WHITE}  ⏳${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# SYSTEM CHECKS
# ============================================================================

check_system() {
    print_header "PHASE 0: System Compatibility Check"
    
    # Check if running on Linux
    print_step "Checking operating system..."
    if [[ "$(uname -s)" != "Linux" ]]; then
        print_error "This script only supports Linux systems."
        print_info "Recommended: Amazon Linux 2023 or Ubuntu 22.04"
        exit 1
    fi
    print_success "Linux detected: $(uname -r)"
    
    # Check for NVIDIA GPU
    print_step "Checking for NVIDIA GPU..."
    if ! command_exists nvidia-smi; then
        print_error "NVIDIA drivers not found!"
        print_info "Please use an AMI with pre-installed NVIDIA drivers."
        print_info "Recommended: Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.9 (Amazon Linux 2023)"
        exit 1
    fi
    
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1)
    GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -n1)
    print_success "GPU detected: $GPU_NAME ($GPU_MEMORY)"
    
    # Check GPU memory (need at least 24GB)
    GPU_MEM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1)
    if [[ $GPU_MEM_MB -lt 20000 ]]; then
        print_warning "GPU has less than 24GB VRAM. The model may not fit!"
        print_info "Recommended: NVIDIA A10G (24GB) or better"
    fi
    
    # Check available disk space (need at least 50GB)
    print_step "Checking disk space..."
    AVAILABLE_SPACE=$(df -BG /home | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $AVAILABLE_SPACE -lt 50 ]]; then
        print_error "Insufficient disk space!"
        print_info "Need at least 50GB, found ${AVAILABLE_SPACE}GB"
        print_info "The model alone is 21GB, plus llama.cpp and system files"
        exit 1
    fi
    print_success "Disk space available: ${AVAILABLE_SPACE}GB"
    
    # Check RAM
    print_step "Checking system memory..."
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    print_success "System RAM: ${TOTAL_RAM}GB"
    
    echo ""
    print_success "All system checks passed! Ready to install."
    echo ""
}

# ============================================================================
# PHASE 1: CUDA TOOLKIT INSTALLATION
# ============================================================================

install_cuda() {
    print_header "PHASE 1: CUDA Toolkit Installation"
    
    # Check if CUDA is already installed
    if [[ -d "$CUDA_HOME" ]] && [[ -f "$CUDA_HOME/bin/nvcc" ]]; then
        print_info "CUDA Toolkit already installed at $CUDA_HOME"
        NVCC_VERSION=$($CUDA_HOME/bin/nvcc --version | grep "release" | awk '{print $6}')
        print_success "CUDA version: $NVCC_VERSION"
        
        # Set environment variables
        export CUDA_HOME="$CUDA_HOME"
        export PATH="$CUDA_HOME/bin:$PATH"
        export LD_LIBRARY_PATH="$CUDA_HOME/lib64:$LD_LIBRARY_PATH"
        return 0
    fi
    
    print_step "Adding NVIDIA CUDA repository..."
    sudo dnf config-manager --add-repo \
        https://developer.download.nvidia.com/compute/cuda/repos/amzn2023/x86_64/cuda-amzn2023.repo
    print_success "Repository added"
    
    print_step "Installing CUDA Toolkit ${CUDA_VERSION}..."
    print_progress "This may take 5-10 minutes. Grab a coffee! ☕"
    sudo dnf install -y cuda-toolkit-${CUDA_VERSION} > /dev/null 2>&1
    print_success "CUDA Toolkit installed"
    
    print_step "Configuring environment variables..."
    export CUDA_HOME="$CUDA_HOME"
    export PATH="$CUDA_HOME/bin:$PATH"
    export LD_LIBRARY_PATH="$CUDA_HOME/lib64:$LD_LIBRARY_PATH"
    
    # Add to bashrc for persistence
    if ! grep -q "CUDA_HOME" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# ============================================" >> ~/.bashrc
        echo "# CUDA Configuration (added by NemoClaw)" >> ~/.bashrc
        echo "# ============================================" >> ~/.bashrc
        echo "export CUDA_HOME=$CUDA_HOME" >> ~/.bashrc
        echo "export PATH=\$CUDA_HOME/bin:\$PATH" >> ~/.bashrc
        echo "export LD_LIBRARY_PATH=\$CUDA_HOME/lib64:\$LD_LIBRARY_PATH" >> ~/.bashrc
    fi
    print_success "Environment configured"
    
    # Verify installation
    if [[ -f "$CUDA_HOME/bin/nvcc" ]]; then
        NVCC_VERSION=$($CUDA_HOME/bin/nvcc --version | grep "release" | awk '{print $6}')
        print_success "CUDA Toolkit ready: version $NVCC_VERSION"
    else
        print_error "CUDA installation verification failed!"
        exit 1
    fi
}

# ============================================================================
# PHASE 2: BUILD LLAMA.CPP WITH CUDA SUPPORT
# ============================================================================

build_llama_cpp() {
    print_header "PHASE 2: Building llama.cpp with CUDA Acceleration"
    
    # Check if already built
    if [[ -f "$LLAMA_CPP_DIR/build/bin/llama-server" ]]; then
        print_info "llama.cpp already built at $LLAMA_CPP_DIR"
        print_success "Skipping build step"
        return 0
    fi
    
    print_step "Cloning llama.cpp repository..."
    cd "$HOME"
    
    if [[ -d "$LLAMA_CPP_DIR" ]]; then
        print_info "Removing existing llama.cpp directory..."
        rm -rf "$LLAMA_CPP_DIR"
    fi
    
    git clone --depth 1 https://github.com/ggerganov/llama.cpp.git > /dev/null 2>&1
    print_success "Repository cloned"
    
    cd "$LLAMA_CPP_DIR"
    
    print_step "Creating build directory..."
    mkdir -p build
    cd build
    
    print_step "Configuring CMake with CUDA support..."
    cmake .. \
        -DGGML_CUDA=ON \
        -DCUDAToolkit_ROOT="$CUDA_HOME" \
        -DCMAKE_BUILD_TYPE=Release > /dev/null 2>&1
    print_success "CMake configured"
    
    print_step "Compiling llama.cpp..."
    NUM_CORES=$(nproc)
    print_progress "Using $NUM_CORES CPU cores for parallel compilation..."
    print_progress "This may take 3-5 minutes..."
    cmake --build . --config Release -j$NUM_CORES > /dev/null 2>&1
    
    # Verify build
    if [[ -f "$LLAMA_CPP_DIR/build/bin/llama-server" ]]; then
        print_success "llama.cpp built successfully!"
        print_info "Binary location: $LLAMA_CPP_DIR/build/bin/llama-server"
    else
        print_error "llama.cpp build failed!"
        print_info "Check build logs in $LLAMA_CPP_DIR/build"
        exit 1
    fi
}

# ============================================================================
# PHASE 3: DOWNLOAD THE MODEL
# ============================================================================

download_model() {
    print_header "PHASE 3: Downloading Nemotron 3 Nano Model"
    
    # Check if model already exists
    if [[ -f "$MODEL_DIR/$MODEL_NAME" ]]; then
        print_info "Model file found. Verifying..."
        MODEL_SIZE=$(stat -c%s "$MODEL_DIR/$MODEL_NAME" 2>/dev/null || stat -f%z "$MODEL_DIR/$MODEL_NAME" 2>/dev/null)
        # Expected size is approximately 21GB (22833947424 bytes)
        if [[ $MODEL_SIZE -gt 22000000000 ]]; then
            READABLE_SIZE=$(numfmt --to=iec $MODEL_SIZE 2>/dev/null || echo "${MODEL_SIZE} bytes")
            print_success "Model verified: $READABLE_SIZE"
            return 0
        else
            print_warning "Model file appears incomplete. Re-downloading..."
            rm -f "$MODEL_DIR/$MODEL_NAME"
        fi
    fi
    
    print_step "Creating models directory..."
    mkdir -p "$MODEL_DIR"
    cd "$MODEL_DIR"
    
    echo ""
    echo -e "  ${WHITE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${WHITE}║  Model: NVIDIA Nemotron 3 Nano 30B                         ║${NC}"
    echo -e "  ${WHITE}║  Quantization: Q4_K_XL (4-bit)                             ║${NC}"
    echo -e "  ${WHITE}║  Size: ~21 GB                                              ║${NC}"
    echo -e "  ${WHITE}║  Source: Hugging Face (Unsloth)                            ║${NC}"
    echo -e "  ${WHITE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_step "Downloading model..."
    print_progress "This is the longest step (~10-15 minutes depending on network speed)"
    print_info "Model URL: $MODEL_URL"
    echo ""
    
    # Download with wget showing progress
    wget --progress=bar:force:noscroll \
        -O "$MODEL_NAME" \
        "$MODEL_URL"
    
    echo ""
    
    # Verify download
    if [[ -f "$MODEL_DIR/$MODEL_NAME" ]]; then
        MODEL_SIZE=$(stat -c%s "$MODEL_DIR/$MODEL_NAME" 2>/dev/null || stat -f%z "$MODEL_DIR/$MODEL_NAME" 2>/dev/null)
        READABLE_SIZE=$(numfmt --to=iec $MODEL_SIZE 2>/dev/null || echo "${MODEL_SIZE} bytes")
        print_success "Model downloaded successfully!"
        print_info "File size: $READABLE_SIZE"
        print_info "Location: $MODEL_DIR/$MODEL_NAME"
    else
        print_error "Model download failed!"
        exit 1
    fi
}

# ============================================================================
# PHASE 4: CREATE SYSTEMD SERVICE
# ============================================================================

create_service() {
    print_header "PHASE 4: Creating Systemd Service"
    
    print_step "Creating NemoClaw service file..."
    
    sudo tee /etc/systemd/system/nemoclaw.service > /dev/null << EOF
# ============================================================================
# NemoClaw - Nemotron 3 Nano Inference Server
# https://github.com/Omsatyaswaroop29/nemoclaw
# ============================================================================

[Unit]
Description=NemoClaw - Nemotron 3 Nano Inference Server
Documentation=https://github.com/Omsatyaswaroop29/nemoclaw
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$LLAMA_CPP_DIR/build/bin

# Environment variables for CUDA
Environment="CUDA_HOME=$CUDA_HOME"
Environment="PATH=$CUDA_HOME/bin:/usr/local/bin:/usr/bin:/bin"
Environment="LD_LIBRARY_PATH=$CUDA_HOME/lib64"

# Server command with optimized settings
# -m: Model file path
# --host 0.0.0.0: Listen on all interfaces (allows external connections)
# --port: API server port
# -ngl 99: Offload all layers to GPU
# -c: Context size in tokens (can be increased up to 1048576)
ExecStart=$LLAMA_CPP_DIR/build/bin/llama-server \\
    -m $MODEL_DIR/$MODEL_NAME \\
    --host 0.0.0.0 \\
    --port $SERVER_PORT \\
    -ngl $GPU_LAYERS \\
    -c $CONTEXT_SIZE

# Restart policy
Restart=on-failure
RestartSec=10

# Give the server time to load the model (21GB takes a while)
TimeoutStartSec=300

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$HOME/.cache

[Install]
WantedBy=multi-user.target
EOF

    print_success "Service file created"
    
    print_step "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    print_success "Daemon reloaded"
    
    print_step "Enabling NemoClaw service (auto-start on boot)..."
    sudo systemctl enable nemoclaw > /dev/null 2>&1
    print_success "Service enabled"
}

# ============================================================================
# PHASE 5: START AND VERIFY
# ============================================================================

start_and_verify() {
    print_header "PHASE 5: Starting NemoClaw Server"
    
    print_step "Starting NemoClaw service..."
    sudo systemctl start nemoclaw
    
    echo ""
    echo -e "  ${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${YELLOW}║  ⏳ Loading model into GPU memory...                        ║${NC}"
    echo -e "  ${YELLOW}║  This takes 60-90 seconds for the 21GB model               ║${NC}"
    echo -e "  ${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Wait for server to be ready with a progress indicator
    MAX_WAIT=180  # Maximum wait time in seconds
    WAITED=0
    INTERVAL=5
    
    while [[ $WAITED -lt $MAX_WAIT ]]; do
        # Check if server is responding
        if curl -s http://localhost:$SERVER_PORT/v1/models > /dev/null 2>&1; then
            echo ""
            print_success "NemoClaw server is ready!"
            break
        fi
        
        # Show progress
        PROGRESS=$((WAITED * 100 / MAX_WAIT))
        BAR_LENGTH=40
        FILLED=$((PROGRESS * BAR_LENGTH / 100))
        EMPTY=$((BAR_LENGTH - FILLED))
        BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')
        
        printf "\r  ${WHITE}[${BAR}] ${PROGRESS}%% (${WAITED}s)${NC}"
        
        sleep $INTERVAL
        WAITED=$((WAITED + INTERVAL))
    done
    
    if [[ $WAITED -ge $MAX_WAIT ]]; then
        echo ""
        print_warning "Server took longer than expected to start."
        print_info "Check logs with: sudo journalctl -u nemoclaw -f"
        print_info "The server may still be loading..."
    fi
}

# ============================================================================
# PHASE 6: DISPLAY SUMMARY
# ============================================================================

display_summary() {
    # Get the public IP
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "YOUR_INSTANCE_IP")
    
    clear
    print_banner
    
    echo -e "${GREEN}"
    echo "  ╔═══════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                       ║"
    echo "  ║   🎉  INSTALLATION COMPLETE!  🎉                                      ║"
    echo "  ║                                                                       ║"
    echo "  ╠═══════════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                       ║"
    echo "  ║   🌐 API Endpoints:                                                   ║"
    echo "  ║      Local:   http://localhost:$SERVER_PORT/v1                             ║"
    printf "  ║      Public:  http://%-45s  ║\n" "$PUBLIC_IP:$SERVER_PORT/v1"
    echo "  ║                                                                       ║"
    echo "  ║   📊 Model Specs:                                                     ║"
    echo "  ║      Model:       Nemotron 3 Nano 30B (Q4_K_XL)                       ║"
    echo "  ║      Parameters:  31.58B total, 3.5B active (MoE)                     ║"
    echo "  ║      Context:     32,768 tokens (expandable to 1M)                    ║"
    echo "  ║      Speed:       120+ tokens/second                                  ║"
    echo "  ║                                                                       ║"
    echo "  ╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo ""
    echo -e "  ${CYAN}📡 Quick Test:${NC}"
    echo ""
    echo "  curl http://localhost:$SERVER_PORT/v1/chat/completions \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{"
    echo '      "model": "nemotron",'
    echo '      "messages": [{"role": "user", "content": "Hello! Who are you?"}]'
    echo "    }'"
    echo ""
    
    echo -e "  ${CYAN}🛠️  Management Commands:${NC}"
    echo ""
    echo "  sudo systemctl status nemoclaw     # Check status"
    echo "  sudo systemctl restart nemoclaw    # Restart server"
    echo "  sudo systemctl stop nemoclaw       # Stop server"
    echo "  sudo journalctl -u nemoclaw -f     # View live logs"
    echo ""
    
    echo -e "  ${CYAN}🔌 OpenClaw Configuration:${NC}"
    echo ""
    echo "  Add this provider to ~/.openclaw/openclaw.json:"
    echo ""
    echo '  "models": {'
    echo '    "providers": {'
    echo '      "nemoclaw": {'
    printf '        "baseUrl": "http://%s:%s/v1",\n' "$PUBLIC_IP" "$SERVER_PORT"
    echo '        "apiKey": "not-needed",'
    echo '        "api": "openai-completions",'
    echo '        "models": [{ "id": "nemotron", "name": "Nemotron 3 Nano" }]'
    echo '      }'
    echo '    }'
    echo '  }'
    echo ""
    
    echo -e "  ${YELLOW}⚠️  IMPORTANT: Stop your EC2 instance when not in use!${NC}"
    echo -e "  ${YELLOW}   Running 24/7 costs ~\$730/month. Stop when idle to save money.${NC}"
    echo ""
    
    echo -e "  ${PURPLE}🦞 Thank you for using NemoClaw!${NC}"
    echo -e "  ${BLUE}   GitHub: https://github.com/Omsatyaswaroop29/nemoclaw${NC}"
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    clear
    print_banner
    
    echo -e "  ${WHITE}Starting installation...${NC}"
    echo ""
    
    # Run installation phases
    check_system
    install_cuda
    build_llama_cpp
    download_model
    create_service
    start_and_verify
    display_summary
}

# Run main function
main "$@"
