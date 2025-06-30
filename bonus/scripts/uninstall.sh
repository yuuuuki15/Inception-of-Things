#!/bin/bash

# destroy cluster
sudo k3d cluster delete p3

# remove argocd and gitlab DNS entry from /etc/hosts(create backup named /etc/hosts.bak)
sudo sed -i.bak -e '/^127\.0\.0\.1\s\+argocd\.local$/d' -e '/^10\.10\.10\.10\s\+gitlab\.local$/d' /etc/hosts
