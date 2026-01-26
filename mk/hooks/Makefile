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
	@command -v pre-commit >/dev/null 2>&1 || { \
		echo "Installing pre-commit framework..."; \
		pip3 install pre-commit; \
	}
	@echo "Setting up pre-commit hooks..."
	@cd ../.. && pre-commit install --hook-type pre-push
	@echo "Setting up post-commit hook for shellcheck..."
	@cd ../.. && ln -sf ../../scripts/post-commit-shellcheck.sh .git/hooks/post-commit
	@chmod +x ../../scripts/post-commit-shellcheck.sh
	@echo "✓ Pre-commit hooks installed successfully"
	@echo "✓ Post-commit shellcheck hook installed"
	@echo ""
	@echo "Hooks will now run:"
	@echo "  - After every commit (shellcheck on changed .sh files)"
	@echo "  - Before every push (all validation checks)"
	@echo ""
	@echo "To run manually:"
	@echo "  make test sh-commit    - Check shell scripts in last commit"
	@echo "  make hooks run         - Run all pre-push checks"
	@echo ""
	@echo "To uninstall: make hooks uninstall"

run:
	@command -v pre-commit >/dev/null 2>&1 || { \
		echo "Error: pre-commit not installed"; \
		echo "Run 'make hooks setup' first"; \
		exit 1; \
	}
	@echo "Running pre-commit hooks on all files..."
	@cd ../.. && pre-commit run --all-files

uninstall:
	@if [ -f ../../.git/hooks/pre-push ]; then \
		cd ../.. && pre-commit uninstall --hook-type pre-push; \
		echo "✓ Pre-push hooks uninstalled"; \
	else \
		echo "Pre-push hooks are not installed"; \
	fi
	@if [ -L ../../.git/hooks/post-commit ]; then \
		rm ../../.git/hooks/post-commit; \
		echo "✓ Post-commit hook uninstalled"; \
	else \
		echo "Post-commit hook is not installed"; \
	fi
