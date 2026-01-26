.PHONY: adr adr-new adr-list adr-list-accepted adr-list-proposed

adr: ## Show ADR help and guidelines
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
