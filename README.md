# vpnctl

A simple shell-based VPN profile manager driven by a YAML config.

## Features

- Multiple profiles in `~/.config/vpn_config.yaml`
- Commands: `start|up`, `stop|down`, `status`
- Cleanup before start: `-k`/`--kill` to remove all old `tun*` interfaces, routes, DNS caches, and stray openvpn processes
- Debug mode: `-d` or `-v` to stream logs
- Profile selection: `-p <profile>`
- Bash tab-completion for flags, actions, and profiles
- Works with either Go-yq or Python-yq

## Installation

```bash
cd vpnctl
./scripts/install.sh
```

## Usage

```bash
vpnctl [-d|-v] [-k] [-p <profile>] <start|up|stop|down|status>
```

- `-k`/`--kill`  
  Before bringing up your chosen profile, clean out **all** old `tun*` interfaces, their routes, DNS caches, and any leftover openvpn processes.
- `-d`/`--debug` or `-v`/`--verbose`  
  Stream the log from the very beginning without tearing down the tunnel on Ctrl-C.
- `-p <profile>`  
  Select which profile from your YAML to use (defaults to the first one).

### Examples

```bash
# Just start the default profile:
vpnctl start

# Kill old VPN bits then start:
vpnctl -k start

# Start and immediately stream all logs:
vpnctl -d start

# Kill old bits, then debug-start:
vpnctl -k -d start

# Stop a specific profile:
vpnctl -p customer1 stop

# Check status:
vpnctl status
```

## Uninstallation

```bash
cd vpnctl
./scripts/uninstall.sh
```

## Configuration tips

vpnctl expects your configuration residing in `~/.config/vpn_config.yaml`:

```yaml
# Sample VPN config for vpnctl
# Copy to ~/.config/vpn_config.yaml and adjust paths.

vpn:
  default:
    config: "$HOME/.vpn/default.ovpn"

  other:
    config: "~/vpn/other.ovpn"
```

I personally set it up like this:

```yaml
vpn:
  customer1:
    config: "$HOME/.vpn/customer1/config.ovpn"
  customer2:
    config: "$HOME/.vpn/customer2/config.ovpn"
```

Within each customer's config directory I then place the necessary configuration for OpenVPN. Example for `customer2`:

```bash
user@host:~/.vpn/customer2$ tree
.
├── auth.txt
├── config.ovpn
├── customer2-ca.pem
├── customer2-cert.key
└── customer2-cert.pem
```

Not related to vpnctl, but important to your configuration is that you follow up on the paths within `config.ovpn`, for example:

```bash
ca /home/user/.vpn/customer2/customer2-ca.pem
cert /home/user/.vpn/customer2/customer2-cert.pem
key /home/user/.vpn/customer2/customer2-cert.key
auth-user-pass /home/user/.vpn/customer2/auth.txt
```
