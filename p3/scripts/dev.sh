#!/bin/bash'

set -e

sudo helm repo add nginx-stable https://helm.nginx.com/stable
sudo helm repo update

# Create cluster
sudo k3d cluster create p3 --agents 2 -p "8080:80@loadbalancer"
# Create namespaces
sudo kubectl create namespace dev

sudo helm install nginx-ingress nginx-stable/nginx-ingress --namespace dev
