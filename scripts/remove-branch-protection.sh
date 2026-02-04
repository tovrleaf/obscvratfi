#!/usr/bin/env bash
# Remove branch protection ruleset (emergency rollback)
# WARNING: This removes branch protection from the main branch
# Usage: ./scripts/remove-branch-protection.sh
# Or: make unprotect-main

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

# List rulesets and let user choose one to delete
select_ruleset_to_delete() {
    log_info "Fetching rulesets..."
    
    local rulesets_json
    rulesets_json=$(gh api repos/"$OWNER"/"$REPO"/rulesets --jq '.[]' 2>/dev/null || echo "")
    
    if [ -z "$rulesets_json" ]; then
        log_warning "No rulesets found"
        echo ""
        return 1
    fi
    
    echo ""
    echo "Current rulesets:"
    echo "================="
    echo ""
    
    # Create associative array for ID -> name mapping
    declare -A id_map
    declare -a ids_array
    
    while IFS= read -r id name branches enforcement; do
        id_map["$id"]="$name | Branches: $branches | Status: $enforcement"
        ids_array+=("$id")
        echo "  ID: $id"
        echo "      Name: $name"
        echo "      Branches: $branches"
        echo "      Status: $enforcement"
        echo ""
    done < <(gh api repos/"$OWNER"/"$REPO"/rulesets --jq '.[] | "\(.id) \(.name) \(.conditions.ref_name.include | join(\", \")) \(.enforcement)"' 2>/dev/null)
    
    if [ ${#ids_array[@]} -eq 0 ]; then
        log_warning "No rulesets found"
        echo ""
        return 1
    fi
    
    echo ""
    read -p "Enter ruleset ID to delete (or Ctrl+C to cancel): " selected_id
    
    # Check if selected_id is in ids_array
    found=false
    for id in "${ids_array[@]}"; do
        if [[ "$id" == "$selected_id" ]]; then
            found=true
            break
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        log_error "Invalid ruleset ID: $selected_id"
        exit 1
    fi
    
    RULESET_ID="$selected_id"
    return 0
}

# Confirm deletion with warnings
confirm_deletion() {
    echo ""
    log_warning "WARNING: You are about to DELETE a branch protection ruleset"
    echo ""
    echo "Ruleset details:"
    gh api repos/"$OWNER"/"$REPO"/rulesets/"$RULESET_ID" --jq '"\(.name) | Branches: \(.conditions.ref_name.include | join(\", \")) | Status: \(.enforcement)"' 2>/dev/null || return 1
    echo ""
    log_warning "After deletion:"
    echo "  • Direct pushes to protected branches will be ALLOWED"
    echo "  • Pull request workflow will no longer be enforced"
    echo "  • CI/CD checks will no longer be required"
    echo "  • Code review will no longer be enforced"
    echo ""
    
    read -p "Are you SURE you want to delete this ruleset? (type 'yes' to confirm): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        log_info "Deletion cancelled"
        echo ""
        exit 0
    fi
}

# Delete the ruleset
delete_ruleset() {
    log_info "Deleting ruleset $RULESET_ID..."
    
    if gh api repos/"$OWNER"/"$REPO"/rulesets/"$RULESET_ID" --method DELETE 2>/dev/null; then
        log_success "Ruleset deleted successfully"
        echo ""
        log_warning "Branch protection has been removed!"
        echo ""
        return 0
    else
        log_error "Failed to delete ruleset"
        echo ""
        return 1
    fi
}

# Main execution
main() {
    echo ""
    echo "========================================="
    echo "Remove Branch Protection Ruleset"
    echo "========================================="
    echo ""
    log_warning "EMERGENCY ROLLBACK MODE"
    echo ""
    
    log_info "Verifying prerequisites..."
    verify_gh_installed
    verify_gh_auth
    
    log_info "Detecting repository..."
    get_repo_info
    log_success "Repository: $OWNER/$REPO"
    
    echo ""
    
    if ! select_ruleset_to_delete; then
        exit 1
    fi
    
    confirm_deletion
    delete_ruleset
}

main "$@"
