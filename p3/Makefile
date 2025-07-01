create:
	bash ./scripts/check_sudo.sh
	sudo bash ./scripts/setup_vm.sh
	sudo bash ./scripts/install_cluster.sh

clean_argo:
	bash ./scripts/check_sudo.sh
	sudo kubectl delete pods --all --namespace argocd

clean:
	bash ./scripts/check_sudo.sh
	sudo kubectl delete pods --all --all-namespaces
	sudo bash ./scripts/uninstall.sh

.PHONY: create clean_argo clean
