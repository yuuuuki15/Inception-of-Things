create:
	k3d cluster create p3 --agents 2 -p "8080:80@loadbalancer"
	kubectl create namespace argocd
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update

clean_argo:
	kubectl delete pods --all --namespace argocd

clean:
	kubectl delete pods --all --all-namespaces

.PHONY: create clean_argo clean
