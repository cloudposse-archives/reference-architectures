## Fetch the remote helmfiles
deps:
	@exit 0

diff: kubeconfig
	chamber exec kops -- helmfile diff --args="--allow-unreleased --context 5 --no-color --suppress-secrets"

apply: kubeconfig
	chamber exec kops -- helmfile apply

## Reset this project
reset:
	rm -rf releases scripts
	exit 0

## Install or upgrade tiller. Should only be needed when initially creating the environment.
install-tiller upgrade-tiller: kubeconfig
	helmctl tiller install

.PHONY: kubeconfig
kubeconfig:
	chamber exec kops -- kops export kubecfg
