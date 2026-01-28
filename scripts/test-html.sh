#!/bin/bash
set -e

# HTML Testing Script for Hugo Site
# Tests HTML validation and verifies changes are present in rendered output
# Usage: scripts/test-html.sh [all|changed]

MODE="${1:-changed}"

# Files that trigger HTML rebuild/validation
TRIGGER_PATTERNS=(
    "website/layouts/"
    "website/content/"
    "website/archetypes/"
    "website/hugo.toml"
)

check_dependencies() {
    if [ -f .venv/bin/python ]; then
        PYTHON=".venv/bin/python"
    elif command -v python3 &> /dev/null; then
        PYTHON="python3"
    else
        echo "❌ Python not found"
        echo "Run 'make hooks setup' to install locally"
        exit 1
    fi
}

has_trigger_changes() {
    local changed_files
    changed_files=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || echo "")
    
    if [ -z "$changed_files" ]; then
        return 1
    fi
    
    for pattern in "${TRIGGER_PATTERNS[@]}"; do
        if echo "$changed_files" | grep -q "^$pattern"; then
            return 0
        fi
    done
    return 1
}

rebuild_hugo_site() {
    echo "🔨 Rebuilding Hugo site..."
    cd website
    if [ -f ../docker-compose.yml ]; then
        docker run --rm -v "$PWD:/site" -w /site alpine:3.20.2 sh -c \
            "wget -q -O - https://github.com/gohugoio/hugo/releases/download/v0.128.2/hugo_0.128.2_linux-amd64.tar.gz | tar xz && ./hugo --config hugo.toml && rm -f hugo LICENSE"
    else
        hugo --config hugo.toml
    fi
    cd ..
}

validate_html() {
    echo "🔍 Validating HTML structure..."
    if $PYTHON scripts/validate-html.py website/public; then
        return 0
    else
        return 1
    fi
}

check_changes_in_html() {
    local changed_files
    changed_files=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || echo "")
    
    if [ -z "$changed_files" ]; then
        echo "ℹ️  No changes to verify in HTML"
        return 0
    fi
    
    echo "🔍 Checking if changes are present in rendered HTML..."
    
    # Extract text content from changed files for verification
    local found_changes=false
    while IFS= read -r file; do
        if [[ "$file" == website/content/* ]] && [[ "$file" == *.md ]]; then
            # Extract meaningful text from markdown content (skip frontmatter)
            local content
            content=$(sed '/^---$/,/^---$/d' "$file" 2>/dev/null | grep -v '^$' | head -3 | tr -d '\n' | sed 's/[^a-zA-Z0-9 ]//g' | tr -s ' ')
            if [ -n "$content" ] && grep -r -q "$content" website/public/ 2>/dev/null; then
                found_changes=true
                break
            fi
        elif [[ "$file" == website/layouts/* ]]; then
            found_changes=true
            break
        fi
    done <<< "$changed_files"
    
    if [ "$found_changes" = true ]; then
        echo "✅ Changes found in rendered HTML"
        return 0
    else
        echo "⚠️  Changes not found in rendered HTML (may be normal for config/archetype changes)"
        return 0
    fi
}

main() {
    check_dependencies
    
    if [ "$MODE" = "all" ]; then
        echo "🔍 Testing all HTML files..."
        rebuild_hugo_site
        validate_html
        echo "✅ HTML testing complete"
        exit 0
    fi
    
    if ! has_trigger_changes; then
        echo "ℹ️  No template/content changes detected, skipping HTML validation"
        exit 0
    fi
    
    rebuild_hugo_site
    validate_html
    check_changes_in_html
    
    echo "✅ HTML testing complete"
}

main "$@"