# Import the cloudposse/build-harness
include $(shell curl -sSL -o .build-harness "https://git.io/build-harness"; echo .build-harness)
-include tasks/Makefile.*

# The target called when calling `make` with no arguments
export DEFAULT_HELP_TARGET = help/short

