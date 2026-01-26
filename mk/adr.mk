.PHONY: adr

# Delegate to mk/adr/Makefile
adr:
	@$(MAKE) -C mk/adr $(filter-out $@,$(MAKECMDGOALS))

# Catch-all target for adr subcommands
adr-%:
	@$(MAKE) -C mk/adr $*

# Prevent "No rule to make target" errors for subcommands
%:
	@:
