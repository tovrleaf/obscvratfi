.DEFAULT_GOAL := help
.PHONY: help adr-new adr-list adr-help serve build clean build-docker

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":[^#]*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ADR Tasks

adr-new: ## Create a new ADR (usage: make adr-new TITLE="Your Decision Title")
	@if [ -z "$(TITLE)" ]; then \
		echo "Error: TITLE is required"; \
		echo "Usage: make adr-new TITLE=\"Your Decision Title\""; \
		exit 1; \
	fi
	@./scripts/new-adr.sh "$(TITLE)"

adr-list: ## List all ADRs with their status
	@./scripts/list-adrs.sh

adr-list-accepted: ## List all accepted ADRs
	@./scripts/list-adrs.sh Accepted

adr-list-proposed: ## List all proposed ADRs
	@./scripts/list-adrs.sh Proposed

adr-help: ## Show ADR help and guidelines
	@echo "Architecture Decision Records (ADRs)"
	@echo "====================================="
	@echo ""
	@echo "Create a new ADR:"
	@echo "  make adr-new TITLE=\"Choose frontend framework\""
	@echo ""
	@echo "List all ADRs:"
	@echo "  make adr-list"
	@echo ""
	@echo "List ADRs by status:"
	@echo "  make adr-list-accepted"
	@echo "  make adr-list-proposed"
	@echo ""
	@echo "More info:"
	@echo "  See docs/adr/README.md for complete ADR documentation"
	@echo "  See AGENTS.md for ADR workflow guidelines"

# Website Tasks

serve: ## Run Hugo dev server in Docker (http://localhost:1313)
	docker-compose up hugo

build: ## Build Hugo site for production in Docker
	docker-compose run --rm hugo --destination=/src/public

clean: ## Remove Docker containers
	docker-compose down

build-docker: ## Build Docker image locally
	docker build -t obscvratfi:latest .

# vim: noexpandtab
