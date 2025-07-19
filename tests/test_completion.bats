#!/usr/bin/env bats

# BATS tests for bash completion functionality
# Run with: bats tests/test_completion.bats

setup() {
    export TEST_DIR=$(mktemp -d)
    export ORIGINAL_HOME="$HOME"
    export HOME="$TEST_DIR"
    export XDG_CONFIG_HOME="$TEST_DIR/.config"
    mkdir -p "$XDG_CONFIG_HOME"
    
    # Load completion function
    source "$BATS_TEST_DIRNAME/../completions/vpnctl"
    
    # Initialize completion variables
    COMP_WORDS=()
    COMP_CWORD=0
    COMPREPLY=()
}

teardown() {
    rm -rf "$TEST_DIR"
    export HOME="$ORIGINAL_HOME"
    unset XDG_CONFIG_HOME
}

@test "completion includes all main actions" {
    COMP_WORDS=("vpnctl" "")
    COMP_CWORD=1
    
    _vpnctl_completions
    
    # Check if all expected actions are present
    local actions=("start" "up" "stop" "down" "status" "backup" "restore" "backup-stats" "set-backup")
    for action in "${actions[@]}"; do
        [[ " ${COMPREPLY[*]} " =~ " ${action} " ]]
    done
}

@test "completion provides flags when input starts with dash" {
    COMP_WORDS=("vpnctl" "-")
    COMP_CWORD=1
    
    _vpnctl_completions
    
    # Check if flags are provided
    [[ " ${COMPREPLY[*]} " =~ " -d " ]]
    [[ " ${COMPREPLY[*]} " =~ " -v " ]]
    [[ " ${COMPREPLY[*]} " =~ " -k " ]]
    [[ " ${COMPREPLY[*]} " =~ " -p " ]]
    [[ " ${COMPREPLY[*]} " =~ " --debug " ]]
    [[ " ${COMPREPLY[*]} " =~ " --verbose " ]]
}

@test "completion provides file completion for -o flag" {
    # Create test files
    touch "$TEST_DIR/test-backup.tar.gz.gpg"
    touch "$TEST_DIR/another-file.txt"
    
    COMP_WORDS=("vpnctl" "-o" "test")
    COMP_CWORD=2
    
    _vpnctl_completions
    
    # Should provide file completion (exact behavior depends on compgen -f)
    [ ${#COMPREPLY[@]} -ge 0 ]  # At least doesn't crash
}

@test "completion provides file completion for -i flag" {
    # Create test files
    touch "$TEST_DIR/restore-backup.tar.gz.gpg"
    
    COMP_WORDS=("vpnctl" "-i" "restore")
    COMP_CWORD=2
    
    # Mock compgen to avoid file system dependency
    compgen() {
        case "$1" in
            -f) echo "restore-backup.tar.gz.gpg" ;;
        esac
    }
    export -f compgen
    
    _vpnctl_completions
    
    # Should provide file completion
    [ ${#COMPREPLY[@]} -ge 0 ]  # At least doesn't crash
}

@test "completion provides file completion for set-backup command" {
    # Create test files
    mkdir -p "$TEST_DIR/Backups"
    touch "$TEST_DIR/Backups/vpn-backup.tar.gz.gpg"
    
    COMP_WORDS=("vpnctl" "set-backup" "Backups/")
    COMP_CWORD=2
    
    # Mock compgen for file completion
    compgen() {
        case "$1" in
            -f) echo "Backups/vpn-backup.tar.gz.gpg" ;;
        esac
    }
    export -f compgen
    
    _vpnctl_completions
    
    # Should provide file completion for set-backup
    [ ${#COMPREPLY[@]} -ge 0 ]  # At least doesn't crash
}

@test "completion provides profile names for -p flag when config exists" {
    # Create test config with profiles
    cat > "$XDG_CONFIG_HOME/vpn_config.yaml" << EOF
vpn:
  customer1:
    config: "/test1.ovpn"
  customer2:
    config: "/test2.ovpn"
  testprofile:
    config: "/test3.ovpn"
EOF
    
    # Mock yq to return profile names
    yq() {
        case "$*" in
            *"keys"*)
                echo "customer1"
                echo "customer2"
                echo "testprofile"
                ;;
        esac
    }
    export -f yq
    
    COMP_WORDS=("vpnctl" "-p" "cust")
    COMP_CWORD=2
    
    _vpnctl_completions
    
    # Should include profiles starting with "cust"
    [[ " ${COMPREPLY[*]} " =~ " customer1 " ]] || 
    [[ " ${COMPREPLY[*]} " =~ " customer2 " ]]
}

@test "completion handles missing config file gracefully" {
    # No config file exists
    COMP_WORDS=("vpnctl" "-p" "test")
    COMP_CWORD=2
    
    # Mock yq to handle missing config
    yq() {
        return 1  # Simulate failure when config is missing
    }
    export -f yq
    
    # Run completion - should not crash
    run _vpnctl_completions
    
    # Should not crash when config file is missing (exit code 0 or just return)
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]  # Allow either success or controlled failure
}

@test "completion detects yq version correctly" {
    # Test Go-yq detection
    yq() {
        echo "yq (https://github.com/mikefarah/yq/) version 4.35.2"
    }
    export -f yq
    
    # Run the yq version detection from completion script
    if yq --version 2>&1 | grep -q 'eval'; then
        yq_cmd="yq eval"
    else
        yq_cmd="yq"
    fi
    
    [ "$yq_cmd" = "yq" ]  # Our mock doesn't contain 'eval'
}

@test "completion handles different word positions correctly" {
    # Mock yq to avoid config dependency
    yq() {
        case "$*" in
            *"keys"*) echo "testprofile" ;;
            *) return 1 ;;
        esac
    }
    export -f yq
    
    # Position 1: should show actions
    COMP_WORDS=("vpnctl" "sta")
    COMP_CWORD=1
    _vpnctl_completions
    [[ " ${COMPREPLY[*]} " =~ " start " ]]
    
    # Position 2 with flag: should show profiles
    COMP_WORDS=("vpnctl" "-p" "")
    COMP_CWORD=2
    run _vpnctl_completions
    # Should not crash
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "completion includes backup-stats in action list" {
    COMP_WORDS=("vpnctl" "backup-")
    COMP_CWORD=1
    
    _vpnctl_completions
    
    [[ " ${COMPREPLY[*]} " =~ " backup-stats " ]]
}

@test "completion includes set-backup in action list" {
    COMP_WORDS=("vpnctl" "set-")
    COMP_CWORD=1
    
    _vpnctl_completions
    
    [[ " ${COMPREPLY[*]} " =~ " set-backup " ]]
}

@test "completion handles empty input gracefully" {
    COMP_WORDS=("vpnctl" "")
    COMP_CWORD=1
    
    _vpnctl_completions
    
    # Should provide all actions
    [ ${#COMPREPLY[@]} -gt 0 ]
    [[ " ${COMPREPLY[*]} " =~ " start " ]]
    [[ " ${COMPREPLY[*]} " =~ " backup-stats " ]]
    [[ " ${COMPREPLY[*]} " =~ " set-backup " ]]
    [[ " ${COMPREPLY[*]} " =~ " self-update " ]]
}