create:
	bash ./p3/scripts/setup_vm.sh
	bash ./p3/scripts/install_cluster.sh

clean_argo:
	kubectl delete pods --all --namespace argocd

clean:
	kubectl delete pods --all --all-namespaces

.PHONY: create clean_argo clean
