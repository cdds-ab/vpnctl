# vpnctl

[![Tests](https://github.com/cdds-ab/vpnctl/actions/workflows/test.yml/badge.svg)](https://github.com/cdds-ab/vpnctl/actions/workflows/test.yml)
[![Release](https://github.com/cdds-ab/vpnctl/actions/workflows/release.yml/badge.svg)](https://github.com/cdds-ab/vpnctl/actions/workflows/release.yml)
[![Coverage](https://img.shields.io/badge/coverage-44%25-green)](https://github.com/cdds-ab/vpnctl/actions)
[![Latest Release](https://img.shields.io/github/v/release/cdds-ab/vpnctl)](https://github.com/cdds-ab/vpnctl/releases)
[![Shell](https://img.shields.io/badge/shell-bash-blue)](bin/vpnctl)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A simple shell-based VPN profile manager driven by a YAML config.

## Features

- Multiple profiles in `~/.config/vpn_config.yaml`
- Commands: `start|up`, `stop|down`, `status`, `backup`, `restore`, `backup-stats`, `set-backup`, `self-update`
- Cleanup before `start`: `-k`/`--kill` to remove all old `tun*` interfaces, routes, DNS caches, and stray openvpn processes
- Debug mode: `-d` or `-v` to stream logs without tearing down the tunnel on Ctrl-C
- Profile selection: `-p <profile>`
- Encrypted backup: `backup` with `-o`/`--output <file>` (default `vpn-backup.tar.gz.gpg`)
- Encrypted restore: `restore` with `-i`/`--input <file>` (default `vpn-backup.tar.gz.gpg`)
- Bash tab-completion for flags, actions, and profiles
- Works with either Go-yq or Python-yq

## Installation

### From Release (Recommended)

Download the latest release from [GitHub Releases](https://github.com/cdds-ab/vpnctl/releases):

```bash
# Download and install latest release
curl -L https://github.com/cdds-ab/vpnctl/releases/latest/download/install.sh | bash
```

Or manually:
```bash
wget https://github.com/cdds-ab/vpnctl/releases/latest/download/vpnctl
wget https://github.com/cdds-ab/vpnctl/releases/latest/download/install.sh
chmod +x install.sh
sudo ./install.sh
```

### From Source

```bash
git clone https://github.com/cdds-ab/vpnctl.git
cd vpnctl
./scripts/install.sh
```

## Usage

```bash
vpnctl [--version] [-d|-v] [-k] [-p <profile>] [-o <file>] [-i <file>] <start|up|stop|down|status|backup|restore|backup-stats|set-backup <path>|self-update>
```

- `--version`  
  Show version information and exit.
- `-k`/`--kill`  
  Before bringing up your chosen profile, clean out **all** old `tun*` interfaces, their routes, DNS caches, and any leftover openvpn processes.
- `-d`/`--debug` or `-v`/`--verbose`  
  Stream the log from the very beginning without tearing down the tunnel on Ctrl-C.
- `-p <profile>`  
  Select which profile from your YAML to use (defaults to the first one).
- `-o <file>`/`--output <file>` (for `backup`)  
  Write the encrypted backup archive to `<file>`. If omitted, defaults to `vpn-backup.tar.gz.gpg`.
- `-i <file>`/`--input <file>` (for `restore`)  
  Read the encrypted backup archive from `<file>`. If omitted, defaults to `vpn-backup.tar.gz.gpg`.

## Backup and Restore

Note! Currently the backup and recovery depends on having the following configurational setup:

- `${HOME}/.config/vpn_config.yaml`: location of vpn_config.yaml
- `${HOME}/.vpn/`: location of the specific vpn configs of your customers

### Examples

```bash
# Show version:
vpnctl --version

# Start the default profile:
vpnctl start

# Kill old VPN bits then start:
vpnctl -k start

# Start and immediately stream all logs:
vpnctl -d start

# Create encrypted backup to a specific path:
vpnctl backup -o ~/Backups/vpn-$(date +%F).tar.gz.gpg

# Restore from encrypted backup:
vpnctl restore -i ~/Backups/vpn-2025-07-05.tar.gz.gpg

# Stop a specific profile:
vpnctl -p customer1 stop

# Check status:
vpnctl status

# Set backup location in config:
vpnctl set-backup ~/Backups/my-vpn-backup.tar.gz.gpg

# View backup statistics:
vpnctl backup-stats

# Update to latest version:
vpnctl self-update
```

## Testing

vpnctl includes comprehensive tests using BATS (Bash Automated Testing System):

```bash
# Install BATS
sudo apt install bats  # Ubuntu/Debian
sudo dnf install bats  # Fedora/RHEL

# Run all tests
./tests/run_tests.sh

# Run with coverage analysis
./tests/coverage.sh run

# Generate HTML coverage report
./tests/coverage.sh html

# Run specific test files
bats tests/test_vpnctl.bats
```

### Test Coverage

The test suite covers:
- ✅ Core backup file resolution logic
- ✅ Configuration file handling (YAML parsing)
- ✅ Both Go-yq and Python-yq compatibility
- ✅ set-backup command functionality
- ✅ Bash completion system
- ✅ Argument parsing and validation
- ✅ Path expansion and normalization

Coverage reports are generated in `coverage/` directory with HTML visualization.

### Continuous Integration

## Development Status

### ✅ Completed Features
- **Core VPN Management** - start, stop, status, backup, restore operations
- **Backup Analytics** - `backup-stats` command for encrypted backup analysis
- **Configurable Backup** - `set-backup` command with YAML config and tab completion
- **Self-Update System** - Automatic update checking and `self-update` command
- **Multi-yq Support** - Compatible with both Go-yq (mikefarah) and Python-yq (kislyuk)
- **Kill Switch** - `-k` flag for cleanup of existing tunnel interfaces

### ✅ Test Infrastructure (GitHub Issue #4)
- **Regression Tests** - 21 BATS test cases with matrix testing
- **Coverage Analysis** - Function coverage validation and CI integration
- **CI/CD Pipeline** - Automated testing, linting, security scanning
- **Multi-environment** - Tests with both Go-yq and Python-yq variants

### ✅ Release Automation
- **Semantic Versioning** - Automated releases via conventional commits
- **GitHub Actions** - Complete CI/CD with tests → lint → release pipeline  
- **Release Assets** - Auto-generated with scripts, docs, and checksums
- **Conventional Commits** - Developer guidelines with commit templates

### 🎯 Current Status
- **Version**: v1.0.1 (stable)
- **Test Suite**: 21 test cases covering core functionality
- **Functions**: Comprehensive coverage of backup, config, and VPN operations
- **CI/CD**: Fully automated
- **Release Process**: Zero-touch via conventional commits

## Releases

This project uses automated releases with [Semantic Versioning](https://semver.org/):

- **feat**: New features → MINOR version bump
- **fix**: Bug fixes → PATCH version bump  
- **BREAKING CHANGE**: Breaking changes → MAJOR version bump

All releases are automatically created via GitHub Actions and include:
- Pre-compiled binaries and scripts
- Automated changelogs
- Release assets with checksums

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for commit message guidelines.

## Uninstallation

```bash
cd vpnctl
./scripts/uninstall.sh
```

## Configuration

`vpnctl` expects your configuration residing in `~/.config/vpn_config.yaml`:

```yaml
# Sample VPN config for vpnctl
# Copy to ~/.config/vpn_config.yaml and adjust paths.

backup:
  default_file: "$HOME/vpn-backup.tar.gz.gpg"

vpn:
  default:
    config: "$HOME/.vpn/default.ovpn"

  other:
    config: "~/vpn/other.ovpn"
```

### Backup Configuration

The `backup.default_file` setting allows you to specify a default location for backup operations:

- **Without config**: Uses `vpn-backup.tar.gz.gpg` in current directory
- **With config**: Uses the configured path (supports `~` and `$HOME` expansion)
- **Command line override**: `-o` and `-i` flags always take precedence

**Examples:**
```yaml
backup:
  default_file: "~/Backups/vpn-backup.tar.gz.gpg"        # Home directory
  default_file: "/var/backups/vpn-backup.tar.gz.gpg"     # Absolute path
  default_file: "$HOME/Documents/vpn-backup.tar.gz.gpg"  # Variable expansion
```

### Setting Backup Location

Use the `set-backup` command to easily configure your backup location with tab completion:

```bash
# Set backup path (supports tab completion for file paths)
vpnctl set-backup ~/Backups/vpn-backup.tar.gz.gpg

# The command will automatically update your ~/.config/vpn_config.yaml
# All backup operations will now use this location by default
```

### Example Configuration

I personally set it up like this:

```yaml
backup:
  default_file: "$HOME/Backups/vpn-backup.tar.gz.gpg"

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

Not directly related to `vpnctl`, but important to your configuration is that you follow up on the paths within `config.ovpn`, for example:

```bash
ca /home/user/.vpn/customer2/customer2-ca.pem
cert /home/user/.vpn/customer2/customer2-cert.pem
key /home/user/.vpn/customer2/customer2-cert.key
auth-user-pass /home/user/.vpn/customer2/auth.txt
```
