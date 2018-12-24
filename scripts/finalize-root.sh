#!/bin/bash

source /scripts/lib.sh

echo "Finalizing root account"

for module in ${TERRAFORM_ROOT_MODULES}; do 
  echo "Processing $module..."
  make -C "/conf/${module}" init plan apply
done

# Destroy the bootstrap user & role
#make -C /conf/bootstrap init destroy
