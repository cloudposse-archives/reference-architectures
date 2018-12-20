include $(shell curl -sSL -o .build-harness "https://git.io/build-harness"; echo .build-harness)

export TF_VAR_repos_dir ?= $(shell pwd)/repos
export TF_VAR_templates_dir ?= $(shell pwd)/templates

export DEFAULT_HELP_TARGET = help/short

## Initialize the "root" AWS account
init/root:
	terraform init -from-module=modules/root accounts/root
	terraform apply -var-file=configs/root.tfvars -auto-approve accounts/root

## Initialize the "testing" AWS account
init/testing:
	terraform init -from-module=modules/child accounts/testing
	terraform apply -var-file=configs/testing.tfvars -auto-approve accounts/testing

## Initialize all the child subaccounts
init/child: init/testing
	@exit 0

## Finalize the configuration of the AWS "root" account
finalize/root:
	@echo "Not implemented"

## Clean up 
clean::
	rm -rf repos accounts .terraform terraform.tfstate*
