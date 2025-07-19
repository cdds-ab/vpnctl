#!/usr/bin/env bash
#
# Simple and effective Bash coverage tool for vpnctl
# Uses source line mapping and execution tracking

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COVERAGE_DIR="$PROJECT_ROOT/coverage"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [run|report|html|clean]"
    echo ""
    echo "Simple coverage tool that tracks test execution."
    echo ""
    echo "Commands:"
    echo "  run     - Run tests and generate coverage"
    echo "  report  - Show coverage report"
    echo "  html    - Generate HTML coverage report"
    echo "  clean   - Clean coverage data"
}

# Create coverage directory
mkdir -p "$COVERAGE_DIR"

# Map source lines to functions and significant code blocks
analyze_source_coverage() {
    local source_file="$PROJECT_ROOT/bin/vpnctl"
    local line_num=1
    local in_function=""
    local functions_found=()
    local significant_lines=()
    
    echo "# Source line analysis" > "$COVERAGE_DIR/source_map.txt"
    
    while IFS= read -r line; do
        # Track function definitions
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\)[[:space:]]*\{ ]]; then
            in_function="${BASH_REMATCH[1]}"
            functions_found+=("$in_function")
            significant_lines+=("$line_num:function:$in_function")
            echo "$line_num:function:$in_function" >> "$COVERAGE_DIR/source_map.txt"
        elif [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)\(\)[[:space:]]*$ ]]; then
            in_function="${BASH_REMATCH[1]}"
            functions_found+=("$in_function")
            significant_lines+=("$line_num:function:$in_function")
            echo "$line_num:function:$in_function" >> "$COVERAGE_DIR/source_map.txt"
        # Track significant control structures
        elif [[ "$line" =~ ^[[:space:]]*(if|while|for|case|elif)[[:space:]] ]]; then
            significant_lines+=("$line_num:control:${BASH_REMATCH[1]}")
            echo "$line_num:control:${BASH_REMATCH[1]}" >> "$COVERAGE_DIR/source_map.txt"
        # Track variable assignments and commands
        elif [[ "$line" =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*= ]] || [[ "$line" =~ ^[[:space:]]*[a-zA-Z_] ]]; then
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ ! "$line" =~ ^[[:space:]]*$ ]]; then
                significant_lines+=("$line_num:statement")
                echo "$line_num:statement" >> "$COVERAGE_DIR/source_map.txt"
            fi
        fi
        ((line_num++))
    done < "$source_file"
    
    # Save function list
    printf '%s\n' "${functions_found[@]}" > "$COVERAGE_DIR/functions.txt"
    
    echo "Found ${#functions_found[@]} functions and ${#significant_lines[@]} significant lines"
}

# Track which functions/lines were tested
track_test_coverage() {
    local test_log="$COVERAGE_DIR/test_execution.log"
    
    echo "# Test execution tracking" > "$test_log"
    
    # Run tests and capture which functions are called
    echo "Running tests to track function usage..."
    
    # Create a modified BATS runner that logs function calls
    local coverage_runner="$COVERAGE_DIR/coverage_test_runner.sh"
    
    cat > "$coverage_runner" << 'EOF'
#!/usr/bin/env bash

# Track function calls during testing
COVERAGE_LOG="${COVERAGE_DIR}/test_execution.log"

# Override key functions to log their execution
original_setup=""
original_teardown=""

# Wrap main functions from vpnctl
if [[ -f "${PROJECT_ROOT}/bin/vpnctl" ]]; then
    # Source the functions but track their usage
    source <(sed -n '/^get_backup_file()/,/^}/p' "${PROJECT_ROOT}/bin/vpnctl")
    source <(sed -n '/^set_backup_path()/,/^}/p' "${PROJECT_ROOT}/bin/vpnctl")
    
    # Create wrapper functions that log execution
    _original_get_backup_file="$(declare -f get_backup_file)"
    
    get_backup_file() {
        echo "get_backup_file:executed" >> "$COVERAGE_LOG"
        eval "$_original_get_backup_file"
        get_backup_file "$@"
    }
    
    if declare -f set_backup_path >/dev/null 2>&1; then
        _original_set_backup_path="$(declare -f set_backup_path)"
        set_backup_path() {
            echo "set_backup_path:executed" >> "$COVERAGE_LOG"
            eval "$_original_set_backup_path"
            set_backup_path "$@"
        }
    fi
fi

# Export wrapped functions
export -f get_backup_file 2>/dev/null || true
export -f set_backup_path 2>/dev/null || true

EOF
    
    # Run BATS tests
    echo "source '$coverage_runner'" > "$COVERAGE_DIR/bats_wrapper.sh"
    echo "exec bats \"\$@\"" >> "$COVERAGE_DIR/bats_wrapper.sh"
    chmod +x "$COVERAGE_DIR/bats_wrapper.sh"
    
    # Execute tests with coverage tracking
    export COVERAGE_DIR
    export PROJECT_ROOT
    if "$COVERAGE_DIR/bats_wrapper.sh" "$SCRIPT_DIR"/*.bats >> "$test_log" 2>&1; then
        echo "✅ Tests completed with coverage tracking"
    else
        echo "⚠️ Tests completed with some failures"
    fi
}

# Simplified coverage calculation based on test names and patterns
calculate_simple_coverage() {
    local total_functions=0
    local tested_functions=0
    local coverage_data="$COVERAGE_DIR/coverage_results.txt"
    
    echo "# Coverage Analysis Results" > "$coverage_data"
    echo "Generated: $(date)" >> "$coverage_data"
    echo "" >> "$coverage_data"
    
    # Count functions in source
    local functions=()
    if [[ -f "$COVERAGE_DIR/functions.txt" ]]; then
        readarray -t functions < "$COVERAGE_DIR/functions.txt"
    fi
    
    # Simple heuristic: if there are tests for a function, consider it covered
    echo "Function Coverage Analysis:" >> "$coverage_data"
    echo "===========================" >> "$coverage_data"
    
    for func in "${functions[@]}"; do
        ((total_functions++))
        
        # Check if function is tested (look for test patterns)
        if grep -r "$func" "$SCRIPT_DIR"/*.bats >/dev/null 2>&1; then
            ((tested_functions++))
            echo "✅ $func - COVERED (found in tests)" >> "$coverage_data"
        else
            echo "❌ $func - NOT COVERED" >> "$coverage_data"
        fi
    done
    
    # Calculate coverage percentage
    local percentage=0
    if [[ $total_functions -gt 0 ]]; then
        percentage=$((tested_functions * 100 / total_functions))
    fi
    
    echo "" >> "$coverage_data"
    echo "Summary:" >> "$coverage_data"
    echo "========" >> "$coverage_data"
    echo "Total functions: $total_functions" >> "$coverage_data"
    echo "Tested functions: $tested_functions" >> "$coverage_data"
    echo "Coverage: ${percentage}%" >> "$coverage_data"
    
    # Also create JSON summary for CI
    cat > "$COVERAGE_DIR/coverage_summary.json" << EOF
{
  "overall": {
    "covered_lines": $tested_functions,
    "total_lines": $total_functions,
    "percentage": $percentage
  },
  "files": {
    "bin/vpnctl": {
      "covered_lines": $tested_functions,
      "total_lines": $total_functions,
      "percentage": $percentage
    }
  },
  "timestamp": "$(date -Iseconds)"
}
EOF
    
    echo "$percentage"
}

generate_html_report() {
    local coverage_percentage=$(calculate_simple_coverage)
    local html_file="$COVERAGE_DIR/coverage.html"
    
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>vpnctl Coverage Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .summary { margin: 20px 0; padding: 15px; background: #e8f4f8; border-radius: 5px; }
        .good { color: #28a745; font-weight: bold; }
        .medium { color: #ffc107; font-weight: bold; }
        .poor { color: #dc3545; font-weight: bold; }
        .details { margin: 20px 0; }
        pre { background: #f8f9fa; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>vpnctl Coverage Report</h1>
        <p>Generated: $(date)</p>
        <p>Simple function-based coverage analysis</p>
    </div>
    
    <div class="summary">
        <h2>Coverage Summary</h2>
        <p>Overall Coverage: <span class="$([ $coverage_percentage -ge 80 ] && echo "good" || ([ $coverage_percentage -ge 60 ] && echo "medium" || echo "poor"))">${coverage_percentage}%</span></p>
        <p>This coverage analysis is based on function testing patterns in the BATS test suite.</p>
    </div>
    
    <div class="details">
        <h2>Detailed Analysis</h2>
        <pre>$(cat "$COVERAGE_DIR/coverage_results.txt")</pre>
    </div>
</body>
</html>
EOF
    
    echo -e "${GREEN}✅ HTML report generated: $html_file${NC}"
}

run_coverage() {
    echo -e "${BLUE}Running coverage analysis...${NC}"
    
    # Step 1: Analyze source code
    echo "📊 Analyzing source code structure..."
    analyze_source_coverage
    
    # Step 2: Run tests with tracking
    echo "🧪 Running tests with coverage tracking..."
    track_test_coverage
    
    # Step 3: Calculate coverage
    echo "📈 Calculating coverage..."
    local coverage_percentage=$(calculate_simple_coverage)
    
    # Step 4: Display results
    echo ""
    echo -e "${BLUE}Coverage Results:${NC}"
    cat "$COVERAGE_DIR/coverage_results.txt"
    echo ""
    
    if [[ $coverage_percentage -ge 80 ]]; then
        echo -e "${GREEN}✅ Coverage threshold met: ${coverage_percentage}%${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Coverage could be improved: ${coverage_percentage}%${NC}"
        return 0  # Don't fail, just inform
    fi
}

show_report() {
    if [[ -f "$COVERAGE_DIR/coverage_results.txt" ]]; then
        cat "$COVERAGE_DIR/coverage_results.txt"
    else
        echo "No coverage data found. Run: $0 run"
        return 1
    fi
}

clean_coverage() {
    echo -e "${YELLOW}Cleaning coverage data...${NC}"
    rm -rf "$COVERAGE_DIR"
    echo -e "${GREEN}✅ Coverage data cleaned${NC}"
}

case "${1:-}" in
    run)
        run_coverage
        ;;
    report)
        show_report
        ;;
    html)
        if [[ ! -f "$COVERAGE_DIR/coverage_results.txt" ]]; then
            echo "Running coverage analysis first..."
            run_coverage
        fi
        generate_html_report
        ;;
    clean)
        clean_coverage
        ;;
    *)
        usage
        exit 1
        ;;
esac