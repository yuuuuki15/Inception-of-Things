all: create

create:
	bash ./scripts/check_sudo.sh
	sudo bash ./scripts/install.sh
	sudo bash ./scripts/dev.sh
	sudo bash ./scripts/install_cluster_helm.sh

destroy:
	bash ./scripts/check_sudo.sh
	sudo bash ./scripts/uninstall.sh

.PHONY: all create destroy
