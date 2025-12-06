.PHONY: cluster
cluster:
	k3d cluster create --config k3dcluster.yaml

.PHONY: update-argocd
update-argocd:
	curl -L https://raw.githubusercontent.com/argoproj/argo-cd/refs/heads/master/manifests/install.yaml -o k3d/manifests/argocd-install.yaml

.PHONY: clean
clean:
	k3d cluster delete --config k3dcluster.yaml || true

.PHONY: recreate-cluster
recreate-cluster: clean cluster
