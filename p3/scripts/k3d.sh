#!/bin/bash

# Create cluster
sudo k3d cluster create p3 --agents 2 -p "8080:80@loadbalancer"
# Create namespaces
sudo kubectl create namespace dev
sudo kubectl create namespace argocd
