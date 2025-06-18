#!/bin/bash'

set -e

sudo kubectl apply -f configs/dev/app.yaml --namespace argocd
sudo kubectl apply -f configs/dev/ingress.yaml --namespace dev

sudo kubectl port-forward service/playground -n dev 8888:8888 &
