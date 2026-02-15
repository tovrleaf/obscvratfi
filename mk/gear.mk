.PHONY: gear

gear: ## Manage gear inventory (pedals, synths, instruments)
	@if [ -f .venv/bin/python3 ]; then \
		.venv/bin/python3 scripts/manage_gear.py; \
	else \
		python3 scripts/manage_gear.py; \
	fi
