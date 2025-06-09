# Part 1

The first part is an introduction to Vagrant, a **VM orchestrator** created by HashiCorp that we will use to provision VirtualBox. The `Vagrantfile` is a configuration file written in Ruby and describes the desired development environment.

Vagrant aims to simplify the deployment of development and test environments (for production, other tools are preferred, such as **Terraform**) across different platforms, making the process reproducible and portable. No more manually creating virtual machines.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Tutorial](#tutorial)
   - [1. VM Definition](#1-vm-definition)
   - [2. Kubernetes Installation](#2-kubernetes-installation)
   - [3. Final Configuration](#3-final-configuration)
- [Resources](#resources)

## Prerequisites

- Vagrant
- VirtualBox as virtualization software

## Configuration

- Minimal resources: 1 CPU and 512 MB RAM (or 1024)
- k3s must be installed on both machines:
  - In controller mode on Server
  - In agent mode on ServerWorker

| **Machine**  | **IP Address**   | **Hostname** |
| :----------- | :--------------- | :----------- |
| Server       | 192.168.56.110   | mboivinS     |
| ServerWorker | 192.168.56.111   | mboivinSW    |

The "Server" machine will act as the server node in Kubernetes (control plane). The "Server Worker" machine will be an agent node.

## Tutorial

1. Create a new subfolder `p1` as required in the project.

   ```sh
   $ mkdir p1
   $ cd p1
   ```

2. The OS we selected is [`debian/bookworm64`](https://www.debian.org/releases/bookworm/) with VirtualBox as the provider. To download and add it to the available boxes (`~/.vagrant.d/boxes/`), run:

   ```sh
   $ vagrant box add debian/bookworm64 --provider virtualbox
   ```

   In Vagrant, a "box" refers to OS images.

3. To generate a `Vagrantfile`, run:

   ```sh
   $ vagrant init debian/bookworm64
   ```

## 1. VM Definition

1. Edit the generated file to create two VMs.

   ```ruby
   Vagrant.configure("2") do |config|
     config.vm.box = "debian/bookworm64"
     server_vm_name = "mboivinS"
     worker_vm_name = "mboivinSW"

     # Server VM
     config.vm.define server_vm_name do |server|
       server.vm.hostname = server_vm_name
       server.vm.network "private_network", ip: "192.168.56.110"

       server.vm.provider "virtualbox" do |vb|
         vb.name = server_vm_name
         vb.memory = "1024"
         vb.cpus = "1"
       end
       server.vm.provision "shell", inline: <<-SHELL
         apt update
         apt install -y curl
       SHELL
     end

     # Server Worker VM
     config.vm.define worker_vm_name do |worker|
       worker.vm.hostname = worker_vm_name
       worker.vm.network "private_network", ip: "192.168.56.111"

       worker.vm.provider "virtualbox" do |vb|
         vb.name = worker_vm_name
         vb.memory = "1024"
         vb.cpus = "1"
       end

       worker.vm.provision "shell", inline: <<-SHELL
         apt update
         apt install -y curl
       SHELL
     end
   end
   ```

2. To ensure everything was set up as expected, up the machines and connect to them via SSH:

   ```sh
   $ vagrant up
   $ vagrant ssh <vm_name>
   ```

## 2. Kubernetes Installation

1. Once everything is running, SSH into the Server machine and install the **k3s agent**:

   ```sh
   $ vagrant ssh mboivinS
   $ curl -sfL https://get.k3s.io | sh -
   ```

2. A token is created at `/var/lib/rancher/k3s/server/node-token`. It is used to authenticate agents joining the k3s server. Since the agent will need it, copy it to the shared folder `/vagrant`. To keep a structured project, use a subfolder `/vagrand/shared`. Add this line to the global config in the `Vagrantfile`:

   ```ruby
   config.vm.synced_folder "./shared", "/vagrant/shared", create: true
   ```

3. Now SSH into Server Worker to **add it as an agent to the k3s server**:

   ```sh
   $ curl -sfL https://get.k3s.io | K3S_URL=https://<server-ip>:6443 K3S_TOKEN=<token> sh -
   ```

4. After confirming everything works, SSH into Server and check that all nodes are present:

   ```sh
   $ sudo kubectl get nodes --output wide
   ```

5. To give `vagrant` user access to `kubectl`, install k3s like this:

   ```sh
   $ curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
   ```

6. You can also enable shell auto completion by following these [steps](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-shell-autocompletion).

## 3. Final Configuration

You can add Kubernetes installation steps to the Vagrantfile using `config.vm.provision`.

You may provision the VM with scripts instead of inline shell (documentation [here](https://developer.hashicorp.com/vagrant/docs/provisioning/shell)).

## Resources

- [VirtualBox Configuration in Vagrantfile](https://developer.hashicorp.com/vagrant/docs/providers/virtualbox/configuration)
- [Set up your development environment](https://developer.hashicorp.com/vagrant/tutorials/get-started/setup-project)
- [Getting Started with K3s: A Practical Guide to Setup and Scaling](https://medium.com/@josephsims1/getting-started-with-k3s-a-practical-guide-to-setup-and-scaling-86769e873ad5)
