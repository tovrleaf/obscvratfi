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
	@echo "  make test links           - Validate all links and images (htmltest)"
	@echo ""
	@echo "Test single file (use FILE parameter):"
	@echo "  make test sh FILE=path/to/script.sh"
	@echo "  make test yaml FILE=path/to/file.yml"
	@echo "  make test md FILE=path/to/file.md"
	@echo "  make test html FILE=path/to/file.html"
	@echo "  make test py FILE=path/to/file.py"
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
	@if [ -n "$(FILE)" ]; then \
		echo "🔍 Running shellcheck on $(FILE)..."; \
		if [ ! -f "../../$(FILE)" ]; then \
			echo "❌ File not found: $(FILE)"; \
			exit 1; \
		fi; \
		if [ -f ../../.venv/bin/shellcheck ]; then \
			if cd ../.. && .venv/bin/shellcheck --severity=error --format=gcc $(FILE); then \
				echo "✅ Shellcheck passed"; \
			else \
				echo "❌ Shellcheck found issues in $(FILE)"; \
				exit 1; \
			fi; \
		elif command -v shellcheck >/dev/null 2>&1; then \
			if cd ../.. && shellcheck --severity=error --format=gcc $(FILE); then \
				echo "✅ Shellcheck passed"; \
			else \
				echo "❌ Shellcheck found issues in $(FILE)"; \
				exit 1; \
			fi; \
		else \
			echo "❌ shellcheck not found"; \
			echo "Run 'make hooks setup' to install locally"; \
			exit 1; \
		fi; \
	else \
		echo "🔍 Running shellcheck on all shell scripts..."; \
		if [ -f ../../.venv/bin/shellcheck ]; then \
			if cd ../.. && find scripts -name "*.sh" -type f -exec .venv/bin/shellcheck --severity=error --format=gcc {} +; then \
				echo "✅ Shellcheck passed"; \
			else \
				echo "❌ Shellcheck found issues"; \
				exit 1; \
			fi; \
		elif command -v shellcheck >/dev/null 2>&1; then \
			if cd ../.. && find scripts -name "*.sh" -type f -exec shellcheck --severity=error --format=gcc {} +; then \
				echo "✅ Shellcheck passed"; \
			else \
				echo "❌ Shellcheck found issues"; \
				exit 1; \
			fi; \
		else \
			echo "❌ shellcheck not found"; \
			echo "Run 'make hooks setup' to install locally"; \
			exit 1; \
		fi; \
	fi

sh-all: sh

sh-commit:
	@echo "🔍 Running shellcheck on shell scripts in last commit..."
	@if [ -f ../../.venv/bin/shellcheck ]; then \
		cd ../.. && shell_files=$$(git diff-tree --no-commit-id --name-only -r HEAD | grep '\.sh$$'); \
		if [ -n "$$shell_files" ]; then \
			if echo "$$shell_files" | xargs .venv/bin/shellcheck --severity=error --format=gcc; then \
				echo "✅ Shellcheck passed"; \
			else \
				echo "❌ Shellcheck found issues in committed files"; \
				exit 1; \
			fi; \
		else \
			echo "ℹ️  No shell scripts in last commit"; \
		fi; \
	elif command -v shellcheck >/dev/null 2>&1; then \
		cd ../.. && shell_files=$$(git diff-tree --no-commit-id --name-only -r HEAD | grep '\.sh$$'); \
		if [ -n "$$shell_files" ]; then \
			if echo "$$shell_files" | xargs shellcheck --severity=error --format=gcc; then \
				echo "✅ Shellcheck passed"; \
			else \
				echo "❌ Shellcheck found issues in committed files"; \
				exit 1; \
			fi; \
		else \
			echo "ℹ️  No shell scripts in last commit"; \
		fi; \
	else \
		echo "❌ shellcheck not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

yaml:
	@if [ -n "$(FILE)" ]; then \
		echo "🔍 Running yamllint on $(FILE)..."; \
		if [ ! -f "../../$(FILE)" ]; then \
			echo "❌ File not found: $(FILE)"; \
			exit 1; \
		fi; \
		if [ -f ../../.venv/bin/yamllint ]; then \
			if cd ../.. && .venv/bin/yamllint -c .github/yamllint-config.yml $(FILE); then \
				echo "✅ Yamllint passed"; \
			else \
				echo "❌ Yamllint found issues in $(FILE)"; \
				exit 1; \
			fi; \
		else \
			echo "❌ yamllint not found"; \
			echo "Run 'make hooks setup' to install locally"; \
			exit 1; \
		fi; \
	else \
		echo "🔍 Running yamllint on all YAML files..."; \
		if [ -f ../../.venv/bin/yamllint ]; then \
			if cd ../.. && find . -name "*.yml" -o -name "*.yaml" | grep -v ".venv" | xargs .venv/bin/yamllint -c .github/yamllint-config.yml; then \
				echo "✅ Yamllint passed"; \
			else \
				echo "❌ Yamllint found issues"; \
				exit 1; \
			fi; \
		else \
			echo "❌ yamllint not found"; \
			echo "Run 'make hooks setup' to install locally"; \
			exit 1; \
		fi; \
	fi

yaml-all: yaml

yaml-commit:
	@echo "🔍 Running yamllint on YAML files in last commit..."
	@if [ -f ../../.venv/bin/yamllint ]; then \
		cd ../.. && yaml_files=$$(git diff-tree --no-commit-id --name-only -r HEAD | grep -E '\.(yml|yaml)$$'); \
		if [ -n "$$yaml_files" ]; then \
			if echo "$$yaml_files" | xargs .venv/bin/yamllint -c .github/yamllint-config.yml; then \
				echo "✅ Yamllint passed"; \
			else \
				echo "❌ Yamllint found issues in committed files"; \
				exit 1; \
			fi; \
		else \
			echo "ℹ️  No YAML files in last commit"; \
		fi; \
	else \
		echo "❌ yamllint not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

md:
	@if [ -n "$(FILE)" ]; then \
		echo "🔍 Running pymarkdown on $(FILE)..."; \
		if [ ! -f "../../$(FILE)" ]; then \
			echo "❌ File not found: $(FILE)"; \
			exit 1; \
		fi; \
		if [ -f ../../.venv/bin/pymarkdown ]; then \
			if cd ../.. && .venv/bin/pymarkdown --config .pymarkdownlnt scan $(FILE); then \
				echo "✅ Pymarkdown passed"; \
			else \
				echo "❌ Pymarkdown found issues in $(FILE)"; \
				exit 1; \
			fi; \
		else \
			echo "❌ pymarkdown not found"; \
			echo "Run 'make hooks setup' to install locally"; \
			exit 1; \
		fi; \
	else \
		echo "🔍 Running pymarkdown on all Markdown files..."; \
		if [ -f ../../.venv/bin/pymarkdown ]; then \
			if cd ../.. && find . -name "*.md" | grep -v ".venv" | xargs .venv/bin/pymarkdown --config .pymarkdownlnt scan; then \
				echo "✅ Pymarkdown passed"; \
			else \
				echo "❌ Pymarkdown found issues"; \
				exit 1; \
			fi; \
		else \
			echo "❌ pymarkdown not found"; \
			echo "Run 'make hooks setup' to install locally"; \
			exit 1; \
		fi; \
	fi

md-all: md

md-commit:
	@echo "🔍 Running pymarkdown on Markdown files in last commit..."
	@if [ -f ../../.venv/bin/pymarkdown ]; then \
		cd ../.. && md_files=$$(git diff-tree --no-commit-id --name-only -r HEAD | grep '\.md$$'); \
		if [ -n "$$md_files" ]; then \
			if echo "$$md_files" | xargs .venv/bin/pymarkdown --config .pymarkdownlnt scan; then \
				echo "✅ Pymarkdown passed"; \
			else \
				echo "❌ Pymarkdown found issues in committed files"; \
				exit 1; \
			fi; \
		else \
			echo "ℹ️  No Markdown files in last commit"; \
		fi; \
	else \
		echo "❌ pymarkdown not found"; \
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

html:
	@if [ -n "$(FILE)" ]; then \
		echo "🔍 Running HTML validation on $(FILE)..."; \
		if [ ! -f "../../$(FILE)" ]; then \
			echo "❌ File not found: $(FILE)"; \
			exit 1; \
		fi; \
		cd ../.. && chmod +x scripts/test-html.sh && scripts/test-html.sh single $(FILE); \
	else \
		echo "🔍 Running HTML validation on all files..."; \
		cd ../.. && chmod +x scripts/test-html.sh && scripts/test-html.sh all; \
	fi

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
	# pragma: allowlist secret
	@if [ -f ../../.venv/bin/detect-secrets ]; then \  # pragma: allowlist secret
		cd ../.. && .venv/bin/detect-secrets scan; \  # pragma: allowlist secret
	else \
		# pragma: allowlist secret
		echo "❌ detect-secrets not found"; \  # pragma: allowlist secret
		# pragma: allowlist secret
		echo "Run 'make hooks setup' to install locally"; \
		exit 1; \
	fi

secrets-all: secrets # pragma: allowlist secret

links:
	@echo "🔗 Validating all links and images with htmltest..."
	@if ! command -v htmltest >/dev/null 2>&1; then \
		echo "❌ htmltest not found"; \
		echo "Install: brew install htmltest"; \
		exit 1; \
	fi
	@if [ ! -d ../../website/public ]; then \
		echo "❌ website/public not found"; \
		echo "Run 'cd website && hugo' to build site first"; \
		exit 1; \
	fi
	@cd ../.. && htmltest

py:
	@if [ -n "$(FILE)" ]; then \
		echo "🐍 Running Python linting on $(FILE)..."; \
		if [ ! -f "../../$(FILE)" ]; then \
			echo "❌ File not found: $(FILE)"; \
			exit 1; \
		fi; \
		if [ -f ../../.venv/bin/ruff ]; then \
			if cd ../.. && .venv/bin/ruff check $(FILE); then \
				echo "✅ Python linting passed"; \
			else \
				echo "❌ Ruff found issues in $(FILE)"; \
				exit 1; \
			fi; \
		elif command -v ruff >/dev/null 2>&1; then \
			if cd ../.. && ruff check $(FILE); then \
				echo "✅ Python linting passed"; \
			else \
				echo "❌ Ruff found issues in $(FILE)"; \
				exit 1; \
			fi; \
		else \
			echo "❌ ruff not found"; \
			echo "Run 'make hooks setup' to install locally"; \
			exit 1; \
		fi; \
	else \
		echo "🐍 Running Python tests and linting..."; \
		if [ -f ../../.venv/bin/pytest ]; then \
			if cd ../.. && .venv/bin/ruff check scripts/; then \
				echo "✅ Ruff linting passed"; \
			else \
				echo "❌ Ruff found issues"; \
				exit 1; \
			fi; \
			if .venv/bin/pytest; then \
				echo "✅ Python tests passed"; \
			else \
				echo "❌ Pytest failed"; \
				exit 1; \
			fi; \
		elif command -v pytest >/dev/null 2>&1 && command -v ruff >/dev/null 2>&1; then \
			if cd ../.. && ruff check scripts/; then \
				echo "✅ Ruff linting passed"; \
			else \
				echo "❌ Ruff found issues"; \
				exit 1; \
			fi; \
			if pytest; then \
				echo "✅ Python tests passed"; \
			else \
				echo "❌ Pytest failed"; \
				exit 1; \
			fi; \
		else \
			echo "❌ pytest or ruff not found"; \
			echo "Run 'make hooks setup' to install locally"; \
			exit 1; \
		fi; \
	fi

py-all: py
