#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ==========================================
# OPENCLAW BOOTSTRAP FENCE (TERMUX)
# ==========================================

APP_DIR="$HOME/ai-lab"
REPO_URL="https://github.com/openclaw/openclaw.git"
LOG_FILE="$HOME/openclaw_install.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting OpenClaw bootstrap..."

# ==========================================
# 1. SYSTEM DEPENDENCIES
# ==========================================
log "Updating Termux packages..."
pkg update -y && pkg upgrade -y

log "Installing dependencies..."
pkg install -y git python openssh curl clang make

# ==========================================
# 2. WORKSPACE SETUP
# ==========================================
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# ==========================================
# 3. REPO CLONE (IDEMPOTENT SAFE)
# ==========================================
if [ ! -d "$APP_DIR/openclaw" ]; then
  log "Cloning OpenClaw repository..."
  git clone "$REPO_URL"
else
  log "OpenClaw already exists. Pulling latest changes..."
  cd openclaw && git pull && cd ..
fi

cd openclaw

# ==========================================
# 4. PYTHON ENVIRONMENT ISOLATION
# ==========================================
log "Setting up Python venv..."
python -m venv venv
source venv/bin/activate

pip install --upgrade pip

if [ -f requirements.txt ]; then
  pip install -r requirements.txt
else
  log "WARNING: requirements.txt not found"
fi

# ==========================================
# 5. SHIZUKU HOOK (OPTIONAL LAYER)
# ==========================================
log "Checking Shizuku environment (optional)..."

if command -v shizuku >/dev/null 2>&1; then
  log "Shizuku detected."
else
  log "Shizuku not detected (non-root mode assumed)."
fi

# ==========================================
# 6. RUNTIME FENCE CREATION
# ==========================================
cat > "$APP_DIR/run_openclaw.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~/ai-lab/openclaw
source venv/bin/activate
python main.py
EOF

chmod +x "$APP_DIR/run_openclaw.sh"

# ==========================================
# 7. COMPLETION
# ==========================================
log "OpenClaw bootstrap completed successfully."
log "Run using: bash ~/ai-lab/run_openclaw.sh"
