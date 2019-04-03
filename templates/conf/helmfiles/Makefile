## Fetch the remote helmfiles
deps:
	curl -sSL -q  $(HELMFILES_ARCHIVE)  --output - | tar -xz  --strip-components=1 --wildcards "*/releases" "*/scripts"

diff:
	chamber exec kops -- kops export kubecfg
	chamber exec kops  -- helmfile diff --args="--allow-unreleased --context 5 --no-color --suppress-secrets"

apply:
	chamber exec kops -- kops export kubecfg
	chamber exec kops  -- helmfile apply

## Reset this project
reset:
	rm -rf releases scripts
	exit 0
