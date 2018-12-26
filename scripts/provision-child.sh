#!/bin/bash

# This is support `assume-role` which does not honor SDK ENVs. (https://github.com/remind101/assume-role/issues/40)
export HOME=/artifacts
export AWS_CONFIG_FILE="${HOME}/.aws/config"

source /scripts/lib.sh

echo "Configuring child account"

# Load the environment for this stage
echo "Loading /artifacts/${STAGE}.env"
source /artifacts/${STAGE}.env

# Fetch the Role ARN from the configuration
export TF_VAR_aws_assume_role_arn=$(crudini --get ${AWS_CONFIG_FILE} "profile ${AWS_DEFAULT_PROFILE}" role_arn)

if [ -z "${TF_VAR_aws_assume_role_arn}" ]; then
	abort "TF_VAR_aws_assume_role_arn must be set"
fi

# Assume the role needed to provision resources in this account
assume_role

# Test the connection
aws sts get-caller-identity

# Provision modules
apply_modules
