.DEFAULT_GOAL := help
.PHONY: help list new list-accepted list-proposed

help:
	@echo "Architecture Decision Records (ADRs)"
	@echo "====================================="
	@echo ""
	@echo "Create a new ADR:"
	@echo "  make adr new TITLE=\"Choose frontend framework\""
	@echo ""
	@echo "List all ADRs:"
	@echo "  make adr list"
	@echo ""
	@echo "List ADRs by status:"
	@echo "  make adr list-accepted"
	@echo "  make adr list-proposed"
	@echo ""
	@echo "More info:"
	@echo "  See docs/adr/README.md for complete ADR documentation"
	@echo "  See AGENTS.md for ADR workflow guidelines"

new:
	@if [ -z "$(TITLE)" ]; then \
		echo "Error: TITLE is required"; \
		echo "Usage: make adr new TITLE=\"Your Decision Title\""; \
		exit 1; \
	fi
	@cd ../.. && ./scripts/new-adr.sh "$(TITLE)"

list:
	@cd ../.. && ./scripts/list-adrs.sh

list-accepted:
	@cd ../.. && ./scripts/list-adrs.sh Accepted

list-proposed:
	@cd ../.. && ./scripts/list-adrs.sh Proposed
