# Notes

## Container
We used debian/bookworm which is the latest stable version as of May 25, 2025.
[Debian Release Information](https://www.debian.org/releases/)


## Vagrant

### settings
When you run Vagrant commands, the Vagrantfile settings are loaded and merged in the following order:

1. Packaged Vagrantfile of the machine
2. Root settings (default: ~/.vagrant.d)
3. Project directory Vagrantfile

The configuration is merged from 1 to 3, with later settings taking precedence.

----

### VAGRANT_CWD
VAGRANT_CWD is an environment variable that sets the working directory for Vagrant commands. By default, Vagrant will use the current directory, but you can override this by setting VAGRANT_CWD:

```bash
export VAGRANT_CWD=/path/to/vagrant/project
```


## k3s

### Install k3s
```bash
curl -sfL https://get.k3s.io | sh -
```
### Uninstall k3s
```bash
/usr/local/bin/k3s-uninstall.sh
```
### Check k3s status
```bash
sudo systemctl status k3s
```
### Check k3s version
```bash
k3s --version
```
### Check k3s nodes
```bash
k3s kubectl get nodes
```
### Check k3s pods
```bash
k3s kubectl get pods -A
```
### Check k3s services
```bash
k3s kubectl get services -A
```
### Check k3s deployments
```bash
k3s kubectl get deployments -A
```
### Check k3s namespaces
```bash
k3s kubectl get namespaces
```
### Check k3s logs
```bash
k3s kubectl logs <pod-name> -n <namespace>
```
### Check k3s events
```bash
k3s kubectl get events -A
```
### Check k3s config
```bash
k3s kubectl config view
```