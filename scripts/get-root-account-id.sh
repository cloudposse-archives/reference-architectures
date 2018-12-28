#!/bin/bash

export AWS_ROOT_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

if [[ -z "${AWS_ROOT_ACCOUNT_ID}" ]]; then
  echo "Unable to obtain root account id"
  exit 1
fi

# Export the "root AWS Account ID so we can use it with the rest of the bootstrapping process
printf 'aws_root_account_id = "%s"' $AWS_ROOT_ACCOUNT_ID > /artifacts/aws.tfvars
