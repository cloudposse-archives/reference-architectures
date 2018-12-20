# Import the cloudposse/build-harness
include $(shell curl -sSL -o .build-harness "https://git.io/build-harness"; echo .build-harness)

# Run time environment passed to terraform
export TF_VAR_repos_dir ?= $(shell pwd)/repos
export TF_VAR_templates_dir ?= $(shell pwd)/templates

# The target called when calling `make` with no arguments
export DEFAULT_HELP_TARGET = help/short

# The command we'll use to start the container 
export DOCKER_RUN = docker run -it -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -v $(shell pwd)/artifacts:/artifacts -v $(shell pwd)/scripts:/scripts


## Initialize the "root" AWS account
init/root:
	$(DOCKER_RUN) cloudposse/geodesic:0.46.0 -c /scripts/get-root-account-id.sh
	terraform init -from-module=modules/root accounts/root
	terraform apply -var-file=artifacts/aws.tfvars -var-file=configs/root.tfvars -auto-approve accounts/root
	terraform output docker_image > artifacts/root-docker-image
	$(DOCKER_RUN) root -l -c /scripts/init-root.sh

## Initialize the "testing" AWS account
init/testing:
	terraform init -from-module=modules/child accounts/testing
	terraform apply -var-file=artifacts/aws.tfvars -var-file=configs/testing.tfvars -auto-approve accounts/testing
	$(DOCKER_RUN) IMAGE -c /scripts/init-testing.sh

## Initialize all the child AWS subaccounts (depends on init/root)
init/child: init/testing
	@exit 0

## Finalize the configuration of the AWS "root" account (depends on init/child)
finalize/root:
	@echo "Not implemented"

## Clean up 
clean::
	rm -rf repos accounts .terraform terraform.tfstate*
