# Partie 1

La première partie est une introduction à Vagrant, **un orchestrateur de VMs** créé par HashiCorp que nous allons utiliser pour provisionner VirtualBox. Le `Vagrantfile` est un fichier de configuration écrit en Ruby et décrivant l'environnement de développement souhaité.

Vagrant a pour objectif de faciliter le déploiement d'environnements de développement et de test (pour la production, d'autres outils sont préférés comme par exemple **Terraform**) sur différentes plateformes, en rendant le processus reproductible et portable. Plus besoin de créer des machines virtuelles à la main.

## Table des matières

- [Pré-requis](#pré-requis)
- [Configuration](#configuration)
- [Tutoriel](#tutoriel)
   - [1. Définition des VMs](#1-définition-des-vms)
   - [2. Installation de Kubernetes](#2-installation-de-kubernetes)
   - [3. Configuration finale](#3-configuration-finale)
- [Ressources](#ressources)

## Pré-requis

- Vagrant
- VirtualBox comme logiciel de virtualisation

## Configuration

- Le moins de ressources possible : 1 CPU et 512 MB de RAM (ou 1024)
- k3s doit être installé sur les deux machines :
  - En mode *controller* sur Server
  - En mode *agent* sur ServerWorker

| **Machine**  | **Adresse IP** | **Hostname** |
| :----------- | :------------- | :----------- |
| Server       | 192.168.56.110 | mboivinS     |
| ServerWorker | 192.168.56.111 | mboivinSW    |

La machine "*Server*" servira de *Server Node* dans Kubernetes, soit de plan de contrôle. Quant à la machine "*ServerWorker*", ce sera un *Agent Node*.

## Tutoriel

1. Créer un nouveau sous-dossier `p1` comme demandé dans le projet.

   ```sh
   $ mkdir p1
   $ cd p1
   ```

2. L'OS que nous avons choisi est [`debian/bookworm64`](https://www.debian.org/releases/bookworm/) et le provider VirtualBox. Pour la télécharger et l'ajouter aux boxes disponibles (`~/.vagrant.d/boxes/`), il faut faire la commande suivante :

   ```sh
   $ vagrant box add debian/bookworm64 --provider virtualbox
   ```

   Dans Vagrant, "*box*" désigne les images d'OS.

3. Pour générer un `Vagrantfile`, on fait la commande :

   ```sh
   $ vagrant init debian/bookworm64
   ```

## 1. Définition des VMs

1. On modifie le fichier généré afin de créer deux VMs.

   ```ruby
   Vagrant.configure("2") do |config|
     config.vm.box = "debian/bookworm64"
     server_vm_name = "mboivinS"
     worker_vm_name = "mboivinSW"

     # VM Server
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

     # VM Server Worker
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

2. Pour vérifier que la configuration a été appliquée, lancer les machines et s'y connecter en SSH :

   ```sh
   $ vagrant up
   $ vagrant ssh <vm_name>
   ```

## 2. Installation de Kubernetes

1. Une fois s'être assuré que tout marche bien, on peut passer à l'installation de k3s. Tout d'abord, on va se connecter en SSH à la machine *Server* et on installe l'**agent k3s**.

   ```sh
   $ vagrant ssh mboivinS
   $ curl -sfL https://get.k3s.io | sh -
   ```

2. Un token est créé à cet emplacement : `/var/lib/rancher/k3s/server/node-token`. Il va servir à authentifier les agents qui veulent rejoindre le serveur k3s. Vu que l'agent en aura besoin, on va le copier dans le dossier partagé `/vagrant`. Pour un répertoire bien architecturé, on le placera dans un sous-dossier `/vagrand/shared`. Il faut ajouter cette ligne au Vagrantfile dans la configuration globale :

   ```ruby
   config.vm.synced_folder "./shared", "/vagrant/shared", create: true
   ```

3. Il faut maintenant se connecter en SSH à *Server Worker* afin de l'**ajouter comme agent au serveur k3s**.

   ```sh
   $ curl -sfL https://get.k3s.io | K3S_URL=https://<server-ip>:6443 K3S_TOKEN=<token> sh -
   ```

4. Après nous être assuré que tout fonctionne, on se connecte en SSH à *Server* afin de vérifier que l'on a bien nos noeuds :

   ```sh
   $ sudo kubectl get nodes --output wide
   ```

5. Pour donner les droits sur `kubectl` à l'utilisateur `vagrant`, on installera k3s de cette manière :

   ```sh
   $ curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
   ```

6. Activer l'auto-complétion de kubectl peut être utile. Suivre les étapes détaillées [ici](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/#activation-de-l-auto-compl%C3%A9tion-de-shell).

## 3. Configuration finale

On peut ajouter les étapes d'installation de Kubernetes au Vagrantfile grâce à `config.vm.provision`.

Il est possible de provisionner la VM avec des scripts plutôt que du inline shell (documentation [ici](https://developer.hashicorp.com/vagrant/docs/provisioning/shell)).

## Ressources

- [VirtualBox Configuration in Vagrantfile](https://developer.hashicorp.com/vagrant/docs/providers/virtualbox/configuration)
- [Set up your development environment](https://developer.hashicorp.com/vagrant/tutorials/get-started/setup-project)
- [Getting Started with K3s: A Practical Guide to Setup and Scaling](https://medium.com/@josephsims1/getting-started-with-k3s-a-practical-guide-to-setup-and-scaling-86769e873ad5)
