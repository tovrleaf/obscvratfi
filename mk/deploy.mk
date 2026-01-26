.PHONY: deploy

# Delegate to mk/deploy/Makefile
deploy:
	@$(MAKE) -C mk/deploy $(filter-out $@,$(MAKECMDGOALS))

# Catch-all target for deploy subcommands
deploy-%:
	@$(MAKE) -C mk/deploy $*

# Prevent "No rule to make target" errors for subcommands
%:
	@:
