#!/bin/bash

source /scripts/lib.sh

echo "Configuring root account"

# Load the environment for this stage
source /artifacts/${STAGE}.env

# Setup Terraform State Backend (special case)
#make -C /conf/tfstate-backend init

# Bootstrap the IAM user account & role we'll use for provisioning the rest of the infrastructure
make -C /conf/bootstrap init plan apply

# Assume the role needed to provision resources in this account
assume_role

# List of modules that do not get processed during this phase
SKIP_MODULES="^(tfstate-backend|root-dns|iam|users)$"

# Provision modules
apply_modules