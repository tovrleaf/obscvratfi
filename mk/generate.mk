# Generate markdown from YAML data files

.PHONY: generate bump-version

generate: ## Generate markdown from YAML data (usage: make generate [live|music|media])
	@target="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$target" ]; then \
		./scripts/generate-markdown.sh all; \
	else \
		./scripts/generate-markdown.sh "$$target"; \
	fi

bump-version: ## Bump version in CHANGELOG.md (usage: make bump-version [TYPE=patch|minor|major])
	@python3 scripts/bump_version.py $(or $(TYPE),patch)
