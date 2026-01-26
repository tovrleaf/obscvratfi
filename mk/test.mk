.PHONY: test

# Delegate to mk/test/Makefile
test:
	@$(MAKE) -C mk/test $(filter-out $@,$(MAKECMDGOALS))

# Catch-all target for test subcommands
test-%:
	@$(MAKE) -C mk/test $*

# Prevent "No rule to make target" errors for subcommands
%:
	@:
