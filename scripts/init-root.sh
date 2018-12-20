#!/bin/bash

[ "${GEODESIC_SHELL}" == "true" ] || (echo "This script is intended to be run inside the account container. "; exit 1)

echo "Configuring root account"

#   Setup AWS vault
#   aws-vault exec ${AWS_PROFILE} -- /scripts/init-tfstate
#   aws-vault exec ${AWS_PROFILE} -- /scripts/init-accounts

