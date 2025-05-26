# Notes

## Container
We used debian/bookworm which is the latest stable version as of May 25, 2025.
[Debian Release Information](https://www.debian.org/releases/)
[Debian Cloud Image](https://portal.cloud.hashicorp.com/vagrant/discover/debian/bookworm64)

## Vagrant

### Settings
When you run Vagrant commands, the Vagrantfile settings are loaded and merged in the following order:

1. Packaged Vagrantfile of the machine
2. Root settings (default: ~/.vagrant.d)
3. Project directory Vagrantfile

The configuration is merged from 1 to 3, with later settings taking precedence.

### Important Vagrantfile Settings

```ruby
Vagrant.configure("2") do |config|
  # This specifies the Vagrant configuration version (v2)

  # Dynamically sets username from system
  username = `whoami`.strip

  # VirtualBox provider configuration
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048  # Allocates 2GB RAM to each VM
    vb.cpus = 2       # Allocates 2 CPU cores to each VM
  end

  # Synced folder options
  # create: true - creates the directory if it doesn't exist
  s.vm.synced_folder "./shared", "/vagrant/shared", create: true

  # Private network configuration
  # ip: sets a static IP address for the VM
  s.vm.network "private_network", ip: "192.168.56.110"
end
```

## K3S initializing script
### server installation
```bash
export INSTALL_K3S_EXEC="server --flannel-iface=eth1 --write-kubeconfig-mode 644"
curl -sfL https://get.k3s.io | sh -s -
```
Flag explanation:

- server: Installs k3s in server mode
- --flannel-iface=eth1: Specifies the network interface for Flannel to use (eth1 is our VM private network interface used for VM-to-VM communication)
- --write-kubeconfig-mode 644: Sets permissions on the kubeconfig file to be readable by all users (644 = rw-r--r--)

### agent installation
```bash
export K3S_TOKEN=$(cat /vagrant/shared/node-token)
export K3S_URL="https://192.168.56.110:6443"
export INSTALL_K3S_EXEC="--flannel-iface=eth1"
curl -sfL https://get.k3s.io | sh -s -
```
environment explanation:
- K3S_TOKEN: Authentication token for joining the cluster (read from shared token file)
- K3S_URL: URL of the k3s server to connect to (specifying this makes it install as an agent)
- INSTALL_K3S_EXEC: Additional flags for the agent installation

### token sharing mechanism
The token is stored in a shared directory mounted at `/vagrant/shared` on each VM. This allows the server to write the token once, and all agents can read it to join the cluster.
```bash
# Server side
sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/shared/node-token

# Agent side
TIMEOUT=10
while [ ! -f /vagrant/shared/node-token ] && [ $TIMEOUT -gt 0 ]; do
    echo "Waiting for node-token to be available..."
    sleep 1
    TIMEOUT=$((TIMEOUT - 1))
done
```

### system-wide Aliases and Path configuration
We set up system-wide aliases and PATH configurations for all users:
```bash
# Create system-wide alias for kubectl
echo 'alias k="kubectl"' | sudo tee /etc/profile.d/k3s-aliases.sh
sudo chmod +x /etc/profile.d/k3s-aliases.sh

# Add /sbin to PATH for all users
echo "PATH=$PATH" >> /etc/profile.d/k3s-path.sh
```
Details:
- profile.d directory is loaded by all login shells
- Files ending in .sh are executed during user login
- Making these files executable ensures they are properly sourced
- These changes apply to all users on the system, not just the current user

### networking tools
```bash
sudo apt install -y net-tools
```
we can use `ifconfig` to check network interfaces and their configurations. path: "/sbin/ifconfig"