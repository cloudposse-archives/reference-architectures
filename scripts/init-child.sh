#!/bin/bash

source /scripts/lib.sh

echo "Configuring child account"

# Load the environment for this stage
source /artifacts/${STAGE}.env

# Setup Terraform State Backend (special case)
#make -C /conf/tfstate-backend init

# Assume the role needed to provision resources in this account
assume_role

# List of modules that do not get processed during this phase
SKIP_MODULES="^(tfstate-backend)$"

# Provision modules
apply_modules
