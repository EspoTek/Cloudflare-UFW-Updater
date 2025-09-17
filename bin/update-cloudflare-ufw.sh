#!/usr/bin/env bash
# Update UFW to allow Cloudflare IPs on ports 80/443 (tcp)
# Safe: only touches rules tagged with (cloudflare)
set -Eeuo pipefail

LOCKFILE="/run/lock/update-cloudflare-ufw.lock"
exec 9>"$LOCKFILE" || true
flock -n 9 || { echo "Another run is in progress. Exit."; exit 0; }

CF_V4_URL="https://www.cloudflare.com/ips-v4"
CF_V6_URL="https://www.cloudflare.com/ips-v6"
COMMENT="cloudflare"
PORTS="80,443"
PROTO="tcp"

echo "Fetching Cloudflare IP ranges..."
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }
need_cmd curl; need_cmd ufw; need_cmd awk; need_cmd sort; need_cmd grep; need_cmd sed

if grep -q "^IPV6=no" /etc/default/ufw 2>/dev/null; then
  echo "WARN: IPv6 is disabled in /etc/default/ufw. IPv6 rules will not be effective. Consider setting IPV6=yes and running 'ufw reload'."
fi

echo "Fetching Cloudflare IP ranges..."
CF_IPV4=$(curl -fsSL "$CF_V4_URL" | grep -E '^[0-9]+\.' || true)
CF_IPV6=$(curl -fsSL "$CF_V6_URL" | grep -E '^[0-9a-fA-F:]+/' || true)

if [ -z "${CF_IPV4}${CF_IPV6}" ]; then
  echo "ERROR: Failed to fetch Cloudflare IP list."
  exit 1
fi

CF_IPV4=$(printf "%s\n" "$CF_IPV4" | awk 'NF' | sort -u)
CF_IPV6=$(printf "%s\n" "$CF_IPV6" | awk 'NF' | sort -u)
echo "IPv4: $(printf "%s\n" "$CF_IPV4" | wc -l)  IPv6: $(printf "%s\n" "$CF_IPV6" | wc -l)"

if ! ufw status | grep -q "Status: active"; then
  echo "UFW is not enabled, enabling now..."
  yes | ufw enable
fi

echo "Pruning old Cloudflare-tagged rules..."
mapfile -t CF_RULE_IDX < <(ufw status numbered | sed -n '/(cloudflare)/p' | sed -E 's/^\[([0-9]+)\].*/\1/' | sort -nr)
for idx in "${CF_RULE_IDX[@]:-}"; do
  yes | ufw delete "$idx" >/dev/null || true
done

add_rule() {
  local ip="$1"
  ufw allow proto "$PROTO" from "$ip" to any port "$PORTS" comment "$COMMENT" >/dev/null
}

echo "Adding new Cloudflare rules..."
while IFS= read -r ip; do [ -n "$ip" ] && add_rule "$ip"; done <<< "$CF_IPV4"
while IFS= read -r ip; do [ -n "$ip" ] && add_rule "$ip"; done <<< "$CF_IPV6"

ufw reload >/dev/null || true
echo "Done. Current UFW rules tagged with ($COMMENT):"
ufw status | grep "(cloudflare)" || echo "No tagged rules found. (unexpected)"
