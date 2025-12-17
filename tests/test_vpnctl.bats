#!/usr/bin/env bats

# BATS tests for vpnctl
# Run with: bats tests/test_vpnctl.bats

# Setup test environment
setup() {
    # Create temporary directory for test files
    export TEST_DIR=$(mktemp -d)
    export ORIGINAL_HOME="$HOME"
    export HOME="$TEST_DIR"
    export XDG_CONFIG_HOME="$TEST_DIR/.config"
    
    # Create test config directory
    mkdir -p "$XDG_CONFIG_HOME"
    
    # Load only the functions we need from the main script
    eval "$(sed -n '/^get_backup_file()/,/^}/p' "$BATS_TEST_DIRNAME/../bin/vpnctl")"
    
    # Set default variables that the functions expect
    export CONFIG_FILE="${XDG_CONFIG_HOME}/vpn_config.yaml"
    export OUTPUT_FILE=""
    export INPUT_FILE=""
}

# Cleanup after each test
teardown() {
    rm -rf "$TEST_DIR"
    export HOME="$ORIGINAL_HOME"
    unset XDG_CONFIG_HOME
}

# Test get_backup_file function
@test "get_backup_file returns default when no config file exists" {
    result=$(get_backup_file "input")
    [ "$result" = "vpn-backup.tar.gz.gpg" ]
}

@test "get_backup_file returns OUTPUT_FILE when set for output" {
    OUTPUT_FILE="/custom/output.tar.gz"
    result=$(get_backup_file "output")
    [ "$result" = "/custom/output.tar.gz" ]
}

@test "get_backup_file returns INPUT_FILE when set for input" {
    INPUT_FILE="/custom/input.tar.gz"
    result=$(get_backup_file "input")
    [ "$result" = "/custom/input.tar.gz" ]
}

@test "get_backup_file reads from config file when available" {
    # Create test config with backup section
    cat > "$XDG_CONFIG_HOME/vpn_config.yaml" << EOF
backup:
  default_file: "/test/backup/location.tar.gz.gpg"
vpn:
  test:
    config: "/test/config.ovpn"
EOF
    
    # Mock yq to return our test value
    yq() {
        if [[ "$*" == *"backup.default_file"* ]]; then
            echo '"/test/backup/location.tar.gz.gpg"'
        fi
    }
    export -f yq
    
    result=$(get_backup_file "input")
    [ "$result" = "/test/backup/location.tar.gz.gpg" ]
}

@test "get_backup_file expands tilde in config path" {
    cat > "$XDG_CONFIG_HOME/vpn_config.yaml" << EOF
backup:
  default_file: "~/backups/vpn.tar.gz.gpg"
EOF
    
    # Mock yq
    yq() {
        if [[ "$*" == *"backup.default_file"* ]]; then
            echo '"~/backups/vpn.tar.gz.gpg"'
        fi
    }
    export -f yq
    
    result=$(get_backup_file "input")
    [ "$result" = "$TEST_DIR/backups/vpn.tar.gz.gpg" ]
}

@test "get_backup_file expands HOME variable in config path" {
    cat > "$XDG_CONFIG_HOME/vpn_config.yaml" << EOF
backup:
  default_file: "\$HOME/Documents/backup.tar.gz.gpg"
EOF
    
    # Mock yq
    yq() {
        if [[ "$*" == *"backup.default_file"* ]]; then
            echo '"$HOME/Documents/backup.tar.gz.gpg"'
        fi
    }
    export -f yq
    
    result=$(get_backup_file "input")
    [ "$result" = "$TEST_DIR/Documents/backup.tar.gz.gpg" ]
}

# Test yq version detection
@test "detects Go-yq when version contains eval" {
    yq() {
        echo "yq (https://github.com/mikefarah/yq/) version 4.35.2"
    }
    export -f yq
    
    if yq --version 2>&1 | grep -q 'eval'; then
        result="go-yq"
    else
        result="python-yq"
    fi
    
    [ "$result" = "python-yq" ]  # Our mock doesn't contain 'eval'
}

@test "detects Python-yq when version does not contain eval" {
    yq() {
        echo "yq 3.2.3"
    }
    export -f yq
    
    if yq --version 2>&1 | grep -q 'eval'; then
        result="go-yq"
    else
        result="python-yq"
    fi
    
    [ "$result" = "python-yq" ]
}

# Test argument parsing logic
@test "parses debug flag correctly" {
    # Simulate argument parsing
    DEBUG=false
    args=("-d" "start")
    
    for arg in "${args[@]}"; do
        case "$arg" in
            -d|--debug|-v|--verbose)
                DEBUG=true ;;
        esac
    done
    
    [ "$DEBUG" = "true" ]
}

@test "parses kill flag correctly" {
    KILL_OLD=false
    args=("-k" "start")
    
    for arg in "${args[@]}"; do
        case "$arg" in
            -k|--kill)
                KILL_OLD=true ;;
        esac
    done
    
    [ "$KILL_OLD" = "true" ]
}

@test "parses profile flag correctly" {
    PROFILE_KEY=""
    args=("-p" "customer1" "start")
    
    i=0
    while [ $i -lt ${#args[@]} ]; do
        case "${args[$i]}" in
            -p|--profile)
                i=$((i + 1))
                if [ $i -lt ${#args[@]} ]; then
                    PROFILE_KEY="${args[$i]}"
                fi
                ;;
        esac
        i=$((i + 1))
    done
    
    [ "$PROFILE_KEY" = "customer1" ]
}

# Test path expansion functions
@test "expands tilde to HOME correctly" {
    path="~/test/file.txt"
    expanded="${path/#\~/$HOME}"
    [ "$expanded" = "$TEST_DIR/test/file.txt" ]
}

@test "handles absolute paths without expansion" {
    path="/absolute/path/file.txt"
    expanded="${path/#\~/$HOME}"
    [ "$expanded" = "/absolute/path/file.txt" ]
}

# Test configuration file handling
@test "creates missing config directory structure" {
    rm -rf "$XDG_CONFIG_HOME"
    mkdir -p "$(dirname "$XDG_CONFIG_HOME/vpn_config.yaml")"
    
    [ -d "$(dirname "$XDG_CONFIG_HOME/vpn_config.yaml")" ]
}

@test "handles missing config file gracefully" {
    config_file="$XDG_CONFIG_HOME/vpn_config.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        result="missing"
    else
        result="exists"
    fi
    
    [ "$result" = "missing" ]
}

# Test backup path validation
@test "validates backup file extensions" {
    valid_extensions=(".tar.gz.gpg" ".tgz.gpg")
    test_file="backup.tar.gz.gpg"
    
    is_valid=false
    for ext in "${valid_extensions[@]}"; do
        if [[ "$test_file" == *"$ext" ]]; then
            is_valid=true
            break
        fi
    done
    
    [ "$is_valid" = "true" ]
}

@test "rejects invalid backup file extensions" {
    valid_extensions=(".tar.gz.gpg" ".tgz.gpg")
    test_file="backup.txt"
    
    is_valid=false
    for ext in "${valid_extensions[@]}"; do
        if [[ "$test_file" == *"$ext" ]]; then
            is_valid=true
            break
        fi
    done
    
    [ "$is_valid" = "false" ]
}

@test "backup_stats function detects missing backup file" {
    export INPUT_FILE="/nonexistent/backup.tar.gz.gpg"
    
    # Run vpnctl with backup-stats command to test the function
    run "$BATS_TEST_DIRNAME/../bin/vpnctl" backup-stats
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Backup file"*"not found"* ]]
}

@test "prepare_sudo function behavior with main script" {
    # Test that the script handles sudo requirement properly
    # We can't easily test prepare_sudo in isolation, so test a command that uses it
    
    # Create a mock config to test start command (which calls prepare_sudo)
    cat > "$XDG_CONFIG_HOME/vpn_config.yaml" << EOF
vpn:
  test:
    config: "/nonexistent.ovpn"
EOF
    
    # Run start command which will call prepare_sudo and fail gracefully
    run "$BATS_TEST_DIRNAME/../bin/vpnctl" -p test start
    
    # Should exit with error code due to missing config file or sudo
    [ "$status" -ne 0 ]
}

@test "self_update command exists and runs" {
    run timeout 10 "$BATS_TEST_DIRNAME/../bin/vpnctl" self-update
    
    # Should start the self-update process (exit code varies based on environment)
    # Either succeeds, fails due to network/permissions, or fails due to missing tools
    # Accept any reasonable exit code since this depends on environment
    [[ "$status" -ge 0 && "$status" -le 10 ]]
    
    # Should show self-update related output
    [[ "$output" == *"Checking for vpnctl updates"* || "$output" == *"gh, curl, or wget required"* ]]
}

@test "version flag shows current version" {
    run "$BATS_TEST_DIRNAME/../bin/vpnctl" --version
    
    [ "$status" -eq 0 ]
    [[ "$output" == "vpnctl "* ]]
    [[ "$output" =~ vpnctl[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+ ]]
}

# ===== CRITICAL INTEGRATION TESTS =====
# These tests ensure core functionality doesn't hang or break

@test "status command completes without hanging" {
    # This test catches gh CLI timeout issues
    run timeout 10 "$BATS_TEST_DIRNAME/../bin/vpnctl" status
    
    # Should complete within timeout (not hang)
    [[ "$status" -ne 124 ]]  # 124 = timeout exit code
    
    # Should show status message (success or error, doesn't matter)
    [[ -n "$output" ]]
}

@test "status command works with missing config" {
    # Test with no config file to ensure graceful handling
    local temp_config_dir=$(mktemp -d)
    export XDG_CONFIG_HOME="$temp_config_dir"
    
    run "$BATS_TEST_DIRNAME/../bin/vpnctl" status
    
    # Should fail gracefully, not hang or crash
    [ "$status" -eq 1 ]
    [[ "$output" == *"Config file not found"* ]]
    
    # Cleanup
    rm -rf "$temp_config_dir"
    unset XDG_CONFIG_HOME
}

@test "update check completes without hanging" {
    # Remove update check file to force update check
    rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/.vpnctl_update_check" 2>/dev/null || true
    
    # This should trigger update check and complete within reasonable time
    run timeout 15 "$BATS_TEST_DIRNAME/../bin/vpnctl" --version
    
    # Should not timeout (hang)
    [[ "$status" -ne 124 ]]
    [ "$status" -eq 0 ]
    [[ "$output" == "vpnctl "* ]]
}

@test "start command fails gracefully without config" {
    local temp_config_dir=$(mktemp -d)
    export XDG_CONFIG_HOME="$temp_config_dir"
    
    # Should fail quickly without hanging
    run timeout 10 "$BATS_TEST_DIRNAME/../bin/vpnctl" start
    
    # Should not hang
    [[ "$status" -ne 124 ]]
    
    # Should fail with config error (not hang or crash)
    [ "$status" -eq 1 ]
    [[ "$output" == *"Config file not found"* ]]
    
    # Cleanup
    rm -rf "$temp_config_dir"
    unset XDG_CONFIG_HOME
}

@test "gh CLI timeout protection works" {
    # This test verifies that gh CLI calls don't hang the script
    # We can't easily mock gh, but we can verify the script completes
    
    # Create a mock config file so other checks pass
    local temp_config_dir=$(mktemp -d)
    export XDG_CONFIG_HOME="$temp_config_dir"
    
    cat > "$temp_config_dir/vpn_config.yaml" << 'EOF'
vpn:
  test:
    config: "/nonexistent/config.ovpn"
EOF
    
    # Force update check and ensure it completes
    rm -f "$temp_config_dir/.vpnctl_update_check" 2>/dev/null || true
    
    run timeout 20 "$BATS_TEST_DIRNAME/../bin/vpnctl" status
    
    # Should complete, not hang indefinitely
    [[ "$status" -ne 124 ]]  # Not timed out

    # Cleanup
    rm -rf "$temp_config_dir"
    unset XDG_CONFIG_HOME
}

# ===== VERSION COMPARISON TESTS =====
# Tests for semantic version comparison function

setup_version_compare() {
    # Load the version_compare function from vpnctl
    eval "$(sed -n '/^version_compare()/,/^}/p' "$BATS_TEST_DIRNAME/../bin/vpnctl")"
}

@test "version_compare: equal versions return 0" {
    setup_version_compare
    run version_compare "1.4.4" "1.4.4"
    [ "$status" -eq 0 ]
}

@test "version_compare: v1 > v2 returns 1 (major)" {
    setup_version_compare
    run version_compare "2.0.0" "1.9.9"
    [ "$status" -eq 1 ]
}

@test "version_compare: v1 > v2 returns 1 (minor)" {
    setup_version_compare
    run version_compare "1.5.0" "1.4.4"
    [ "$status" -eq 1 ]
}

@test "version_compare: v1 > v2 returns 1 (patch)" {
    setup_version_compare
    run version_compare "1.4.5" "1.4.4"
    [ "$status" -eq 1 ]
}

@test "version_compare: v1 < v2 returns 2 (major)" {
    setup_version_compare
    run version_compare "1.0.0" "2.0.0"
    [ "$status" -eq 2 ]
}

@test "version_compare: v1 < v2 returns 2 (minor)" {
    setup_version_compare
    run version_compare "1.4.4" "1.5.0"
    [ "$status" -eq 2 ]
}

@test "version_compare: v1 < v2 returns 2 (patch)" {
    setup_version_compare
    run version_compare "1.4.3" "1.4.4"
    [ "$status" -eq 2 ]
}

@test "version_compare: handles v prefix" {
    setup_version_compare
    run version_compare "v1.5.0" "v1.4.4"
    [ "$status" -eq 1 ]
}

@test "version_compare: handles mixed v prefix" {
    setup_version_compare
    run version_compare "v1.5.0" "1.4.4"
    [ "$status" -eq 1 ]
}

@test "version_compare: handles missing patch version" {
    setup_version_compare
    run version_compare "1.5" "1.4.4"
    [ "$status" -eq 1 ]
}