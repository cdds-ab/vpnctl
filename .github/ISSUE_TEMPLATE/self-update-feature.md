---
name: Self-Update Feature Implementation  
about: Add automatic update checking and self-update functionality
title: 'feat: implement self-update functionality with automatic version checking'
labels: ['enhancement', 'feature']
assignees: ''
---

## Feature Request: Self-Update Functionality

### 📋 Description
Implement automated update checking and self-update capabilities for vpnctl to keep users on the latest version without manual intervention.

### 🎯 Requirements

#### A) Automatic Update Checking
- ✅ Check for new releases on GitHub on every `start`, `stop`, or `status` command
- ✅ Rate limit checks to maximum once per 24 hours to avoid API spam  
- ✅ Compare current version against latest GitHub release via API
- ✅ Display non-intrusive notification when update is available
- ✅ Graceful fallback if GitHub API is unavailable (no curl/wget)

#### B) Self-Update Command
- ✅ Add `vpnctl self-update` command for manual updates
- ✅ Download latest release from GitHub releases
- ✅ Verify downloaded version matches expected version
- ✅ Support both user and system installations (with/without sudo)
- ✅ Create backup of current version before updating
- ✅ Handle both curl and wget for maximum compatibility

### 🔧 Implementation Details

#### Version Management
```bash
CURRENT_VERSION="1.0.1"
GITHUB_REPO="cdds-ab/vpnctl"
UPDATE_CHECK_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/.vpnctl_update_check"
```

#### Update Check Flow
1. Check if last update check was < 24 hours ago
2. Query GitHub API for latest release tag
3. Compare versions (string comparison for semantic versions)
4. Display update notification if newer version available
5. Update timestamp file to prevent spam

#### Self-Update Flow  
1. Validate curl/wget availability
2. Fetch latest release information from GitHub API
3. Download latest vpnctl binary from GitHub releases
4. Verify download and version consistency
5. Create backup of current installation
6. Install new version (handling permissions appropriately)
7. Confirm successful update

### 🧪 Testing Requirements

- ✅ Test update checking with mock GitHub API responses
- ✅ Test graceful handling of network failures
- ✅ Test self-update command error handling
- ✅ Verify bash completion includes new `self-update` command
- ✅ Integration tests for both user and system installations

### 📚 Documentation Updates

- ✅ Update README with self-update feature description
- ✅ Add self-update to help text and command documentation
- ✅ Document requirements (curl/wget) in README
- ✅ Update bash completion for new command

### 🔐 Security Considerations

- Use HTTPS for all GitHub API calls and downloads
- Verify download integrity where possible
- Graceful permission handling for system vs user installs
- No automatic updates without explicit user consent
- Backup creation before any file modifications

### 💡 User Experience

**Update Check Notification:**
```bash
$ vpnctl start
🔄 Update available: 1.0.1 → 1.1.0
   Run 'vpnctl self-update' to update to the latest version

🚀 Starting 'default' → /home/user/.vpn/default.ovpn
...
```

**Self-Update Process:**
```bash
$ vpnctl self-update
🔄 Checking for vpnctl updates...
📦 Updating from 1.0.1 to 1.1.0...
⬇️  Downloading latest version...
🔧 Installing new version to /usr/local/bin/vpnctl...
🔒 Installing to system location, sudo required...
✅ Successfully updated to version 1.1.0
   Restart any running VPN connections to use the new version
```

### 🎯 Success Criteria

- [ ] Automatic update checking works on all VPN commands
- [ ] Self-update command successfully downloads and installs updates
- [ ] No breaking changes to existing functionality
- [ ] Comprehensive test coverage for new features
- [ ] Documentation reflects new capabilities
- [ ] Bash completion supports new command

### 🔗 Dependencies

- Requires curl or wget for HTTP requests
- Depends on GitHub releases being properly tagged with semantic versions
- Needs appropriate permissions for installation directory

### ⚠️ Edge Cases to Handle

- Network connectivity issues during update check/download
- GitHub API rate limiting
- Corrupted or incomplete downloads
- Permission issues during installation
- Version comparison edge cases
- Rollback scenario if update fails

---

**Priority:** High
**Effort:** Medium
**Impact:** High (significantly improves user experience and maintenance)