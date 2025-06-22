create:
	bash ./scripts/setup_vm.sh
	bash ./scripts/install_cluster.sh

clean_argo:
	kubectl delete pods --all --namespace argocd

clean:
	kubectl delete pods --all --all-namespaces

.PHONY: create clean_argo clean
