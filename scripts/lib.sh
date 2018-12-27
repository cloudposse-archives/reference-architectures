[ "${GEODESIC_SHELL}" == "true" ] || (echo "This script is intended to be run inside the account container. "; exit 1)

export CONF="${CONF:-/conf}"

# Import env for this stage
function import_env() {
	# Load the environment for this stage, if they exist
	echo "Loading /artifacts/${STAGE}.env"
	source /artifacts/${STAGE}.env

	# Export our environment to TF_VARs
	eval $(tfenv sh -c "export -p")
}

function disable_profile() {
	# Don't use a role to simplify provisioning of root account
	export TF_VAR_aws_assume_role_arn=""
	unset AWS_DEFAULT_PROFILE
	unset AWS_PROFILE
}

# Easily assume role using the "bootstrap" user
function assume_role() {
	echo "Attempting to assume role to ${AWS_DEFAULT_PROFILE}..."

	# Load the environment exported by the `bootstrap` module
	source /artifacts/.envrc

	# Install the helper cli for assuming roles as part of the bootstrapping process
	[ -x /usr/bin/assume-role ] || apk add assume-role@cloudposse

	# This is because the [`assume-role`](https://github.com/remind101/assume-role) cli does not respect the SDK environment variables.
	export HOME="/artifacts"
	export AWS_CONFIG_FILE="${HOME}/.aws/config"

	# Unset AWS credential environment variables so they don't interfere with `assume-role`
	unset AWS_ACCESS_KEY_ID
	unset AWS_SECRET_ACCES_KEY

	# Fetch the Role ARN from the configuration
	export TF_VAR_aws_assume_role_arn=$(crudini --get ${AWS_CONFIG_FILE} "profile ${AWS_DEFAULT_PROFILE}" role_arn)

	if [ -z "${TF_VAR_aws_assume_role_arn}" ]; then
		abort "TF_VAR_aws_assume_role_arn must be set"
	fi

	# Obtain an assume-role session
	eval $(/usr/bin/assume-role $AWS_DEFAULT_PROFILE)
	if [ $? -ne 0 ]; then
		echo "Failed to assume role of ${AWS_DEFAULT_PROFILE}"
		exit 1
	fi
}

# Export map of accounts
function export_accounts() {
	# Export account ids (for use with provisioning children)
	cd /conf/accounts
	make init 
	(
		echo "aws_account_ids = {"
		terraform output -json | jq -r 'to_entries | .[] | .key + " = \"" + .value.value + "\""' | grep account_id | sed 's/_account_id//'
		echo "}"
	) | terraform fmt - > /artifacts/accounts.tfvars
}

function abort() {
	echo -e "\n\n"
	echo "==============================================================================================="
	echo "$1"
	echo
	echo "* Please report this error here:"
	echo "          https://github.com/cloudposse/reference-architectures/issues/new"
	echo -e "\n\n"
	exit 1
}

# Provision modules
function apply_modules() {
	# Provision modules which *do not* have dependencies on other accounts (that will be a later phase)
	for module in ${TERRAFORM_ROOT_MODULES}; do 
		if [[ -n "${SKIP_MODULES}" ]] && [[ "${module}" =~ ${SKIP_MODULES} ]]; then
			echo "Skipping ${module}..."
		else
			echo "Processing $module..."
			make -C "/conf/${module}" init plan apply
			if [ $? -ne 0 ]; then
				abort "The ${module} module errored. Aborting."
			fi
		fi
	done
}

function parse_args() {
	while [[ $1 ]]; do
		echo "Handling [$1]..."
		case "$1" in
		-a | --assume-role)
			assume_role
			shift
			;;
		-d | --disable-profile)
			disable_profile
			shift
			;;
		-m | --apply-modules)
			apply_modules
			shift
			;;
		-i | --import-env)
			import_env
			shift
			;;
		-e | --export-accounts)
			export_accounts
			shift
			;;
		*)
			echo "Error: Unknown option: $1" >&2
			exit 1
			;;
		esac
	done
}

function ctrl_c() {
	echo "* Okay, aborting..."
	exit 1
}
