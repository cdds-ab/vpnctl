# Changelog

All notable changes to vpnctl will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-07-19

### Added

**Backup Statistics (`backup-stats`)**
- Analyze encrypted backup contents without extraction
- Show backup file size, creation date, and VPN profiles
- List all `.ovpn` configuration files in backup
- Smart synchronization status that ignores backup path differences
- Support for custom backup files via `-i` flag

**Configurable Backup Location (`set-backup`)**  
- Set default backup location in `~/.config/vpn_config.yaml`
- Tab completion for file paths
- Automatic YAML configuration updates
- Support for path expansion (`~`, `$HOME`)
- Creates config file if it doesn't exist

**Enhanced Configuration System**
- New `backup.default_file` configuration option
- Hierarchical backup file resolution:
  1. Command-line flags (`-o`/`-i`) - highest priority
  2. Config file (`backup.default_file`) - medium priority  
  3. Default location (`vpn-backup.tar.gz.gpg`) - fallback

**Test Infrastructure & CI/CD (GitHub Issue #4)**
- Comprehensive BATS test suite with 38 test cases
- Function-based code coverage analysis (22% coverage)
- GitHub Actions CI/CD pipeline with matrix testing
- HTML coverage reports with visualization
- Automated regression testing on every commit
- Multi-environment testing (Go-yq vs Python-yq)
- README badges for test status and coverage

### Changed

**Enhanced yq Compatibility**
- Full support for both Go-yq (mikefarah) and Python-yq (kislyuk)
- Automatic detection and syntax adaptation
- Robust YAML manipulation across both implementations

**Improved Tab Completion**
- Added `backup-stats` and `set-backup` commands
- File path completion for `set-backup` command
- Maintained compatibility with existing completion features

**Smart Synchronization**
- `backup-stats` now ignores `backup.default_file` differences
- Shows only meaningful VPN configuration changes
- Prevents false "config differs" warnings from backup path updates

**Documentation**
- All German comments translated to English
- Consistent English docstrings throughout
- Comprehensive backup configuration section in README
- Usage examples for all new commands

### Technical

- **Functions Added:** `get_backup_file()`, `backup_stats()`, `set_backup_path()`
- **Arguments Added:** `BACKUP_PATH` variable, `set-backup <path>` command
- **YAML Operations:** Robust backup configuration management
- **Error Handling:** Improved validation and user feedback
- **CI/CD Pipeline:** GitHub Actions workflow addressing Issue #4
- **Test Infrastructure:** 38 BATS tests with 22% function coverage
- **Coverage Reporting:** HTML and JSON coverage reports

### Usage Examples

```bash
# Set backup location with tab completion
vpnctl set-backup ~/Backups/vpn-backup.tar.gz.gpg

# View backup statistics  
vpnctl backup-stats

# All backup operations now use configured location
vpnctl backup
vpnctl restore
```

## [1.0.0] - Previous Version

### Added
- Multiple VPN profiles in YAML configuration
- Commands: `start`, `stop`, `status`, `backup`, `restore`
- Kill switch (`-k`) to cleanup remaining tunnels
- Debug mode (`-d`/`-v`) for log streaming
- Profile selection (`-p <profile>`)
- Encrypted backup and restore functionality
- Bash tab-completion
- Support for both Go-yq and Python-yq
- Installation and uninstallation scripts