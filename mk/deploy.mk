.PHONY: deploy deploy-production deploy-protect-main deploy-show-rules deploy-unprotect-main

deploy: ## Show deployment help
	@echo "Deployment Commands"
	@echo "==================="
	@echo ""
	@echo "Deploy to production:"
	@echo "  make deploy-production"
	@echo ""
	@echo "Branch protection:"
	@echo "  make deploy-protect-main      - Protect main branch (one-time setup)"
	@echo "  make deploy-show-rules        - Show current protection rules"
	@echo "  make deploy-unprotect-main    - Remove protection (emergency only)"
	@echo ""
	@echo "More info:"
	@echo "  See docs/DEPLOYMENT.md for deployment guide"
	@echo "  See ADR-006 for branch protection rationale"

deploy-production: ## Deploy to production (obscvrat.fi)
	@./scripts/deploy.sh

deploy-protect-main: ## Protect main branch with GitHub Rulesets (one-time setup)
	@./scripts/protect-main-branch.sh

deploy-show-rules: ## List current branch protection rules
	@./scripts/list-branch-rules.sh

deploy-unprotect-main: ## Remove branch protection (emergency rollback only)
	@./scripts/remove-branch-protection.sh
