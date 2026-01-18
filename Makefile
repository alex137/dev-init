# Root Proxy Makefile
%:
	@$(MAKE) -i -C .devcontainer $@

all:
	@$(MAKE) -i -C .devcontainer up
