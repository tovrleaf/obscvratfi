.DEFAULT_GOAL := help
.PHONY: help production protect-main show-rules unprotect-main setup-github-secrets generate-deployment-policy

help:
	@echo "Deployment Commands"
	@echo "==================="
	@echo ""
	@echo "Deploy to production:"
	@echo "  make deploy production"
	@echo ""
	@echo "GitHub Actions setup (one-time):"
	@echo "  make deploy generate-deployment-policy  - Generate IAM policy with distribution ID"
	@echo "  make deploy setup-github-secrets        - Configure GitHub secrets for deployment"
	@echo ""
	@echo "Branch protection:"
	@echo "  make deploy protect-main      - Protect main branch (one-time setup)"
	@echo "  make deploy show-rules        - Show current protection rules"
	@echo "  make deploy unprotect-main    - Remove protection (emergency only)"
	@echo ""
	@echo "More info:"
	@echo "  See docs/GITHUB-ACTIONS.md for GitHub Actions setup"
	@echo "  See docs/DEPLOYMENT.md for deployment guide"
	@echo "  See ADR-006 for branch protection rationale"

production:
	@cd ../.. && ./scripts/deploy.sh

generate-deployment-policy:
	@cd ../.. && bash scripts/generate-deployment-policy.sh

setup-github-secrets:
	@cd ../.. && bash scripts/setup-github-secrets.sh

protect-main:
	@cd ../.. && ./scripts/protect-main-branch.sh

show-rules:
	@cd ../.. && ./scripts/list-branch-rules.sh

unprotect-main:
	@cd ../.. && ./scripts/remove-branch-protection.sh
