#!/usr/bin/env bash
# Post-commit hook to run shellcheck on shell scripts in the commit
# Installed by: make hooks setup

# Get list of shell scripts in the last commit
shell_files=$(git diff-tree --no-commit-id --name-only -r HEAD | grep '\.sh$')

if [ -n "$shell_files" ]; then
    echo ""
    echo "🔍 Running shellcheck on committed shell scripts..."
    
    # Run shellcheck on each file
    if command -v shellcheck &> /dev/null; then
        echo "$shell_files" | xargs shellcheck --format=gcc
        exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo "✅ Shellcheck passed"
        else
            echo ""
            echo "❌ Shellcheck found issues in committed files"
            echo "   Commit was already made. To fix:"
            echo "   1. Fix the issues shown above"
            echo "   2. Run: git add <files>"
            echo "   3. Run: git commit --amend --no-edit"
            echo ""
        fi
    else
        echo "⚠️  shellcheck not found"
        echo "   Install with: brew install shellcheck"
        echo "   Or run: make hooks setup"
    fi
    echo ""
fi
