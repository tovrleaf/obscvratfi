#!/usr/bin/env bash
# List current branch protection rulesets
# Shows all rulesets for the repository with their configuration
# Usage: ./scripts/list-branch-rules.sh
# Or: make show-branch-rules

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

# Verify gh CLI is installed
verify_gh_installed() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        echo "Install from: https://cli.github.com"
        exit 1
    fi
}

# Verify gh authentication
verify_gh_auth() {
    if ! gh auth status &> /dev/null; then
        log_error "Not authenticated with GitHub CLI"
        echo "Run: gh auth login"
        exit 1
    fi
}

# Extract repository info from git config
get_repo_info() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    local remote_url
    remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")
    
    if [ -z "$remote_url" ]; then
        log_error "No remote.origin.url found in git config"
        exit 1
    fi
    
    # Parse git@github.com:OWNER/REPO.git or https://github.com/OWNER/REPO.git
    if [[ $remote_url =~ git@github.com:([^/]+)/(.+)\.git$ ]]; then
        OWNER="${BASH_REMATCH[1]}"
        REPO="${BASH_REMATCH[2]}"
    elif [[ $remote_url =~ https://github.com/([^/]+)/(.+)\.git$ ]]; then
        OWNER="${BASH_REMATCH[1]}"
        REPO="${BASH_REMATCH[2]}"
    else
        log_error "Could not parse GitHub repository from: $remote_url"
        exit 1
    fi
}

# List all rulesets
list_rulesets() {
    log_info "Fetching rulesets for $OWNER/$REPO..."
    
    local rulesets
    rulesets=$(gh api repos/"$OWNER"/"$REPO"/rulesets --jq '.[] | {id, name, enforcement, branches: .conditions.ref_name.include}' 2>/dev/null || echo "")
    
    if [ -z "$rulesets" ]; then
        log_warning "No rulesets found"
        echo ""
        return 1
    fi
    
    echo ""
    echo "Branch Protection Rulesets:"
    echo "=============================="
    echo ""
    
    # Parse and display rulesets
    local count=0
    while IFS= read -r line; do
        if [[ $line =~ "id" ]]; then
            count=$((count + 1))
        fi
    done <<< "$rulesets"
    
    if [ "$count" -eq 0 ]; then
        log_warning "No rulesets found"
        echo ""
        return 1
    fi
    
    # Display using jq for better formatting
    gh api repos/"$OWNER"/"$REPO"/rulesets --jq '.[] | 
        "ID: \(.id) | Name: \(.name) | Enforcement: \(.enforcement) | Branches: \(.conditions.ref_name.include | join(\", \"))"' 2>/dev/null || true
    
    echo ""
    echo "To remove a ruleset, run:"
    echo "  ./scripts/remove-branch-protection.sh"
    echo "  or: make unprotect-main"
    echo ""
    return 0
}

# Main execution
main() {
    echo ""
    echo "========================================="
    echo "Branch Protection Rulesets"
    echo "========================================="
    echo ""
    
    log_info "Verifying prerequisites..."
    verify_gh_installed
    verify_gh_auth
    
    log_info "Detecting repository..."
    get_repo_info
    log_success "Repository: $OWNER/$REPO"
    
    echo ""
    list_rulesets
}

main "$@"
