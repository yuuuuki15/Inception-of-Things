#!/bin/bash

apt update -y

export TOKEN=$(cat /vagrant/shared/node-token)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://192.168.56.110:6443 --token $TOKEN" sh -s -

echo PATH=$PATH >> /etc/default/k3s