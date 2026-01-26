.DEFAULT_GOAL := help
.PHONY: help setup run uninstall

help:
	@echo "Pre-Commit Hooks (Local Validation)"
	@echo "===================================="
	@echo ""
	@echo "Setup hooks (one-time):"
	@echo "  make hooks setup"
	@echo ""
	@echo "Run hooks manually:"
	@echo "  make hooks run"
	@echo ""
	@echo "Uninstall hooks:"
	@echo "  make hooks uninstall"
	@echo ""
	@echo "More info:"
	@echo "  See ADR-004 for detailed rationale"

setup:
	@echo "Setting up local Python virtual environment..."
	@cd ../.. && python3 -m venv .venv
	@echo "Installing development dependencies from requirements-dev.txt..."
	@cd ../.. && .venv/bin/pip install -r requirements-dev.txt
	@echo "Setting up pre-push hooks..."
	@cd ../.. && .venv/bin/pre-commit install --hook-type pre-push
	@echo "Setting up pre-commit hook for linting..."
	@cd ../.. && ln -sf ../../scripts/pre-commit-lint.sh .git/hooks/pre-commit
	@chmod +x ../../scripts/pre-commit-lint.sh
	@echo "✓ Development dependencies installed"
	@echo "✓ Pre-push hooks installed successfully"
	@echo "✓ Pre-commit linting hook installed"
	@echo ""
	@echo "Hooks will now run:"
	@echo "  - Before every commit (linting on staged .sh, .yml, .md files)"
	@echo "  - Before every push (all validation checks)"
	@echo ""
	@echo "To run manually:"
	@echo "  make test sh         - Check all shell scripts"
	@echo "  make test yaml       - Check all YAML files"
	@echo "  make test md         - Check all Markdown files"
	@echo "  make hooks run       - Run all pre-push checks"
	@echo ""
	@echo "To uninstall: make hooks uninstall"

run:
	@if [ -f ../../.venv/bin/pre-commit ]; then \
		echo "Running pre-commit hooks on all files..."; \
		cd ../.. && .venv/bin/pre-commit run --all-files; \
	else \
		echo "Error: pre-commit not installed"; \
		echo "Run 'make hooks setup' first"; \
		exit 1; \
	fi

uninstall:
	@if [ -f ../../.git/hooks/pre-push ]; then \
		cd ../.. && pre-commit uninstall --hook-type pre-push; \
		echo "✓ Pre-push hooks uninstalled"; \
	else \
		echo "Pre-push hooks are not installed"; \
	fi
	@if [ -L ../../.git/hooks/pre-commit ]; then \
		rm ../../.git/hooks/pre-commit; \
		echo "✓ Pre-commit hook uninstalled"; \
	else \
		echo "Pre-commit hook is not installed"; \
	fi
