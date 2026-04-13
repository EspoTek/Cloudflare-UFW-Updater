#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root (with sudo)." >&2
  exit 1
fi

sudo ufw --force reset || true
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp

REPO_DIR="/tmp/Cloudflare-UFW-Updater"
rm -rf "$REPO_DIR"
git clone https://github.com/espotek/Cloudflare-UFW-Updater "$REPO_DIR"
cd "$REPO_DIR"
sudo bash deploy.sh --run-now

sudo ufw --force enable || true
sudo ufw status verbose
