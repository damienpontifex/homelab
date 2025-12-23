.SHELLFLAGS := -o errexit -o nounset -o pipefail
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

## recreate-cluster: Recreate the k3d cluster by cleaning and then creating it
.PHONY: recreate-cluster
recreate-cluster: clean cluster

## cluster: Create a k3d cluster using the configuration in k3dcluster.yaml
.PHONY: cluster
cluster:
	k3d cluster create --config k3d/k3dcluster.yaml

## clean: Delete the k3d cluster defined in k3dcluster.yaml
.PHONY: clean
clean:
	k3d cluster delete --config k3d/k3dcluster.yaml || true

## watch: Watch for changes in YAML files and apply them to the local Kubernetes cluster
.PHONY: watch
watch:
	@[[ $$(kubectl config current-context) == 'k3d-homelab' ]] || (echo "Error: kubectl context is not set to 'k3d-homelab'" && exit 1)
	watchexec --exts yaml kubectl kustomize --enable-helm apps/local

## help: Display available commands and their descriptions
help:
	@echo "Usage:"
	@sed -n 's/^##//p' $(MAKEFILE_LIST) \
		| sort \
		| awk -v bold="$$(tput bold)" -v normal="$$(tput sgr0)" '{ $$1 = bold $$1 normal; print }' \
		| column -t -s ':'

## azure: Deploy secret infrastructure to azure
azure:
	az deployment group create \
		--resource-group homelab \
		--template-file apps/secrets.bicep \
		--name homelab
