.PHONY: hooks hooks-setup hooks-run hooks-uninstall

hooks: ## Show pre-commit hooks help
	@echo "Pre-Commit Hooks (Local Validation)"
	@echo "===================================="
	@echo ""
	@echo "Setup hooks (one-time):"
	@echo "  make hooks-setup"
	@echo ""
	@echo "Run hooks manually:"
	@echo "  make hooks-run"
	@echo ""
	@echo "Uninstall hooks:"
	@echo "  make hooks-uninstall"
	@echo ""
	@echo "More info:"
	@echo "  See ADR-004 for detailed rationale"

hooks-setup: ## Install pre-commit hooks for local development validation
	@command -v pre-commit >/dev/null 2>&1 || { \
		echo "Installing pre-commit framework..."; \
		pip3 install pre-commit; \
	}
	@echo "Setting up pre-commit hooks..."
	@pre-commit install --hook-type pre-push
	@echo "✓ Pre-commit hooks installed successfully"
	@echo ""
	@echo "Hooks will now run automatically before git push"
	@echo "To run hooks manually: make hooks-run"
	@echo "To uninstall: make hooks-uninstall"

hooks-run: ## Run pre-commit hooks manually on all files
	@command -v pre-commit >/dev/null 2>&1 || { \
		echo "Error: pre-commit not installed"; \
		echo "Run 'make hooks-setup' first"; \
		exit 1; \
	}
	@echo "Running pre-commit hooks on all files..."
	@pre-commit run --all-files

hooks-uninstall: ## Remove pre-commit hooks
	@if [ -f .git/hooks/pre-push ]; then \
		pre-commit uninstall --hook-type pre-push; \
		echo "✓ Pre-commit hooks uninstalled"; \
	else \
		echo "Pre-commit hooks are not installed"; \
	fi
