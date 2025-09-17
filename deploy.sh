#!/usr/bin/env bash
set -Eeuo pipefail

RUN_NOW="${1:-}"

BIN_SRC="bin/update-cloudflare-ufw.sh"
BIN_DST="/usr/local/bin/update-cloudflare-ufw.sh"
UNIT_DIR_DST="/etc/systemd/system"
SERVICE_SRC="systemd/update-cloudflare-ufw.service"
TIMER_SRC="systemd/update-cloudflare-ufw.timer"
SERVICE_DST="$UNIT_DIR_DST/update-cloudflare-ufw.service"
TIMER_DST="$UNIT_DIR_DST/update-cloudflare-ufw.timer"

need_root() { [ "$EUID" -eq 0 ] || { echo "Please run as root: sudo bash deploy.sh"; exit 1; }; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }

need_root
need_cmd install
need_cmd systemctl
need_cmd chmod
need_cmd find

# 1) Copy files to their destinations
install -D -m 0755 "$BIN_SRC"  "$BIN_DST"
install -D -m 0644 "$SERVICE_SRC" "$SERVICE_DST"
install -D -m 0644 "$TIMER_SRC"   "$TIMER_DST"

# 2) Recursively tighten permissions, then add execute bits to directories and scripts
#    Note: We only tighten permissions within the project directory; the installed target paths are separately set with reasonable permissions.
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
chmod -R a-wx,a+r,u+rwx "$PROJECT_ROOT"

# Directories need to be accessible; use +X on directories, which won't add x to regular files
find "$PROJECT_ROOT" -type d -exec chmod a+X {} \;

# Make sure the deployed targets also meet the executable requirements
chmod a-wx,a+r,u+rwx "$BIN_DST"   && chmod a+X "$BIN_DST"     # Script executable
chmod a-wx,a+r,u+rwx "$SERVICE_DST" "$TIMER_DST"               # Unit files suggest 644 (currently equivalent)
# systemd unit files can be 0644, directory execute bits are provided by the system directories

# 3) Reload and enable the timer
systemctl daemon-reload
systemctl enable --now update-cloudflare-ufw.timer

if [ "$RUN_NOW" = "--run-now" ]; then
  systemctl start update-cloudflare-ufw.service || true
fi

echo "Deployment complete. Status:"
systemctl status --no-pager update-cloudflare-ufw.timer | sed -n '1,12p'
echo
echo "To view recent logs: journalctl -u update-cloudflare-ufw.service -n 50 --no-pager"
