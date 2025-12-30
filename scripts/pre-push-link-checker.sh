#!/bin/bash
# Pre-push link checker for Obscvrat website
# Validates critical internal links after Hugo build
# Part of ADR-005: Local Pre-Commit Hooks for Development Validation
#
# This script runs automatically before git push to verify essential links exist
# Usage: ./scripts/pre-push-link-checker.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SITE_DIR="${PWD}/website/public"
BASE_URL="http://localhost:1313"
CRITICAL_LINKS=(
  "/"
  "/about/"
  "/gigs/"
  "/albums/"
  "/feed.xml"
  "/sitemap.xml"
)

# Check if site has been built
if [ ! -d "$SITE_DIR" ]; then
    echo -e "${RED}✗ Error: Hugo site not built at $SITE_DIR${NC}"
    echo "Run 'make build' first to generate the static site"
    exit 1
fi

echo "🔗 Validating critical internal links..."
echo ""

FAILED_LINKS=()
CHECKED_COUNT=0

for link in "${CRITICAL_LINKS[@]}"; do
    CHECKED_COUNT=$((CHECKED_COUNT + 1))
    
    # Remove leading/trailing slashes for file path
    FILE_PATH="${link%/}"
    FILE_PATH="${FILE_PATH#/}"
    
    # Determine actual file path
    if [ "$FILE_PATH" = "" ]; then
        FILE_TO_CHECK="$SITE_DIR/index.html"
    elif [[ "$FILE_PATH" == *.xml ]]; then
        FILE_TO_CHECK="$SITE_DIR/$FILE_PATH"
    else
        FILE_TO_CHECK="$SITE_DIR/$FILE_PATH/index.html"
    fi
    
    if [ -f "$FILE_TO_CHECK" ]; then
        echo -e "${GREEN}✓${NC} $link"
    else
        echo -e "${RED}✗${NC} $link (missing: $FILE_TO_CHECK)"
        FAILED_LINKS+=("$link")
    fi
done

echo ""
echo "Checked $CHECKED_COUNT critical links"

if [ ${#FAILED_LINKS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All critical links are valid${NC}"
    exit 0
else
    echo -e "${RED}✗ ${#FAILED_LINKS[@]} link(s) failed:${NC}"
    for failed_link in "${FAILED_LINKS[@]}"; do
        echo -e "  ${RED}•${NC} $failed_link"
    done
    echo ""
    echo -e "${YELLOW}Tip: Run 'make build' to rebuild the site${NC}"
    exit 1
fi
