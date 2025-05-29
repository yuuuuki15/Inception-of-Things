#!/bin/bash
# Set up Server machine
K3S_TOKEN_PATH="/vagrant/shared/node-token"

apt update && apt install -y curl vim

curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
# Share the token for the workers
cp /var/lib/rancher/k3s/server/node-token ${K3S_TOKEN_PATH}
