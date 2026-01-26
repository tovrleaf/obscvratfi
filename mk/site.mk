.PHONY: serve build build-prod build-minified clean distclean list-content

serve: ## Run Hugo dev server (http://localhost:1313)
	cd website && hugo server --bind 0.0.0.0

build: ## Build Hugo site for development
	cd website && hugo --destination=public

build-prod: ## Build Hugo site for production (https://obscvrat.fi) with minification
	cd website && hugo --baseURL="https://obscvrat.fi" --minify --destination=public

build-minified: ## Build Hugo site with minification enabled (for testing production optimization)
	cd website && hugo --minify --destination=public

clean: ## Remove build artifacts
	rm -rf website/public website/.hugo_build.lock

distclean: ## Clean everything including build artifacts
	rm -rf website/public website/.hugo_build.lock

list-content: ## List all content files in the site
	@echo "Live Performances:"
	@find website/content/live -name "*.md" -type f | sort
	@echo ""
	@echo "Albums:"
	@find website/content/albums -name "*.md" -type f | sort
