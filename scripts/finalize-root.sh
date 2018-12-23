#!/bin/bash

source /scripts/lib.sh

echo "Finalizing root account"

# Finish configuration of root account after children provisioned
TERRAFORM_ROOT_MODULES="root-dns iam users"

for module in ${TERRAFORM_ROOT_MODULES}; do 
  echo "Processing $module..."
  make -C "/conf/${module}" init plan
done

# Destroy the bootstrap user & role
make -C /conf/bootstrap init destroy