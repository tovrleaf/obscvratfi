.DEFAULT_GOAL := help
.PHONY: help sh sh-all sh-commit yaml yaml-all yaml-commit md md-all md-commit html html-all html-commit secrets secrets-all links py py-all

help:
	@echo "Testing Commands"
	@echo "================"
	@echo ""
	@echo "Test all files:"
	@echo "  make test sh              - Run shellcheck on all shell scripts"
	@echo "  make test yaml            - Run yamllint on all YAML files"
	@echo "  make test md              - Run pymarkdown on all Markdown files"
	@echo "  make test html            - Run html5lib on all HTML files"
	@echo "  make test py              - Run pytest and ruff on Python files"
	@echo "  make test secrets         - Run detect-secrets on all files"
	@echo "  make test links           - Check critical internal links"
	@echo ""
	@echo "Test committed files:"
	@echo "  make test sh-commit       - Run shellcheck on shell scripts in last commit"
	@echo "  make test yaml-commit     - Run yamllint on YAML files in last commit"
	@echo "  make test md-commit       - Run pymarkdown on Markdown files in last commit"
	@echo "  make test html-commit     - Run html5lib on HTML from changed files"
	@echo ""
	@echo "More info:"
	@echo "  See ADR-004 for testing requirements"

sh:
	@echo "🔍 Running shellcheck on all shell scripts..."
	@if [ -f ../../.venv/bin/shellcheck ]; then \
		cd ../.. && find scripts -name "*.sh" -type f -exec .venv/bin/shellcheck --format=gcc {} +; \
		echo "✅ Shellcheck complete"; \
	elif command -v shellcheck >/dev/null 2>&1; then \
		cd ../.. && find scripts -name "*.sh" -type f -exec shellcheck --format=gcc {} +; \
		echo "✅ Shellcheck complete"; \
	else \
		echo "❌ shellcheck not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

sh-all: sh

sh-commit:
	@echo "🔍 Running shellcheck on shell scripts in last commit..."
	@if [ -f ../../.venv/bin/shellcheck ]; then \
		cd ../.. && shell_files=$$(git diff-tree --no-commit-id --name-only -r HEAD | grep '\.sh$$'); \
		if [ -n "$$shell_files" ]; then \
			echo "$$shell_files" | xargs .venv/bin/shellcheck --format=gcc && echo "✅ Shellcheck passed" || echo "❌ Shellcheck found issues"; \
		else \
			echo "ℹ️  No shell scripts in last commit"; \
		fi; \
	elif command -v shellcheck >/dev/null 2>&1; then \
		cd ../.. && shell_files=$$(git diff-tree --no-commit-id --name-only -r HEAD | grep '\.sh$$'); \
		if [ -n "$$shell_files" ]; then \
			echo "$$shell_files" | xargs shellcheck --format=gcc && echo "✅ Shellcheck passed" || echo "❌ Shellcheck found issues"; \
		else \
			echo "ℹ️  No shell scripts in last commit"; \
		fi; \
	else \
		echo "❌ shellcheck not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

yaml:
	@echo "🔍 Running yamllint on all YAML files..."
	@if [ -f ../../.venv/bin/yamllint ]; then \
		cd ../.. && find . -name "*.yml" -o -name "*.yaml" | grep -v ".venv" | xargs .venv/bin/yamllint -c .github/yamllint-config.yml; \
		echo "✅ Yamllint complete"; \
	else \
		echo "❌ yamllint not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

yaml-all: yaml

yaml-commit:
	@echo "🔍 Running yamllint on YAML files in last commit..."
	@if [ -f ../../.venv/bin/yamllint ]; then \
		cd ../.. && yaml_files=$$(git diff-tree --no-commit-id --name-only -r HEAD | grep -E '\.(yml|yaml)$$'); \
		if [ -n "$$yaml_files" ]; then \
			echo "$$yaml_files" | xargs .venv/bin/yamllint -c .github/yamllint-config.yml && echo "✅ Yamllint passed" || echo "❌ Yamllint found issues"; \
		else \
			echo "ℹ️  No YAML files in last commit"; \
		fi; \
	else \
		echo "❌ yamllint not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

md:
	@echo "🔍 Running pymarkdown on all Markdown files..."
	@if [ -f ../../.venv/bin/pymarkdown ]; then \
		cd ../.. && find . -name "*.md" | grep -v ".venv" | xargs .venv/bin/pymarkdown --config .pymarkdownlnt scan; \
		echo "✅ Pymarkdown complete"; \
	else \
		echo "❌ pymarkdown not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

md-all: md

md-commit:
	@echo "🔍 Running pymarkdown on Markdown files in last commit..."
	@if [ -f ../../.venv/bin/pymarkdown ]; then \
		cd ../.. && md_files=$$(git diff-tree --no-commit-id --name-only -r HEAD | grep '\.md$$'); \
		if [ -n "$$md_files" ]; then \
			echo "$$md_files" | xargs .venv/bin/pymarkdown --config .pymarkdownlnt scan && echo "✅ Pymarkdown passed" || echo "❌ Pymarkdown found issues"; \
		else \
			echo "ℹ️  No Markdown files in last commit"; \
		fi; \
	else \
		echo "❌ pymarkdown not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

html:
	@echo "🔍 Running HTML validation on all files..."
	@cd ../.. && chmod +x scripts/test-html.sh && scripts/test-html.sh all

html-all: html

html-commit:
	@echo "🔍 Running HTML validation on changed files..."
	@if [ -f ../../.venv/bin/python ]; then \
		cd ../.. && chmod +x scripts/test-html.sh && scripts/test-html.sh changed; \
	elif command -v python3 >/dev/null 2>&1; then \
		cd ../.. && chmod +x scripts/test-html.sh && scripts/test-html.sh changed; \
	else \
		echo "❌ Python not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

secrets: # pragma: allowlist secret
	@echo "🔍 Running detect-secrets on all files..." # pragma: allowlist secret
	@if [ -f ../../.venv/bin/detect-secrets ]; then \ # pragma: allowlist secret
		cd ../.. && .venv/bin/detect-secrets scan; \ # pragma: allowlist secret
	else \
		echo "❌ detect-secrets not found"; \ # pragma: allowlist secret
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

secrets-all: secrets # pragma: allowlist secret

links:
	@echo "🔗 Checking critical internal links..."
	@if [ -f ../../scripts/pre-push-link-checker.sh ]; then \
		cd ../.. && chmod +x scripts/pre-push-link-checker.sh && scripts/pre-push-link-checker.sh; \
	else \
		echo "❌ Link checker script not found"; \
		exit 1; \
	fi

py:
	@echo "🐍 Running Python tests and linting..."
	@if [ -f ../../.venv/bin/pytest ]; then \
		cd ../.. && (.venv/bin/ruff check scripts/ || echo "⚠️  Ruff found issues but continuing...") && \
		.venv/bin/pytest && echo "✅ Pytest complete"; \
	elif command -v pytest >/dev/null 2>&1 && command -v ruff >/dev/null 2>&1; then \
		cd ../.. && (ruff check scripts/ || echo "⚠️  Ruff found issues but continuing...") && \
		pytest && echo "✅ Pytest complete"; \
	else \
		echo "❌ pytest or ruff not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

py-all: py
