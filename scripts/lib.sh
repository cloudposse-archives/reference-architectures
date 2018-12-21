[ "${GEODESIC_SHELL}" == "true" ] || (echo "This script is intended to be run inside the account container. "; exit 1)

export CONF="${CONF:-/conf}"

# Don't use a role to simplify provisioning
export TF_VAR_aws_assume_role_arn=""

# We're not using AWS config profiles at this point
unset AWS_DEFAULT_PROFILE

# Export our environment to TF_VARs
eval $(tfenv sh -c "export -p")
