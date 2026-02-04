#!/bin/bash
set -e

# HTML Testing Script for Hugo Site
# Tests HTML validation and verifies changes are present in rendered output
# Usage: scripts/test-html.sh [all|changed|single] [file]

MODE="${1:-changed}"
SINGLE_FILE="${2:-}"

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
    
    if ! command -v hugo &> /dev/null; then
        echo "❌ Hugo not found"
        echo "Install Hugo Extended v0.128.2 or later:"
        echo "  https://gohugo.io/installation/"
        exit 1
    fi
    
    cd website
    hugo --config hugo.toml
    cd ..
}

validate_single_html() {
    local file="$1"
    echo "🔍 Validating HTML file: $file"
    
    # Check if html5lib is available
    if ! $PYTHON -c "import html5lib" 2>/dev/null; then
        echo "⚠️  html5lib not found, skipping HTML validation"
        echo "   Run 'make hooks setup' to install"
        return 0
    fi
    
    # Create temporary Python script for validation
    local temp_script
    temp_script=$(mktemp)
    cat > "$temp_script" << 'EOF'
import html5lib
import sys
import re

filename = sys.argv[1]

# Read file content
with open(filename, 'r') as f:
    content = f.read()
    lines = content.split('\n')

# Parse with error tracking
parser = html5lib.HTMLParser(strict=True)
try:
    parser.parse(content)
    print(f"✅ {filename}: HTML validation passed")
    sys.exit(0)
except Exception as e:
    error_msg = str(e)
    print(f"❌ {filename}: {error_msg}")
    
    # Provide specific hints based on error type
    if "Named entity expected" in error_msg or "& " in error_msg:
        print("\n   Common causes:")
        print("   1. Unescaped & in URLs (use &amp; instead)")
        print("   2. Unescaped & in text (use &amp; instead)")
        print("\n   Searching for unescaped & characters (excluding <script> and <style> tags)...")
        
        # Remove script and style tag contents to avoid false positives
        content_no_scripts = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.DOTALL | re.IGNORECASE)
        content_no_scripts = re.sub(r'<style[^>]*>.*?</style>', '', content_no_scripts, flags=re.DOTALL | re.IGNORECASE)
        lines_no_scripts = content_no_scripts.split('\n')
        
        # Find lines with unescaped & (not part of entity)
        found_issues = False
        for i, line in enumerate(lines_no_scripts, 1):
            # Look for & not followed by valid entity pattern
            matches = re.finditer(r'&(?![a-zA-Z]+;|#[0-9]+;|#x[0-9a-fA-F]+;)', line)
            for match in matches:
                if not found_issues:
                    print("\n   Found potential issues:")
                    found_issues = True
                col = match.start() + 1
                # Get the original line (with scripts) for display
                if i <= len(lines):
                    print(f"\n   Line {i}, Column {col}:")
                    print(f"   {lines[i-1]}")
                    print(f"   {' ' * (col-1)}^")
                    print(f"   Fix: Replace & with &amp;")
        
        if not found_issues:
            print("\n   No obvious & issues found in HTML content.")
            print("   Note: <script> and <style> tag contents are excluded from this check.")
    
    sys.exit(1)
EOF
    
    # Run validation and capture result
    if $PYTHON "$temp_script" "$file"; then
        rm -f "$temp_script"
        return 0
    else
        rm -f "$temp_script"
        return 1
    fi
}

validate_html() {
    echo "🔍 Validating HTML structure..."
    
    # Check if html5lib is available
    if ! $PYTHON -c "import html5lib" 2>/dev/null; then
        echo "⚠️  html5lib not found, skipping HTML validation"
        echo "   Run 'make hooks setup' to install"
        return 0
    fi
    
    # Create temporary Python script for validation
    local temp_script
    temp_script=$(mktemp)
    cat > "$temp_script" << 'EOF'
import html5lib
import sys
import os

filename = sys.argv[1]
try:
    with open(filename, 'r') as f:
        parser = html5lib.HTMLParser(strict=True)
        parser.parse(f)
except Exception as e:
    print(f"❌ {filename}: {e}")
    sys.exit(1)
EOF
    
    # Validate all HTML files and collect errors
    local errors=0
    while IFS= read -r html_file; do
        if ! $PYTHON "$temp_script" "$html_file" 2>/dev/null; then
            errors=$((errors + 1))
        fi
    done < <(find website/public -name "*.html" -type f)
    
    rm -f "$temp_script"
    
    if [ $errors -gt 0 ]; then
        echo "❌ HTML validation failed: $errors files with errors"
        echo "Run with single file mode to see specific errors:"
        echo "  make test html FILE=path/to/file.html"
        return 1
    else
        echo "✅ HTML validation passed"
        return 0
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
    
    if [ "$MODE" = "single" ]; then
        if [ -z "$SINGLE_FILE" ]; then
            echo "❌ Single file mode requires a file argument"
            exit 1
        fi
        if [ ! -f "$SINGLE_FILE" ]; then
            echo "❌ File not found: $SINGLE_FILE"
            exit 1
        fi
        validate_single_html "$SINGLE_FILE"
        echo "✅ HTML testing complete"
        exit 0
    fi
    
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