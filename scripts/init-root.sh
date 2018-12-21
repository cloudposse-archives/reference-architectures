#!/bin/bash

source /scripts/lib.sh

echo "Configuring root account"

# Setup Terraform State Backend (special case)
#make -C /conf/tfstate-backend init

# Provision modules which *do not* have dependencies on other accounts (that will be a later phase)
TERRAFORM_ROOT_MODULES="accounts accounts account-settings root-iam cloudtrail"

for module in ${TERRAFORM_ROOT_MODULES}; do 
  echo "Processing $module..."
  make -C "/conf/${module}" init plan
done
