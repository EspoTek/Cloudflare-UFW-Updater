
# Cloudflare UFW Updater

Automatically updates UFW rules to allow the latest Cloudflare IP ranges for HTTP/HTTPS (ports 80/443).

## Features
- Fetches the official Cloudflare IPv4/IPv6 lists
- Only updates UFW rules tagged with **(cloudflare)**, leaving other rules untouched
- Uses a systemd timer to run daily at 04:00 and once 10 minutes after boot

## Installation
```bash
sudo bash deploy.sh           # Install and enable the systemd timer
sudo bash deploy.sh --run-now # Optionally run immediately after install
```

## Uninstall
```bash
sudo bash uninstall.sh
```

## How it works
1. Downloads the latest Cloudflare IP ranges
2. Removes old UFW rules tagged with (cloudflare)
3. Adds new allow rules for all Cloudflare IPs on ports 80/443 (tcp)
4. Only rules with the (cloudflare) comment are managed—your other UFW rules are safe

## Systemd Integration
- `update-cloudflare-ufw.service`: Runs the update script
- `update-cloudflare-ufw.timer`: Schedules the update daily and after boot

## License

MIT License. See [LICENSE](LICENSE) for details.
