## Fetch the remote helmfiles
deps:
	curl -sSL -q  $(HELMFILES_ARCHIVE)  --output - | tar -xz  --strip-components=1 --wildcards "*/releases" "*/scripts"


diff: kubeconfig
	chamber exec kops -- helmfile diff --args="--allow-unreleased --context 5 --no-color --suppress-secrets"

apply: kubeconfig
	chamber exec kops -- helmfile apply

## Reset this project
reset:
	rm -rf releases scripts
	exit 0

## Install or upgrade tiller. Should only be needed when initially creating the environment.
install-tiller: kubeconfig
	kubectl get -n kube-system serviceaccount tiller > /dev/null 2>&1 || \
	kubectl -n kube-system create serviceaccount tiller
	kubectl get -n kube-system clusterrolebinding tiller > /dev/null 2>&1 || \
	kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
	helm init --history-max 200 --service-account tiller --upgrade

.PHONY: kubeconfig
kubeconfig:
	chamber exec kops -- kops export kubecfg
