#!/usr/bin/env bash
# =============================================================================
# EC2 Server Bootstrap Script
# Run once on a fresh Ubuntu 22.04 EC2 instance.
# Usage: bash scripts/setup_ec2.sh
# =============================================================================

set -euo pipefail

echo "╔══════════════════════════════════════════════════╗"
echo "║        EC2 Bootstrap — Flask CI/CD App           ║"
echo "╚══════════════════════════════════════════════════╝"

# ── 1. Update system ──────────────────────────────────────────────────────────
echo "→ Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# ── 2. Install Docker ─────────────────────────────────────────────────────────
echo "→ Installing Docker..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# ── 3. Add current user to docker group (no sudo needed) ─────────────────────
echo "→ Configuring Docker permissions..."
sudo usermod -aG docker "$USER"
sudo systemctl enable docker
sudo systemctl start docker

# ── 4. Install Docker Compose (standalone v2) ─────────────────────────────────
echo "→ Installing Docker Compose..."
COMPOSE_VERSION="v2.27.0"
sudo curl -SL \
  "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# ── 5. Clone the repository ───────────────────────────────────────────────────
echo "→ Cloning project repository..."
REPO_URL="${REPO_URL:-https://github.com/YOUR_USERNAME/flask-cicd-pipeline.git}"
cd ~
git clone "$REPO_URL" flask-cicd-pipeline || (cd flask-cicd-pipeline && git pull)

# ── 6. Configure firewall (UFW) ───────────────────────────────────────────────
echo "→ Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║              Setup Complete! ✅                  ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  Next steps:                                     ║"
echo "║  1. Log out & back in (apply docker group)       ║"
echo "║  2. Add GitHub Secrets (see README)              ║"
echo "║  3. Push to main → pipeline auto-deploys         ║"
echo "╚══════════════════════════════════════════════════╝"
