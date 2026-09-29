#!/usr/bin/env bash
# One-time setup of a fresh Ubuntu 24.04 EC2 instance for Nexoraa CleanSoft.
# Installs: 4 GB swap, Node.js 22, pnpm (corepack), PM2, Caddy (automatic HTTPS).
# Safe to re-run. Usage (from the cloned repo):  bash infra/aws-ec2/setup-server.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_DIR="${NEXORAA_ENV_DIR:-$HOME/nexoraa-env}"

echo "==> Swap (a small instance needs it to build 14 services)"
if ! sudo swapon --show | grep -q '/swapfile'; then
  sudo fallocate -l 4G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

echo "==> Base packages"
sudo apt-get update -y
sudo apt-get install -y git curl ca-certificates gnupg debian-keyring debian-archive-keyring apt-transport-https
# Libraries headless Chrome needs — order-service renders receipt PDFs with puppeteer.
sudo apt-get install -y libnss3 libatk1.0-0t64 libatk-bridge2.0-0t64 libcups2t64 libdrm2 \
  libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 \
  libcairo2 libasound2t64 fonts-liberation fonts-noto-core

echo "==> Node.js 22"
if ! node --version 2>/dev/null | grep -q '^v22'; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
# Same as Render's build command: a current corepack avoids pnpm signature errors.
sudo npm install -g corepack@latest pm2
sudo corepack enable

echo "==> Caddy (reverse proxy + free Let's Encrypt certificates)"
if ! command -v caddy >/dev/null; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
    | sudo tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y caddy
fi

echo "==> PM2 starts on boot"
sudo env PATH="$PATH:/usr/bin" pm2 startup systemd -u "$USER" --hp "$HOME" >/dev/null

echo "==> Env folder: $ENV_DIR"
mkdir -p "$ENV_DIR"
chmod 700 "$ENV_DIR"
for template in "$SCRIPT_DIR"/env/*.env.template; do
  target="$ENV_DIR/$(basename "$template" .template)"
  [ -f "$target" ] || cp "$template" "$target"
done
chmod 600 "$ENV_DIR"/*.env

echo "==> Generating internal secrets (each GENERATE_ME gets its own random value)"
for env_file in "$ENV_DIR"/*.env; do
  while grep -q 'GENERATE_ME' "$env_file"; do
    sed -i "0,/GENERATE_ME/s//$(openssl rand -hex 32)/" "$env_file"
  done
done

cat <<EOF

Setup complete.
NEXT: put each service's MONGODB_URI (and Razorpay/Brevo keys, if you use them)
into $ENV_DIR/<service>.env — copy them from Render -> service -> Environment.
Every FILL_ME must be replaced. Then run:  bash infra/aws-ec2/deploy.sh
EOF
