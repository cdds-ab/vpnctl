# vpnctl Tests

This directory contains BATS (Bash Automated Testing System) tests for vpnctl.

## Prerequisites

Install BATS on your system:

```bash
# Ubuntu/Debian
sudo apt install bats

# Fedora/CentOS/RHEL
sudo dnf install bats

# macOS with Homebrew
brew install bats-core

# Manual installation
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

### Run All Tests
```bash
# From vpnctl root directory
bats tests/

# Or run individual test files
bats tests/test_vpnctl.bats
bats tests/test_set_backup.bats
bats tests/test_completion.bats
```

### Run with Verbose Output
```bash
bats -t tests/  # Show test timing
bats -p tests/  # Show test progress
```

## Test Structure

### `test_vpnctl.bats`
Core functionality tests:
- `get_backup_file()` function testing
- Path expansion and resolution
- yq version detection
- Argument parsing logic
- Configuration file handling

### `test_set_backup.bats`
Tests for the `set-backup` functionality:
- Config file creation and updates
- Go-yq and Python-yq compatibility
- Path expansion in backup paths
- Backup file resolution priorities
- VPN configuration preservation

### `test_completion.bats`
Bash completion testing:
- Action completion (start, stop, backup-stats, set-backup)
- Flag completion (-d, -v, -k, -p, etc.)
- File completion for backup paths
- Profile completion for -p flag
- Error handling for missing configs

## Test Environment

Each test runs in an isolated environment:
- Temporary `$HOME` directory
- Isolated `$XDG_CONFIG_HOME`
- Mocked external dependencies (yq, jq, gpg)
- No actual VPN operations

## Mocking Strategy

### External Dependencies
- **yq**: Mocked for both Go-yq and Python-yq variants
- **jq**: Mocked for JSON processing
- **gpg**: Not tested (requires integration tests)
- **openvpn**: Not tested (requires system-level testing)

### File Operations
- All file operations use temporary directories
- No modification of real user configs
- Safe cleanup after each test

## Writing New Tests

### Test Function Format
```bash
@test "descriptive test name" {
    # Setup test data
    export TEST_VAR="value"
    
    # Run function or command
    run function_to_test
    
    # Assert results
    [ "$status" -eq 0 ]  # Exit code
    [[ "$output" == *"expected"* ]]  # Output content
}
```

### Best Practices
1. **Isolated tests**: Each test should be independent
2. **Clear names**: Test names should describe what is being tested
3. **Mock externals**: Mock yq, jq, and other external tools
4. **Clean setup/teardown**: Use setup() and teardown() functions
5. **Test edge cases**: Include error conditions and boundary cases

## Coverage

Current test coverage includes:
- ✅ Core backup file resolution logic
- ✅ Configuration file handling
- ✅ Path expansion and normalization
- ✅ yq version detection and compatibility
- ✅ Bash completion functionality
- ✅ set-backup command functionality
- ⏳ Integration tests (future)
- ❌ VPN operations (requires system tests)
- ❌ GPG operations (requires integration tests)

## Future Improvements

1. **Integration Tests**: Test with real yq/jq/gpg
2. **System Tests**: Test VPN operations in containers
3. **Performance Tests**: Test with large config files
4. **Error Handling**: More comprehensive error condition testing
5. **Mock Improvements**: More sophisticated external tool mocking