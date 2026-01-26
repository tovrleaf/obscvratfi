#!/usr/bin/env bash
# Test HTML files with html5lib (pure Python, no Java)

set -euo pipefail

MODE="${1:-all}"  # all or changed

cd "$(dirname "$0")/.."

# Build Hugo site
echo "🔨 Building Hugo site..."
cd website && hugo --quiet && cd ..

# Python script to validate HTML using html5lib
validate_html() {
    .venv/bin/python3 - "$@" <<'PYTHON'
import sys
import html5lib
from pathlib import Path

def validate_file(filepath):
    try:
        with open(filepath, 'rb') as f:
            parser = html5lib.HTMLParser(strict=True)
            parser.parse(f)
        return True, None
    except Exception as e:
        return False, str(e)

errors = []
for filepath in sys.argv[1:]:
    path = Path(filepath)
    if path.suffix == '.html':
        valid, error = validate_file(filepath)
        if not valid:
            errors.append(f"{filepath}: {error}")

if errors:
    print("❌ HTML validation errors:")
    for error in errors:
        print(f"  {error}")
    sys.exit(1)
else:
    print(f"✅ Validated {len(sys.argv)-1} HTML files")
PYTHON
}

if [ "$MODE" = "changed" ]; then
    # Get website files that changed in last commit
    changed_files=$(git diff-tree --no-commit-id --name-only -r HEAD | grep '^website/' | grep -E '\.(html|md)$' || true)
    
    if [ -z "$changed_files" ]; then
        echo "ℹ️  No website files changed in last commit"
        exit 0
    fi
    
    echo "🔍 Validating HTML from changed files..."
    html_files=$(find website/public -name "*.html" 2>/dev/null || true)
    if [ -n "$html_files" ]; then
        validate_html $html_files
    fi
else
    echo "🔍 Validating all HTML files..."
    html_files=$(find website/public -name "*.html" 2>/dev/null || true)
    if [ -n "$html_files" ]; then
        validate_html $html_files
    else
        echo "⚠️  No HTML files found in website/public/"
        exit 1
    fi
fi
