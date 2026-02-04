#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║                        🦞 NemoClaw Installer                              ║
# ║                                                                           ║
# ║   Automated deployment script for Nemotron 3 Nano inference server        ║
# ║   Designed for AWS EC2 g5.xlarge with Amazon Linux 2023                   ║
# ║                                                                           ║
# ║   Repository: https://github.com/Omsatyaswaroop29/nemoclaw                ║
# ║   License: MIT                                                            ║
# ║                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -e  # Exit immediately if a command exits with a non-zero status

# ============================================================================
# CONFIGURATION VARIABLES
# ============================================================================

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
# HELPER FUNCTIONS
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${PURPLE}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# SYSTEM CHECK
# ============================================================================

check_system() {
    print_step "Checking system compatibility..."
    
    if [[ "$(uname -s)" != "Linux" ]]; then
        print_error "This script only supports Linux systems."
        exit 1
    fi
    
    if ! command_exists nvidia-smi; then
        print_error "NVIDIA drivers not found. Please use an AMI with pre-installed NVIDIA drivers."
        print_info "Recommended: Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.9 (Amazon Linux 2023)"
        exit 1
    fi
    
    print_info "Detected GPU:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    
    AVAILABLE_SPACE=$(df -BG /home | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $AVAILABLE_SPACE -lt 50 ]]; then
        print_error "Insufficient disk space. Need at least 50GB, found ${AVAILABLE_SPACE}GB."
        exit 1
    fi
    print_info "Available disk space: ${AVAILABLE_SPACE}GB"
    
    print_success "System check passed!"
}

# ============================================================================
# PHASE 1: CUDA TOOLKIT
# ============================================================================

install_cuda() {
    print_header "PHASE 1: CUDA Toolkit Installation"
    
    if [[ -d "$CUDA_HOME" ]] && command_exists nvcc; then
        print_info "CUDA Toolkit already installed at $CUDA_HOME"
        nvcc --version
        return 0
    fi
    
    print_step "Adding NVIDIA CUDA repository..."
    sudo dnf config-manager --add-repo \
        https://developer.download.nvidia.com/compute/cuda/repos/amzn2023/x86_64/cuda-amzn2023.repo
    
    print_step "Installing CUDA Toolkit ${CUDA_VERSION}..."
    print_info "This may take 5-10 minutes..."
    sudo dnf install -y cuda-toolkit-${CUDA_VERSION}
    
    print_step "Configuring environment variables..."
    export CUDA_HOME="$CUDA_HOME"
    export PATH="$CUDA_HOME/bin:$PATH"
    export LD_LIBRARY_PATH="$CUDA_HOME/lib64:$LD_LIBRARY_PATH"
    
    if ! grep -q "CUDA_HOME" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# CUDA Configuration (added by NemoClaw installer)" >> ~/.bashrc
        echo "export CUDA_HOME=$CUDA_HOME" >> ~/.bashrc
        echo "export PATH=\$CUDA_HOME/bin:\$PATH" >> ~/.bashrc
        echo "export LD_LIBRARY_PATH=\$CUDA_HOME/lib64:\$LD_LIBRARY_PATH" >> ~/.bashrc
    fi
    
    if command_exists nvcc; then
        print_success "CUDA Toolkit installed successfully!"
        nvcc --version
    else
        print_error "CUDA installation verification failed."
        exit 1
    fi
}

# ============================================================================
# PHASE 2: BUILD LLAMA.CPP
# ============================================================================

build_llama_cpp() {
    print_header "PHASE 2: Building llama.cpp with CUDA Support"
    
    if [[ -f "$LLAMA_CPP_DIR/build/bin/llama-server" ]]; then
        print_info "llama.cpp already built. Skipping..."
        return 0
    fi
    
    print_step "Cloning llama.cpp repository..."
    cd "$HOME"
    
    if [[ -d "$LLAMA_CPP_DIR" ]]; then
        print_info "Removing existing llama.cpp directory..."
        rm -rf "$LLAMA_CPP_DIR"
    fi
    
    git clone https://github.com/ggerganov/llama.cpp.git
    cd "$LLAMA_CPP_DIR"
    
    print_step "Creating build directory..."
    mkdir -p build
    cd build
    
    print_step "Configuring CMake with CUDA support..."
    cmake .. \
        -DGGML_CUDA=ON \
        -DCUDAToolkit_ROOT="$CUDA_HOME" \
        -DCMAKE_BUILD_TYPE=Release
    
    print_step "Compiling llama.cpp (this may take 3-5 minutes)..."
    print_info "Using $(nproc) CPU cores for parallel compilation..."
    cmake --build . --config Release -j$(nproc)
    
    if [[ -f "$LLAMA_CPP_DIR/build/bin/llama-server" ]]; then
        print_success "llama.cpp built successfully!"
    else
        print_error "llama.cpp build failed."
        exit 1
    fi
}

# ============================================================================
# PHASE 3: DOWNLOAD MODEL
# ============================================================================

download_model() {
    print_header "PHASE 3: Downloading Nemotron 3 Nano Model"
    
    if [[ -f "$MODEL_DIR/$MODEL_NAME" ]]; then
        print_info "Model already downloaded. Verifying size..."
        MODEL_SIZE=$(stat -c%s "$MODEL_DIR/$MODEL_NAME" 2>/dev/null || stat -f%z "$MODEL_DIR/$MODEL_NAME")
        if [[ $MODEL_SIZE -gt 22000000000 ]]; then
            print_success "Model file verified ($(numfmt --to=iec $MODEL_SIZE))"
            return 0
        else
            print_warning "Model file appears incomplete. Re-downloading..."
            rm -f "$MODEL_DIR/$MODEL_NAME"
        fi
    fi
    
    print_step "Creating models directory..."
    mkdir -p "$MODEL_DIR"
    cd "$MODEL_DIR"
    
    print_step "Downloading Nemotron 3 Nano (Q4_K_XL quantization)..."
    print_info "File size: ~21 GB"
    print_info "This may take 10-15 minutes depending on network speed..."
    echo ""
    
    wget --progress=bar:force:noscroll \
        -O "$MODEL_NAME" \
        "$MODEL_URL"
    
    if [[ -f "$MODEL_DIR/$MODEL_NAME" ]]; then
        MODEL_SIZE=$(stat -c%s "$MODEL_DIR/$MODEL_NAME" 2>/dev/null || stat -f%z "$MODEL_DIR/$MODEL_NAME")
        print_success "Model downloaded successfully! ($(numfmt --to=iec $MODEL_SIZE))"
    else
        print_error "Model download failed."
        exit 1
    fi
}

# ============================================================================
# PHASE 4: CREATE SYSTEMD SERVICE
# ============================================================================

create_service() {
    print_header "PHASE 4: Creating systemd Service"
    
    print_step "Creating NemoClaw service file..."
    
    sudo tee /etc/systemd/system/nemoclaw.service > /dev/null << EOF
[Unit]
Description=NemoClaw - Nemotron 3 Nano Inference Server
Documentation=https://github.com/Omsatyaswaroop29/nemoclaw
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$LLAMA_CPP_DIR/build/bin

Environment="CUDA_HOME=$CUDA_HOME"
Environment="PATH=$CUDA_HOME/bin:/usr/local/bin:/usr/bin:/bin"
Environment="LD_LIBRARY_PATH=$CUDA_HOME/lib64"

ExecStart=$LLAMA_CPP_DIR/build/bin/llama-server \\
    -m $MODEL_DIR/$MODEL_NAME \\
    --host 0.0.0.0 \\
    --port $SERVER_PORT \\
    -ngl $GPU_LAYERS \\
    -c $CONTEXT_SIZE

Restart=on-failure
RestartSec=10
TimeoutStartSec=300

NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$HOME/.cache

[Install]
WantedBy=multi-user.target
EOF

    print_step "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    
    print_step "Enabling NemoClaw service..."
    sudo systemctl enable nemoclaw
    
    print_success "Systemd service created and enabled!"
}

# ============================================================================
# PHASE 5: START AND VERIFY
# ============================================================================

start_and_verify() {
    print_header "PHASE 5: Starting NemoClaw Server"
    
    print_step "Starting NemoClaw service..."
    sudo systemctl start nemoclaw
    
    print_info "Waiting for model to load into GPU memory..."
    print_info "This typically takes 60-90 seconds for the 21GB model..."
    echo ""
    
    MAX_WAIT=180
    WAITED=0
    INTERVAL=5
    
    while [[ $WAITED -lt $MAX_WAIT ]]; do
        if curl -s http://localhost:$SERVER_PORT/v1/models > /dev/null 2>&1; then
            echo ""
            print_success "NemoClaw server is ready!"
            break
        fi
        
        printf "\r  Loading... [%3ds / %ds]" $WAITED $MAX_WAIT
        sleep $INTERVAL
        WAITED=$((WAITED + INTERVAL))
    done
    
    if [[ $WAITED -ge $MAX_WAIT ]]; then
        echo ""
        print_warning "Server took longer than expected to start."
        print_info "Check logs with: sudo journalctl -u nemoclaw -f"
    fi
}

# ============================================================================
# PHASE 6: DISPLAY SUMMARY
# ============================================================================

display_summary() {
    print_header "🎉 Installation Complete!"
    
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "YOUR_INSTANCE_IP")
    
    echo -e "${GREEN}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   NemoClaw is now running!                                    ║"
    echo "  ║                                                               ║"
    echo "  ╠═══════════════════════════════════════════════════════════════╣"
    echo "  ║                                                               ║"
    echo "  ║   🌐 Local Endpoint:    http://localhost:$SERVER_PORT/v1           ║"
    echo "  ║   🌍 Public Endpoint:   http://$PUBLIC_IP:$SERVER_PORT/v1"
    echo "  ║                                                               ║"
    echo "  ║   📊 Model:             Nemotron 3 Nano 30B                   ║"
    echo "  ║   🧠 Context:           $CONTEXT_SIZE tokens                       ║"
    echo "  ║   ⚡ Max Context:       1,048,576 tokens                      ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo ""
    echo -e "${CYAN}Quick Test:${NC}"
    echo ""
    echo "  curl http://localhost:$SERVER_PORT/v1/chat/completions \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{"
    echo '      "model": "nemotron",'
    echo '      "messages": [{"role": "user", "content": "Hello! Who are you?"}]'
    echo "    }'"
    echo ""
    
    echo -e "${CYAN}Management Commands:${NC}"
    echo ""
    echo "  sudo systemctl status nemoclaw     # Check status"
    echo "  sudo systemctl restart nemoclaw    # Restart server"
    echo "  sudo systemctl stop nemoclaw       # Stop server"
    echo "  sudo journalctl -u nemoclaw -f     # View live logs"
    echo ""
    
    echo -e "${YELLOW}⚠️  IMPORTANT: Stop your EC2 instance when not in use to save costs!${NC}"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    clear
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
    echo -e "  ${CYAN}Self-Hosted AI Inference Server for OpenClaw${NC}"
    echo -e "  ${BLUE}Nemotron 3 Nano • 30B Parameters • 1M Token Context${NC}"
    echo ""
    
    check_system
    install_cuda
    build_llama_cpp
    download_model
    create_service
    start_and_verify
    display_summary
}

main "$@"
