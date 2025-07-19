## [1.0.1](https://github.com/cdds-ab/vpnctl/compare/v1.0.0...v1.0.1) (2025-07-19)


### Bug Fixes

* remove automatic coverage badge update due to permission issues ([9e689d6](https://github.com/cdds-ab/vpnctl/commit/9e689d65f9340d16037d183e4e00d28f6e0ca0ae))

# 1.0.0 (2025-07-19)


* add backup analytics and configurable backup locations ([1f3514f](https://github.com/cdds-ab/vpnctl/commit/1f3514f479f450fbeda15d5246d23e1bf38c86fb))
* implement comprehensive test infrastructure and CI/CD pipeline ([341bb6a](https://github.com/cdds-ab/vpnctl/commit/341bb6a9b3b59788333d6533a09227ca4717ee26)), closes [#4](https://github.com/cdds-ab/vpnctl/issues/4)


### Bug Fixes

* remove npm cache and audit from release workflow ([5918077](https://github.com/cdds-ab/vpnctl/commit/5918077fa22714b4b945ed616fabe3c04453177b))
* resolve workflow reusability error in release pipeline ([0d6442e](https://github.com/cdds-ab/vpnctl/commit/0d6442e154126a292eb18e1844f8fdecd14b53ff))
* update README with correct repository URLs and automatic coverage badge updates ([06d4255](https://github.com/cdds-ab/vpnctl/commit/06d425553a442934efc82767536da899f95f3b73))


### Features

* implement automated GitHub releases with semantic versioning ([5756b29](https://github.com/cdds-ab/vpnctl/commit/5756b292bdadf7c44a5675aabe94c738e1097041))
* trigger initial automated release ([06f4ede](https://github.com/cdds-ab/vpnctl/commit/06f4ede12f055bb7ec1fb6500486e8ebaa4b6b16))


### BREAKING CHANGES

* This establishes new commit message conventions for automated releases

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
* none (purely additive)

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
* adds new backup section to vpn_config.yaml schema

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>

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
