#!/usr/bin/env bash
set -Eeuo pipefail

need_root() { [ "$EUID" -eq 0 ] || { echo "Please run as root: sudo bash uninstall.sh"; exit 1; }; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }

need_root
need_cmd systemctl
need_cmd rm

systemctl disable --now update-cloudflare-ufw.timer || true
systemctl stop update-cloudflare-ufw.service || true

rm -f /etc/systemd/system/update-cloudflare-ufw.timer
rm -f /etc/systemd/system/update-cloudflare-ufw.service
systemctl daemon-reload

rm -f /usr/local/bin/update-cloudflare-ufw.sh

echo "Uninstalled."
