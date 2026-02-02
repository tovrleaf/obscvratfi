#!/usr/bin/env bash
#
# Create GitHub Release from CHANGELOG.md
# Usage: create-github-release.sh

set -euo pipefail

CHANGELOG="CHANGELOG.md"

if [[ ! -f "$CHANGELOG" ]]; then
    echo "Error: $CHANGELOG not found" >&2
    exit 1
fi

# Extract current version
VERSION=$(grep -m 1 "^## \[" "$CHANGELOG" | sed -E 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/')

if [[ -z "$VERSION" ]]; then
    echo "Error: Could not find version in $CHANGELOG" >&2
    exit 1
fi

# Extract changelog entry for this version
# Get lines between first ## [ and second ## [
RELEASE_NOTES=$(awk '/^## \[/{if(++count==1){flag=1;next}else{flag=0}}flag' "$CHANGELOG" | sed '/^$/d')

if [[ -z "$RELEASE_NOTES" ]]; then
    echo "Error: Could not extract release notes for version $VERSION" >&2
    exit 1
fi

# Create GitHub release
echo "Creating GitHub release v$VERSION..."
gh release create "v$VERSION" \
    --title "v$VERSION" \
    --notes "$RELEASE_NOTES" \
    --latest

echo "✓ Release v$VERSION created successfully"
