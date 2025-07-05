#!/usr/bin/env bash
#
# scripts/uninstall.sh — system-wide uninstaller for vpnctl
# Removes installed binaries and completions, but preserves user configs.
# Must be run as root (will re-exec under sudo if needed).

set -euo pipefail

# Re-exec under sudo if not root
if [[ $EUID -ne 0 ]]; then
  echo "🔒 Uninstalling vpnctl requires root; re-running under sudo…"
  exec sudo "$0" "$@"
fi

# Paths (must match install.sh)
BIN_PATH="/usr/local/bin/vpnctl"
COMPLETION_PATH="/etc/bash_completion.d/vpnctl"
SHARE_DIR="/usr/local/share/vpnctl"
SAMPLE_CONFIG="$SHARE_DIR/vpn_config.yaml.sample"

echo "🗑️  Uninstalling vpnctl…"

# 1) Remove the binary
if [[ -e "$BIN_PATH" ]]; then
  echo "  • Removing $BIN_PATH"
  rm -f "$BIN_PATH"
else
  echo "  • $BIN_PATH not found, skipping"
fi

# 2) Remove bash completion
if [[ -e "$COMPLETION_PATH" ]]; then
  echo "  • Removing $COMPLETION_PATH"
  rm -f "$COMPLETION_PATH"
else
  echo "  • $COMPLETION_PATH not found, skipping"
fi

# 3) Remove sample config, but leave user configs in ~/.config intact
if [[ -e "$SAMPLE_CONFIG" ]]; then
  echo "  • Removing sample config $SAMPLE_CONFIG"
  rm -f "$SAMPLE_CONFIG"
else
  echo "  • Sample config not found at $SAMPLE_CONFIG, skipping"
fi

# 4) If share directory is empty now, remove it
if [[ -d "$SHARE_DIR" ]]; then
  if [[ -z "$(ls -A "$SHARE_DIR")" ]]; then
    echo "  • Removing empty directory $SHARE_DIR"
    rmdir "$SHARE_DIR"
  else
    echo "  • $SHARE_DIR is not empty; leaving in place"
  fi
fi

echo
echo "✅ vpnctl has been uninstalled. Your personal config (~/.config/vpn_config.yaml) has been left untouched."

