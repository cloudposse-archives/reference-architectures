# Import the cloudposse/build-harness
include $(shell curl -sSL -o .build-harness "https://git.io/build-harness"; echo .build-harness)
include tasks/Makefile.*

# Run time environment passed to terraform
export TF_VAR_artifacts_dir ?= $(CURDIR)/artifacts
export TF_VAR_repos_dir ?= $(CURDIR)/repos
export TF_VAR_templates_dir ?= $(CURDIR)/templates

# The target called when calling `make` with no arguments
export DEFAULT_HELP_TARGET = help/short

# The command we'll use to start the container 
export DOCKER_RUN = docker run --rm -it -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e SSH_KEY=false \
						-v $(CURDIR)/artifacts:/artifacts -v $(CURDIR)/scripts:/scripts

# The directory containing configs
export CONFIGS ?= configs

## Clean up 
clean::
	rm -rf repos accounts .terraform *.tfstate* artifacts/*

## Format all terraform code
fmt:
	find $(CONFIGS) -type f -name '*.tfvars' -exec terraform fmt {} \;
	terraform fmt modules

finalize: root/finalize children/finalize
	@exit 0
