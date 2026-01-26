.DEFAULT_GOAL := help

# Include all modular makefiles
include mk/adr.mk
include mk/hooks.mk
include mk/live.mk
include mk/media.mk
include mk/music.mk
include mk/site.mk
include mk/deploy.mk

.PHONY: help

help: ## Show this help
	@echo "Obscvrat Website - Make Commands"
	@echo "================================="
	@echo ""
	@echo "Content Management:"
	@echo "  make live                      - Manage live performances"
	@echo "  make media                     - Manage media (pictures, videos)"
	@echo "  make music                     - Manage music/albums"
	@echo ""
	@echo "Website:"
	@echo "  make serve                     - Run dev server"
	@echo "  make build                     - Build for development"
	@echo "  make build-prod                - Build for production"
	@echo "  make clean                     - Remove build artifacts"
	@echo "  make list-content              - List all content"
	@echo ""
	@echo "Development:"
	@echo "  make hooks                     - Show hooks help"
	@echo "  make hooks setup               - Install pre-commit hooks"
	@echo "  make hooks run                 - Run hooks manually"
	@echo ""
	@echo "Architecture:"
	@echo "  make adr                       - Show ADR help"
	@echo "  make adr new TITLE=\"...\"       - Create new ADR"
	@echo "  make adr list                  - List all ADRs"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy                    - Show deployment help"
	@echo "  make deploy production         - Deploy to production"
	@echo ""
	@echo "For detailed help on any command group, run:"
	@echo "  make <group>  (e.g., make adr, make hooks, make deploy)"

# vim: noexpandtab
