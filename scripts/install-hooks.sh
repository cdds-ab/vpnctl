#!/usr/bin/env bash
#
# Install git hooks for vpnctl project
#
# This script sets up pre-commit hooks that run tests, linting,
# and GitHub CLI checks before allowing commits.
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Installing git hooks for vpnctl...${NC}"

# Check if we're in a git repository
if [[ ! -d ".git" ]]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install pre-commit hook
echo -e "${YELLOW}📋 Installing pre-commit hook...${NC}"
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo -e "${GREEN}✅ Pre-commit hook installed successfully!${NC}"
echo ""
echo -e "${BLUE}🎯 What happens now:${NC}"
echo "• Before each commit, the hook will automatically run:"
echo "  - BATS tests (all must pass)"
echo "  - Shellcheck linting (no warnings allowed)"
echo "  - Basic functionality test"
echo "  - GitHub CLI checks (if available)"
echo "  - Security scan for secrets"
echo ""
echo -e "${YELLOW}💡 To bypass the hook temporarily (NOT recommended):${NC}"
echo "   git commit --no-verify"
echo ""
echo -e "${YELLOW}🔧 To uninstall the hook:${NC}"
echo "   rm .git/hooks/pre-commit"
echo ""
echo -e "${GREEN}🚀 Ready! Your next commit will be automatically checked.${NC}"