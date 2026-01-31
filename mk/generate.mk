# Generate markdown from YAML data files

.PHONY: generate

generate: ## Generate markdown from YAML data (usage: make generate [live|music|media])
	@target="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$target" ]; then \
		./scripts/generate-markdown.sh all; \
	else \
		./scripts/generate-markdown.sh "$$target"; \
	fi
