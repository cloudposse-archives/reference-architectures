#!/bin/bash

source /scripts/lib.sh

echo "Configuring root account"

# Load the environment for this stage, if they exist
if [ -f "/artifacts/${STAGE}.env" ]; then
	echo "Loading /artifacts/${STAGE}.env"
	source /artifacts/${STAGE}.env
fi

# List of modules that do not get processed during this phase
# These modules will be applied later
SKIP_MODULES="^(root-dns|iam|cloudtrail)$"

# Provision modules
apply_modules

# Export account ids (for use with provisioning children)
cd /conf/accounts
make init 
(
	echo "aws_account_ids = {"
	terraform output -json | jq -r 'to_entries | .[] | .key + " = \"" + .value.value + "\""' | grep account_id | sed 's/_account_id//'
	echo "}"
) | terraform fmt - > /artifacts/accounts.tfvars
