#!/usr/bin/env bash
# Pre-commit hook to run linters on staged files
# Installed by: make hooks setup
# Uses direct venv binaries instead of pre-commit framework

# Get staged files by type
shell_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$')
yaml_files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(yml|yaml)$')
md_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.md$')

has_issues=0

# Check shell scripts
if [ -n "$shell_files" ]; then
    echo ""
    echo "🔍 Running shellcheck on staged shell scripts..."
    if [ -f .venv/bin/shellcheck ]; then
        echo "$shell_files" | xargs .venv/bin/shellcheck --format=gcc || has_issues=1
    else
        echo "⚠️  shellcheck not found, skipping"
    fi
fi

# Check YAML files
if [ -n "$yaml_files" ]; then
    echo ""
    echo "🔍 Running yamllint on staged YAML files..."
    if [ -f .venv/bin/yamllint ]; then
        echo "$yaml_files" | xargs .venv/bin/yamllint --config-file=.github/yamllint-config.yml || has_issues=1
    else
        echo "⚠️  yamllint not found, skipping"
    fi
fi

# Check Markdown files
if [ -n "$md_files" ]; then
    echo ""
    echo "🔍 Running pymarkdown on staged Markdown files..."
    if [ -f .venv/bin/pymarkdown ]; then
        echo "$md_files" | xargs .venv/bin/pymarkdown --config .pymarkdownlnt scan || has_issues=1
    else
        echo "⚠️  pymarkdown not found, skipping"
    fi
fi

if [ $has_issues -eq 1 ]; then
    echo ""
    echo "❌ Linting found issues in staged files"
    echo "   Fix the issues and try committing again"
    echo "   Or bypass with: git commit --no-verify"
    echo ""
    exit 1
fi

exit 0

