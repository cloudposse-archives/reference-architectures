SKIP_MODULES="^(tfstate-backend|root-dns|iam|users)$"

function apply_modules() {
TERRAFORM_ROOT_MODULES="accounts account-settings root-iam cloudtrail root-dns users"
for module in ${TERRAFORM_ROOT_MODULES}; do 

	if [[ "${module}" =~ ${SKIP_MODULES} ]]; then
		echo "Skipping ${module}..."
	else
		echo "Processing $module..."
	fi

done
}

apply_modules
