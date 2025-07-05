#!/usr/bin/env bash
#
# scripts/install.sh — system‐wide installer for vpnctl
# Must be run as root (re-execs under sudo if needed).

set -euo pipefail

# Re-exec under sudo if not root
if [[ $EUID -ne 0 ]]; then
  echo "🔒 Requires root; re-running under sudo…"
  exec sudo "$0" "$@"
fi

# Check yq
if ! command -v yq &>/dev/null; then
  cat <<EOF >&2
❌ 'yq' not found. Please install via your package manager:

  • Debian/Ubuntu: sudo apt update && sudo apt install yq
  • Fedora:         sudo dnf install yq
  • CentOS/RHEL:    sudo yum install yq
  • Arch Linux:     sudo pacman -S yq
  • macOS/Homebrew: brew install yq

Or grab Go-binary from:
  https://github.com/mikefarah/yq/releases
EOF
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BIN_SRC="$PROJECT_ROOT/bin/vpnctl"
BIN_DST="/usr/local/bin/vpnctl"

COMPILE_SRC="$PROJECT_ROOT/completions/vpnctl"
COMPILE_DST="/etc/bash_completion.d/vpnctl"

SHARE_DIR="/usr/local/share/vpnctl"
CONFIG_SRC="$PROJECT_ROOT/config/vpn_config.yaml.sample"
CONFIG_DST="$SHARE_DIR/vpn_config.yaml.sample"

echo "📦 Installing vpnctl…"

# Backup existing
for dst in "$BIN_DST" "$COMPILE_DST"; do
  if [[ -e "$dst" ]]; then
    echo "  • Backing up existing $(basename "$dst") to ${dst}.old"
    mv "$dst" "${dst}.old"
  fi
done

# 1) vpnctl
echo "  • Copying vpnctl to $BIN_DST"
install -Dm755 "$BIN_SRC" "$BIN_DST"

# 2) completion
echo "  • Copying completion to $COMPILE_DST"
install -Dm644 "$COMPILE_SRC" "$COMPILE_DST"

# 3) sample config
echo "  • Installing sample config to $CONFIG_DST"
install -d "$SHARE_DIR"
install -Dm644 "$CONFIG_SRC" "$CONFIG_DST"

cat <<EOF

✅ Installed vpnctl:

  • Command:       $BIN_DST
  • Completion:    $COMPILE_DST
  • Sample config: $CONFIG_DST

Next steps:
  1. Copy sample config to ~/.config/vpn_config.yaml and edit.
  2. Ensure 'yq' is in your PATH.
  3. Reload your shell or run:
       source /etc/bash_completion
EOF

