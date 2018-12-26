#!/bin/bash

# Don't use a role to simplify provisioning of root account
export TF_VAR_aws_assume_role_arn=""

# We're not using AWS config profiles at this point. Those will be used with child accounts.
unset AWS_DEFAULT_PROFILE

source /scripts/lib.sh

echo "Configuring root account"

# Load the environment for this stage, if they exist
echo "Loading /artifacts/${STAGE}.env"
source /artifacts/${STAGE}.env

# List of modules that do not get processed during this phase
# These modules will be applied later


# Provision modules
apply_modules

# Export account ids (for use with provisioning children)
if [ ! -f "/artifacts/accounts.tfvars" ]; then
	cd /conf/accounts
	make init 
	(
		echo "aws_account_ids = {"
		terraform output -json | jq -r 'to_entries | .[] | .key + " = \"" + .value.value + "\""' | grep account_id | sed 's/_account_id//'
		echo "}"
	) | terraform fmt - > /artifacts/accounts.tfvars
fi
