.DEFAULT_GOAL := help
.PHONY: help adr-new adr-list adr-help serve build clean build-docker build-prod build-staging build-minified serve-prod list-content

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

build: ## Build Hugo site for development in Docker
	docker-compose run --rm hugo --destination=/src/public

build-prod: ## Build Hugo site for production (https://obscvrat.fi) with minification
	docker-compose run --rm hugo --baseURL="https://obscvrat.fi" --minify --destination=/src/public

build-staging: ## Build Hugo site for staging (CloudFront) - requires DISTRIBUTION_ID env var
	@if [ -z "$(DISTRIBUTION_ID)" ]; then \
		echo "Error: DISTRIBUTION_ID is required for staging build"; \
		echo "Usage: make build-staging DISTRIBUTION_ID=d1234abcd.cloudfront.net"; \
		exit 1; \
	fi
	docker-compose run --rm hugo --baseURL="https://$(DISTRIBUTION_ID)" --minify --destination=/src/public

build-minified: ## Build Hugo site with minification enabled (for testing production optimization)
	docker-compose run --rm hugo --minify --destination=/src/public

build-docker: ## Build Docker image locally
	docker build -t obscvratfi:latest .

clean: ## Remove Docker containers and cleanup
	docker-compose down
	rm -rf website/public

distclean: ## Clean everything including build artifacts
	docker-compose down
	rm -rf website/public website/.hugo_build.lock

list-content: ## List all content files in the site
	@echo "Gigs:"
	@find website/content/gigs -name "*.md" -type f | sort
	@echo ""
	@echo "Albums:"
	@find website/content/albums -name "*.md" -type f | sort

# vim: noexpandtab
