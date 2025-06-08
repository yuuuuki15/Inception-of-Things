#!/bin/bash

# run k3d
# doc: https://k3d.io/stable/#quick-start
sudo k3d cluster create p3 --port 8080:80@loadbalancer

#argocd
# doc: https://argo-cd.readthedocs.io/en/stable/getting_started/?_gl=1*ohm18h*_ga*MTc5Nzk0MTUzMS4xNzQ4ODY2MjU0*_ga_5Z1VTPDL73*czE3NDg4NjYyNTQkbzEkZzEkdDE3NDg4NjYyNzckajM3JGwwJGgw
sudo kubectl create namespace argocd
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# create ingress
sudo kubectl apply -n argocd -f configs/ingress.yaml

# get password
password=$(sudo kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)

# login
echo "password: $password"
