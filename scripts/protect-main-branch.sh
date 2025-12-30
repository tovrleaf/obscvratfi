#!/usr/bin/env bash
# Protect main branch with GitHub Repository Ruleset
# Automatically creates a ruleset to enforce PR workflow and CI/CD checks
# Usage: ./scripts/protect-main-branch.sh
# Or: make protect-main
# See ADR-006 for complete rationale

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RULESET_NAME="Protect Main Branch"
TARGET_BRANCH="main"

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
    log_success "GitHub CLI found"
}

# Verify gh authentication
verify_gh_auth() {
    if ! gh auth status &> /dev/null; then
        log_error "Not authenticated with GitHub CLI"
        echo "Run: gh auth login"
        exit 1
    fi
    log_success "GitHub authentication verified"
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
    
    log_success "Repository detected: $OWNER/$REPO"
}

# Check if ruleset already exists
check_existing_ruleset() {
    if gh api repos/"$OWNER"/"$REPO"/rulesets --jq ".[] | select(.name==\"$RULESET_NAME\") | .id" 2>/dev/null | grep -q .; then
        log_warning "Ruleset '$RULESET_NAME' already exists"
        return 0  # Ruleset exists
    fi
    return 1  # Ruleset does not exist
}

# Create the branch protection ruleset
create_ruleset() {
    log_info "Creating ruleset..."
    
    local response
    response=$(gh api repos/"$OWNER"/"$REPO"/rulesets \
        --method POST \
        -f name="$RULESET_NAME" \
        -f target='branch' \
        -f enforcement='active' \
        -F conditions='{"ref_name":{"include":["refs/heads/main"]}}' \
        -F rules='[
            {
                "type": "pull_request",
                "parameters": {
                    "required_approving_review_count": 1,
                    "dismiss_stale_reviews_on_push": true,
                    "require_code_owner_review": false,
                    "require_last_push_approval": false,
                    "required_review_thread_resolution": true,
                    "allowed_merge_methods": ["merge", "squash", "rebase"]
                }
            },
            {
                "type": "required_status_checks",
                "parameters": {
                    "strict_required_status_checks_policy": true,
                    "required_status_checks": [
                        {
                            "context": "pr-checks.yml"
                        }
                    ]
                }
            }
        ]' 2>&1)
    
    if echo "$response" | grep -q '"id"'; then
        local ruleset_id
        ruleset_id=$(echo "$response" | jq -r '.id')
        log_success "Ruleset created successfully (ID: $ruleset_id)"
        return 0
    else
        log_error "Failed to create ruleset"
        echo "$response"
        return 1
    fi
}

# Main execution
main() {
    echo ""
    echo "========================================="
    echo "Protect Main Branch with GitHub Ruleset"
    echo "========================================="
    echo ""
    
    log_info "Verifying prerequisites..."
    verify_gh_installed
    verify_gh_auth
    
    log_info "Detecting repository..."
    get_repo_info
    
    echo ""
    
    if check_existing_ruleset; then
        log_warning "Ruleset already exists - no action needed"
        echo ""
        echo "View rules with: ./scripts/list-branch-rules.sh"
        echo "             or: make show-branch-rules"
        echo ""
        exit 0
    fi
    
    log_info "Setting up branch protection for '$TARGET_BRANCH' branch..."
    create_ruleset
    
    echo ""
    log_success "Setup complete!"
    echo ""
    echo "Branch protection is now active:"
    echo "  • Direct pushes to main are blocked"
    echo "  • Pull requests required"
    echo "  • 1 approval required (self-approval allowed)"
    echo "  • GitHub Actions (pr-checks.yml) must pass"
    echo "  • All conversations must be resolved"
    echo ""
    echo "Verify rules with: ./scripts/list-branch-rules.sh"
    echo "              or: make show-branch-rules"
    echo ""
    echo "Remove rules with: ./scripts/remove-branch-protection.sh"
    echo "               or: make unprotect-main"
    echo ""
}

main "$@"
