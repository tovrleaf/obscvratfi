#!/usr/bin/env bash
#
# Bump version in CHANGELOG.md
# Usage: bump-version.sh [major|minor|patch]

set -euo pipefail

BUMP_TYPE="${1:-patch}"
CHANGELOG="CHANGELOG.md"
DATA_CHANGELOG="website/data/changelog.txt"

if [[ ! -f "$CHANGELOG" ]]; then
    echo "Error: $CHANGELOG not found" >&2
    exit 1
fi

# Extract current version from CHANGELOG.md
CURRENT_VERSION=$(grep -m 1 "^## \[" "$CHANGELOG" | sed -E 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/')

if [[ -z "$CURRENT_VERSION" ]]; then
    echo "Error: Could not find current version in $CHANGELOG" >&2
    exit 1
fi

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Bump version based on type
case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Error: Invalid bump type '$BUMP_TYPE'. Use: major, minor, or patch" >&2
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
TODAY=$(date +%Y-%m-%d)

# Create new changelog entry
NEW_ENTRY="## [$NEW_VERSION] - $TODAY

### Added

### Changed

### Fixed

"

# Insert new entry after the header (after line starting with "##")
# Find the line number of the first version entry
FIRST_VERSION_LINE=$(grep -n "^## \[" "$CHANGELOG" | head -1 | cut -d: -f1)

if [[ -z "$FIRST_VERSION_LINE" ]]; then
    echo "Error: Could not find version entry in $CHANGELOG" >&2
    exit 1
fi

# Insert new entry before the first version
{
    head -n $((FIRST_VERSION_LINE - 1)) "$CHANGELOG"
    echo "$NEW_ENTRY"
    tail -n +$FIRST_VERSION_LINE "$CHANGELOG"
} > "$CHANGELOG.tmp"

mv "$CHANGELOG.tmp" "$CHANGELOG"

# Copy to website/data for Hugo
cp "$CHANGELOG" "$DATA_CHANGELOG"

echo "$NEW_VERSION"
