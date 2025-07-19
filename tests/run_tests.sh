#!/usr/bin/env bash
#
# Test runner script for vpnctl
# Provides convenient test execution with reporting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $0 [OPTIONS] [TEST_FILES...]

Run BATS tests for vpnctl with reporting and coverage.

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Run tests with verbose output
    -t, --timing    Show test timing information
    -p, --pretty    Show pretty test progress
    -a, --all       Run all tests (default)
    -c, --coverage  Show test coverage report
    --install-bats  Install BATS if not available

EXAMPLES:
    $0                          # Run all tests
    $0 -v                       # Run with verbose output
    $0 test_vpnctl.bats         # Run specific test file
    $0 -c                       # Run tests with coverage report
    $0 --install-bats           # Install BATS on the system

TEST FILES:
    test_vpnctl.bats           # Core functionality tests
    test_set_backup.bats       # set-backup command tests  
    test_completion.bats       # Bash completion tests
EOF
}

check_bats() {
    if ! command -v bats &> /dev/null; then
        echo -e "${RED}ERROR:${NC} BATS (Bash Automated Testing System) is not installed."
        echo
        echo "Install BATS:"
        echo "  Ubuntu/Debian: sudo apt install bats"
        echo "  Fedora/RHEL:   sudo dnf install bats"  
        echo "  macOS:         brew install bats-core"
        echo "  Manual:        $0 --install-bats"
        echo
        return 1
    fi
}

install_bats() {
    echo -e "${BLUE}Installing BATS...${NC}"
    
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y bats
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y bats
    elif command -v yum &> /dev/null; then
        sudo yum install -y bats
    elif command -v brew &> /dev/null; then
        brew install bats-core
    else
        echo "Manual installation:"
        echo "git clone https://github.com/bats-core/bats-core.git /tmp/bats-core"
        echo "cd /tmp/bats-core && sudo ./install.sh /usr/local"
        return 1
    fi
    
    echo -e "${GREEN}BATS installed successfully!${NC}"
}

run_tests() {
    local bats_args=()
    local test_files=()
    
    # Parse arguments for BATS
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose) bats_args+=("--verbose-run") ;;
            -t|--timing) bats_args+=("--timing") ;;
            -p|--pretty) bats_args+=("--pretty") ;;
            *.bats) test_files+=("$SCRIPT_DIR/$1") ;;
            *) echo "Unknown option: $1" >&2; return 1 ;;
        esac
        shift
    done
    
    # If no test files specified, run all
    if [[ ${#test_files[@]} -eq 0 ]]; then
        test_files=("$SCRIPT_DIR"/*.bats)
    fi
    
    echo -e "${BLUE}Running vpnctl tests...${NC}"
    echo "Test directory: $SCRIPT_DIR"
    echo "Test files: ${test_files[*]##*/}"
    echo
    
    # Run BATS with specified arguments
    if bats "${bats_args[@]}" "${test_files[@]}"; then
        echo
        echo -e "${GREEN}✅ All tests passed!${NC}"
        return 0
    else
        echo
        echo -e "${RED}❌ Some tests failed!${NC}"
        return 1
    fi
}

show_coverage() {
    echo -e "${BLUE}Test Coverage Report${NC}"
    echo "====================="
    echo
    
    local total_functions=0
    local tested_functions=0
    
    # Count functions in main script
    echo "📊 Function Coverage:"
    while IFS= read -r func; do
        ((total_functions++))
        if grep -q "$func" "$SCRIPT_DIR"/*.bats 2>/dev/null; then
            echo -e "  ${GREEN}✅${NC} $func"
            ((tested_functions++))
        else
            echo -e "  ${RED}❌${NC} $func"
        fi
    done < <(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$PROJECT_ROOT/bin/vpnctl" | sed 's/().*//' | sort)
    
    echo
    echo "📈 Coverage Statistics:"
    echo "  Total functions: $total_functions"
    echo "  Tested functions: $tested_functions"
    
    if [[ $total_functions -gt 0 ]]; then
        local coverage=$((tested_functions * 100 / total_functions))
        if [[ $coverage -ge 25 ]]; then
            echo -e "  Coverage: ${GREEN}${coverage}%${NC}"
        elif [[ $coverage -ge 15 ]]; then
            echo -e "  Coverage: ${YELLOW}${coverage}%${NC}"
        else
            echo -e "  Coverage: ${RED}${coverage}%${NC}"
        fi
    fi
    
    echo
    echo "🎯 Test Categories:"
    echo "  Core functions:     $(grep -l "get_backup_file\|backup_stats\|set_backup_path" "$SCRIPT_DIR"/*.bats | wc -l) files"
    echo "  Argument parsing:   $(grep -l "parse.*arg\|DEBUG\|KILL_OLD" "$SCRIPT_DIR"/*.bats | wc -l) files"
    echo "  Bash completion:    $(grep -l "completion\|COMPREPLY" "$SCRIPT_DIR"/*.bats | wc -l) files"
    echo "  Configuration:      $(grep -l "config\|yaml" "$SCRIPT_DIR"/*.bats | wc -l) files"
    echo
    echo "💡 Coverage Tools:"
    echo "  Coverage analysis:  $SCRIPT_DIR/coverage.sh"
    echo "  Run with coverage:  $SCRIPT_DIR/coverage.sh run"
    echo "  HTML report:        $SCRIPT_DIR/coverage.sh html"
}

main() {
    local show_coverage=false
    local run_args=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            --install-bats)
                install_bats
                exit $?
                ;;
            -c|--coverage)
                show_coverage=true
                shift
                ;;
            -a|--all)
                # Default behavior, ignore
                shift
                ;;
            *)
                run_args+=("$1")
                shift
                ;;
        esac
    done
    
    # Check if BATS is available
    if ! check_bats; then
        exit 1
    fi
    
    # Show project info
    echo -e "${BLUE}vpnctl Test Suite${NC}"
    echo "================="
    echo "Project: $PROJECT_ROOT"
    echo "BATS version: $(bats --version)"
    echo
    
    # Run tests
    if ! run_tests "${run_args[@]}"; then
        exit 1
    fi
    
    # Show coverage if requested
    if [[ $show_coverage == true ]]; then
        echo
        show_coverage
    fi
}

main "$@"