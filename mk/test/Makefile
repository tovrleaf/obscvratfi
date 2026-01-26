.DEFAULT_GOAL := help
.PHONY: help sh sh-all sh-commit

help:
	@echo "Testing Commands"
	@echo "================"
	@echo ""
	@echo "Run tests:"
	@echo "  make test sh              - Run shellcheck on all shell scripts"
	@echo "  make test sh-commit       - Run shellcheck on shell scripts in last commit"
	@echo ""
	@echo "More info:"
	@echo "  See ADR-004 for testing requirements"

sh:
	@echo "🔍 Running shellcheck on all shell scripts..."
	@cd ../.. && find scripts -name "*.sh" -type f -exec shellcheck --format=gcc {} +
	@echo "✅ Shellcheck complete"

sh-all: sh

sh-commit:
	@echo "🔍 Running shellcheck on shell scripts in last commit..."
	@cd ../.. && shell_files=$$(git diff-tree --no-commit-id --name-only -r HEAD | grep '\.sh$$'); \
	if [ -n "$$shell_files" ]; then \
		echo "$$shell_files" | xargs shellcheck --format=gcc && echo "✅ Shellcheck passed" || echo "❌ Shellcheck found issues"; \
	else \
		echo "ℹ️  No shell scripts in last commit"; \
	fi
