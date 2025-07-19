#!/usr/bin/env bats

# BATS tests for set-backup functionality
# Run with: bats tests/test_set_backup.bats

setup() {
    # Create test environment
    export TEST_DIR=$(mktemp -d)
    export ORIGINAL_HOME="$HOME"
    export HOME="$TEST_DIR"
    export XDG_CONFIG_HOME="$TEST_DIR/.config"
    mkdir -p "$XDG_CONFIG_HOME"
    
    # Load functions from main script
    source <(sed -n '/^set_backup_path()/,/^}/p' "$BATS_TEST_DIRNAME/../bin/vpnctl")
    source <(sed -n '/^get_backup_file()/,/^}/p' "$BATS_TEST_DIRNAME/../bin/vpnctl")
    
    # Set test variables
    export BACKUP_PATH=""
}

teardown() {
    rm -rf "$TEST_DIR"
    export HOME="$ORIGINAL_HOME"
    unset XDG_CONFIG_HOME
}

# Mock yq for testing
mock_yq_go() {
    case "$*" in
        "--version"*)
            echo "yq (https://github.com/mikefarah/yq/) version 4.35.2 (with eval support)"
            ;;
        "eval"*"-i"*)
            # Go-yq eval with in-place edit: yq eval '.backup.default_file = "path"' -i file
            local config_file="${@: -1}"
            # Extract the path from the command
            local path_value
            path_value=$(echo "$*" | sed 's/.*= *"\([^"]*\)".*/\1/')
            
            # Create backup section if it doesn't exist, then update
            if ! grep -q "^backup:" "$config_file"; then
                echo "backup:" >> "$config_file"
            fi
            
            # Update or add default_file
            if grep -q "default_file:" "$config_file"; then
                sed -i 's|  default_file:.*|  default_file: "'"$path_value"'"|' "$config_file"
            else
                sed -i '/^backup:/a\  default_file: "'"$path_value"'"' "$config_file"
            fi
            ;;
    esac
}

mock_yq_python() {
    case "$*" in
        "--version"*)
            echo "yq 3.2.3"
            ;;
        *"backup.default_file"*)
            if [[ "$*" == *"-y"* && "$*" == *"-i"* ]]; then
                # Simulate Python-yq pipeline
                local config_file="${@: -1}"
                # Simple sed replacement for testing
                sed -i 's|default_file:.*|default_file: "'"$BACKUP_PATH"'"|' "$config_file"
            fi
            ;;
    esac
}

@test "set_backup_path creates config file when missing" {
    export BACKUP_PATH="/test/backup.tar.gz.gpg"
    export -f mock_yq_go
    alias yq=mock_yq_go
    
    # Run set_backup_path function
    run set_backup_path
    
    [ "$status" -eq 0 ]
    [ -f "$XDG_CONFIG_HOME/vpn_config.yaml" ]
    [[ "$output" == *"Config file created"* ]]
}

@test "set_backup_path updates existing config file with Go-yq" {
    # Create existing config
    cat > "$XDG_CONFIG_HOME/vpn_config.yaml" << EOF
backup:
  default_file: "/old/path.tar.gz.gpg"
vpn:
  test:
    config: "/test.ovpn"
EOF
    
    export BACKUP_PATH="/new/backup.tar.gz.gpg"
    export -f mock_yq_go
    alias yq=mock_yq_go
    
    run set_backup_path
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Backup path updated"* ]]
    grep -q "/new/backup.tar.gz.gpg" "$XDG_CONFIG_HOME/vpn_config.yaml"
}

@test "set_backup_path updates existing config file with Python-yq" {
    # Create existing config
    cat > "$XDG_CONFIG_HOME/vpn_config.yaml" << EOF
backup:
  default_file: "/old/path.tar.gz.gpg"
vpn:
  test:
    config: "/test.ovpn"
EOF
    
    export BACKUP_PATH="/new/backup.tar.gz.gpg"
    export -f mock_yq_python
    alias yq=mock_yq_python
    
    run set_backup_path
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Backup path updated"* ]]
}

@test "set_backup_path expands tilde in backup path" {
    export BACKUP_PATH="~/Documents/backup.tar.gz.gpg"
    export -f mock_yq_go
    alias yq=mock_yq_go
    
    run set_backup_path
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"$TEST_DIR/Documents/backup.tar.gz.gpg"* ]]
}

@test "set_backup_path expands HOME variable in backup path" {
    export BACKUP_PATH='$HOME/Backups/vpn.tar.gz.gpg'
    export -f mock_yq_go
    alias yq=mock_yq_go
    
    run set_backup_path
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"$TEST_DIR/Backups/vpn.tar.gz.gpg"* ]]
}

@test "set_backup_path handles absolute paths correctly" {
    export BACKUP_PATH="/var/backups/vpn-backup.tar.gz.gpg"
    export -f mock_yq_go
    alias yq=mock_yq_go
    
    run set_backup_path
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"/var/backups/vpn-backup.tar.gz.gpg"* ]]
}

@test "set_backup_path creates backup section in config without backup section" {
    # Create config without backup section
    cat > "$XDG_CONFIG_HOME/vpn_config.yaml" << EOF
vpn:
  test:
    config: "/test.ovpn"
EOF
    
    export BACKUP_PATH="/test/new-backup.tar.gz.gpg"
    export -f mock_yq_go
    alias yq=mock_yq_go
    
    run set_backup_path
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Backup path updated"* ]]
}

@test "set_backup_path preserves existing VPN configuration" {
    # Create config with VPN profiles
    cat > "$XDG_CONFIG_HOME/vpn_config.yaml" << EOF
backup:
  default_file: "/old/backup.tar.gz.gpg"
vpn:
  customer1:
    config: "/home/user/.vpn/customer1/config.ovpn"
  customer2:
    config: "/home/user/.vpn/customer2/config.ovpn"
EOF
    
    export BACKUP_PATH="/new/backup.tar.gz.gpg"
    export -f mock_yq_go
    alias yq=mock_yq_go
    
    run set_backup_path
    
    [ "$status" -eq 0 ]
    # Verify VPN section still exists
    grep -q "customer1" "$XDG_CONFIG_HOME/vpn_config.yaml"
    grep -q "customer2" "$XDG_CONFIG_HOME/vpn_config.yaml"
}

@test "backup file resolution prioritizes command line over config" {
    # Create config with backup path
    cat > "$XDG_CONFIG_HOME/vpn_config.yaml" << EOF
backup:
  default_file: "/config/backup.tar.gz.gpg"
EOF
    
    # Mock yq to return config value
    yq() {
        if [[ "$*" == *"backup.default_file"* ]]; then
            echo '"/config/backup.tar.gz.gpg"'
        fi
    }
    export -f yq
    
    # Test with INPUT_FILE set (command line priority)
    INPUT_FILE="/commandline/backup.tar.gz.gpg"
    result=$(get_backup_file "input")
    [ "$result" = "/commandline/backup.tar.gz.gpg" ]
    
    # Test without INPUT_FILE (config priority)
    unset INPUT_FILE
    result=$(get_backup_file "input")
    [ "$result" = "/config/backup.tar.gz.gpg" ]
}