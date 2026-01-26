.PHONY: hooks

# Delegate to mk/hooks/Makefile
hooks:
	@$(MAKE) -C mk/hooks $(filter-out $@,$(MAKECMDGOALS))

# Catch-all target for hooks subcommands
hooks-%:
	@$(MAKE) -C mk/hooks $*

# Prevent "No rule to make target" errors for subcommands
%:
	@:
