#!/bin/bash

source /scripts/lib.sh

echo "Configuring root account"

# We're not using AWS config profiles at this point
unset AWS_DEFAULT_PROFILE

# Export our environment to TF_VARs
eval $(tfenv sh -c "export -p")

# Setup Terraform State Backend
cd /conf/tfstate-backend

./scripts/init.sh

# Setup AWS Accounts
cd /conf/accounts

init-terraform

terraform plan

#   Setup AWS vault
#   aws-vault exec ${AWS_PROFILE} -- /scripts/init-tfstate
#   aws-vault exec ${AWS_PROFILE} -- /scripts/init-accounts

