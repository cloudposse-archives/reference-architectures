#!/bin/bash

source lib.sh
if [ `pwd` != "/conf/accounts" ]; then
	echo "This script should be run from /conf/accounts"
	exit 1
fi

(
	echo "aws_account_ids = {"
	terraform output -json | jq -r 'to_entries | .[] | .key + " = \"" + .value.value + "\""' | grep account_id | sed 's/_account_id//'
	echo "}"
) | terraform fmt - > /artifacts/accounts.tfvars

