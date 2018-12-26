[ "${GEODESIC_SHELL}" == "true" ] || (echo "This script is intended to be run inside the account container. "; exit 1)

export CONF="${CONF:-/conf}"

# Export our environment to TF_VARs
eval $(tfenv sh -c "export -p")

# Easily assume role using the "bootstrap" user
function assume_role() {
    # Load the environment exported by the `bootstrap` module
    source /artifacts/.envrc

    # Install the helper cli for assuming roles as part of the bootstrapping process
    apk add assume-role@cloudposse

    # This is because the [`assume-role`](https://github.com/remind101/assume-role) cli does not respect the SDK environment variables.
    export HOME="/artifacts"

    # Unset AWS credential environment variables so they don't interfere with `assume-role`
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCES_KEY

    # Obtain an assume-role session
    eval $(/usr/bin/assume-role $AWS_DEFAULT_PROFILE)
	if [ $? -ne 0 ]; then
		echo "Failed to assume role of ${AWS_DEFAULT_PROFILE}"
		exit 1
	fi
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

function apply_modules() {
    # Provision modules which *do not* have dependencies on other accounts (that will be a later phase)
    for module in ${TERRAFORM_ROOT_MODULES}; do 
        if [[ "${module}" =~ ${SKIP_MODULES} ]]; then
            echo "Skipping ${module}..."
        else
            echo "Processing $module..."
            make -C "/conf/${module}" init plan 
			if [ $? -ne 0 ]; then
				abort "The ${module} module errored. Aborting."
			fi
        fi
    done
}

# Capture ^C and exit immediately
trap ctrl_c INT

function ctrl_c() {
	echo "* Okay, aborting..."
	exit 1
}
