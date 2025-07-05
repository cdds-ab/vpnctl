# vpnctl

A simple shell-based VPN profile manager driven by a YAML config.

## Features

- Multiple profiles in `~/.config/vpn_config.yaml`
- Commands: `start|up`, `stop|down`, `status`
- Debug mode: `-d` or `-v` to tail logs
- Profile selection: `-p <profile>`
- Bash tab-completion for flags, actions, and profiles
- Works with either Go-yq or Python-yq

## Installation

```bash
cd vpnctl
scripts/install.sh

