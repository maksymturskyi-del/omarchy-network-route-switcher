#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
REPOSITORY_URL="https://github.com/maksymturskyi-del/omarchy-network-route-switcher.git"
BACKEND_PATH="/usr/local/libexec/omarchy-mwan-backend"
DISPATCHER_PATH="/etc/NetworkManager/dispatcher.d/90-omarchy-internet-route"
POLICY_PATH="/usr/share/polkit-1/actions/org.omarchy.network-route-switcher.policy"
LEGACY_BACKEND="/usr/local/bin/omarchy-mwan-backend"
INSTALL_PLUGIN=1

if [[ ${1:-} == --skip-plugin ]]; then
  INSTALL_PLUGIN=0
elif [[ $# -gt 0 ]]; then
  echo "Usage: $0 [--skip-plugin]" >&2
  exit 2
fi

echo "==> Встановлення Omarchy Network Route Switcher..."

# 1. Встановлення бінарного скрипта
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/bin/omarchy-internet-route" "$BIN_DIR/omarchy-internet-route"
chmod +x "$BIN_DIR/omarchy-internet-route"
echo "  [✓] Скрипт встановлено в $BIN_DIR/omarchy-internet-route"

if ! command -v sudo >/dev/null 2>&1; then
  echo "Помилка: sudo потрібен для встановлення системного маршрутизатора Both." >&2
  exit 1
fi

if ! command -v pkexec >/dev/null 2>&1 || ! command -v nft >/dev/null 2>&1; then
  echo "Помилка: для Both потрібні pkexec і nftables." >&2
  exit 1
fi

if [[ $INSTALL_PLUGIN -eq 1 ]] && ! command -v omarchy >/dev/null 2>&1; then
  echo "Помилка: omarchy CLI не знайдено. Встановіть Omarchy Shell та повторіть." >&2
  exit 1
fi

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin validate "$SCRIPT_DIR"
elif [[ $INSTALL_PLUGIN -eq 0 ]]; then
  echo "Увага: omarchy CLI не знайдено; перевірку маніфесту пропущено." >&2
fi

# Migrate the first experimental installer, which used the same feature name
# but left policy-routing rules that conflict with the maintained backend.
if [[ -x $LEGACY_BACKEND ]] && grep -q 'Omarchy Multi-WAN Load Balancer' "$LEGACY_BACKEND" \
  && { [[ -e /etc/systemd/system/omarchy-mwan.service ]] || [[ -e /etc/NetworkManager/dispatcher.d/99-omarchy-internet-route.sh ]]; }; then
  echo "  [i] Removing the legacy Omarchy Multi-WAN rules and dispatcher..."
  sudo "$LEGACY_BACKEND" uninstall
fi

sudo install -D -o root -g root -m 0755 "$SCRIPT_DIR/bin/omarchy-mwan-backend" "$BACKEND_PATH"
sudo install -D -o root -g root -m 0755 "$SCRIPT_DIR/bin/omarchy-mwan-dispatcher" "$DISPATCHER_PATH"
sudo install -D -o root -g root -m 0644 "$SCRIPT_DIR/org.omarchy.network-route-switcher.policy" "$POLICY_PATH"
config_tmp=$(mktemp)
trap 'rm -f "$config_tmp"' EXIT
printf 'STATE_FILE=%q\n' "$HOME/.config/omarchy/network-route.mode" > "$config_tmp"
sudo install -D -o root -g root -m 0644 "$config_tmp" /etc/omarchy-internet-route.conf

# 2. Install the bar plugin from this repository.
if [[ $INSTALL_PLUGIN -eq 1 ]]; then
  omarchy plugin add "$REPOSITORY_URL" --enable
  omarchy restart shell
fi

echo "==> Встановлення завершено успішно!"
