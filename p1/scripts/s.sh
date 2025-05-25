#!/bin/bash

apt update -y

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s -

sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/shared/node-token

echo PATH=$PATH >> /etc/default/k3s