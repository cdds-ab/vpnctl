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
./scripts/install.sh
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

I personally setup it like this:

```yaml
vpn:
  customer1:
    config: "$HOME/.vpn/customer1/config.ovpn"
  customer2:
    config: "$HOME/.vpn/customer2/config.ovpn"
```

within each customer's config directory I then place the necessary configuration for openvpn, example for customer2:

```bash
user@host:~/.vpn/customer2$ tree
.
├── auth.txt
├── config.ovpn
├── customer2-ca.pem
├── customer2-cert.key
└── customer2-cert.pem
```

Not related to vpnctl, but important to your configuration is of course, that you follow up on the paths within config.ovpn, that is you should have something like the following in your `config.ovpn`:

```bash
...
ca /home/user/.vpn/customer2/customer2-ca.pem
cert /home/user/.vpn/customer2/customer2-cert.pem
key /home/user/.vpn/customer2/customer2-cert.key
...
auth-user-pass /home/user/.vpn/customer2/auth.txt
```

In auth.txt you should have your vpn user name and password line by line.

