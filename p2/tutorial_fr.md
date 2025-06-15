# Partie 2

Dans cette seconde partie, la consigne est de créer une machine virtuelle, de déployer trois applications web et de rediriger les requêtes selon l'hôte demandé. C'est l'occasion de découvrir **Ingress**, un composant Kubernetes permettant d'exposer des services web à l'extérieur du cluster via HTTP(S).

## Table des matières

- [Pré-requis](#pré-requis)
- [Tutoriel](#tutoriel)
   - [1. Création des ressources Kubernetes](#1-création-des-ressources-kubernetes)
   - [2. Application des manifestes](#2-application-des-manifestes)
   - [3. À la découverte de Helm](#3-à-la-découverte-de-helm)
- [Ressources](#ressources)

## Pré-requis

- Vagrant
- VirtualBox comme logiciel de virtualisation

## Tutoriel

1. Créer un nouveau sous-dossier `p2` comme demandé dans le projet.

   ```sh
   $ mkdir p2
   $ cd p2
   ```

2. Reprendre le Vagrantfile et le script d'installation de la machine *Server* de la [partie 1](/p1/tutorial_fr.md).

### 1. Définition des ressources Kubernetes

Il va ensuite falloir rédiger au format YAML pour chacune des trois applications :

- Des [**déploiements**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) que l'on peut voir comme des sortes de **fiches techniques** qui décrivent le nombre de répliques voulues, quelle image utiliser, comment redémarrer le pod si besoin, et ainsi de suite.
- Des [**services**](https://kubernetes.io/docs/concepts/services-networking/service/) pour **exposer les applications** en leur fournissant une **adresse stable** et en permettant la communication vers l'extérieur avec Ingress.

Pour compléter, il nous faut en plus :

- Un [**Ingress**](https://kubernetes.io/docs/concepts/services-networking/ingress/).
- Un [**namespace**](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) que l'on peut voir métaphoriquement comme un espace de rangement. C'est toujours plus propre que de tout laisser dans l'espace de nommage par défaut.

Comme dans le sujet, on utilise l'image [`hello-kubernetes`](https://github.com/paulbouwer/hello-kubernetes) de Paul Bouwer dont on change le message d'accueil par défaut grâce à la variable d'environnement `MESSAGE`.

Le namespace :

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: p2
```

Si on veut utiliser ce namespace, il faudra rajouter `namespace: p2` dans les `metadata` de chaque ressource.

Les déploiements :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  namespace: p2
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: app1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app1
    spec:
      containers:
      - name: hello-kubernetes
        image: paulbouwer/hello-kubernetes:1.10
        ports:
        - containerPort: 8080
        env:
        - name: MESSAGE
          value: "Hello from app1."
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
  namespace: p2
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: app2
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app2
    spec:
      containers:
      - name: hello-kubernetes
        image: paulbouwer/hello-kubernetes:1.10
        ports:
        - containerPort: 8080
        env:
        - name: MESSAGE
          value: "Hello from app2."
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app3
  namespace: p2
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: app3
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app3
    spec:
      containers:
      - name: hello-kubernetes
        image: paulbouwer/hello-kubernetes:1.10
        ports:
        - containerPort: 8080
        env:
        - name: MESSAGE
          value: "Hello from app3."
```

Les services :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app1-svc
  namespace: p2
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app.kubernetes.io/name: app1
---
apiVersion: v1
kind: Service
metadata:
  name: app2-svc
  namespace: p2
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app.kubernetes.io/name: app2
---
apiVersion: v1
kind: Service
metadata:
  name: app3-svc
  namespace: p2
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app.kubernetes.io/name: app3
```

Pour finir, afin de rediriger les requêtes vers la bonne application grâce à Ingress. Hormis pour l'application nous faut des [règles sur le nom de domaine](https://kubernetes.io/docs/concepts/services-networking/ingress/#hostname-wildcards) :

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: p2-ingress
  namespace: p2
spec:
  rules:
  - host: app1.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-svc
            port:
              number: 80
  - host: app2.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-svc
            port:
              number: 80
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app3-svc
            port:
              number: 80
```

### 2. Application des manifestes

1. Tout d'abord, il faut se connecter en SSH à notre machine :

   ```sh
   $ vagrant ssh <machine>
   ```

2. On place les fichiers YAML décrivant nos ressources dans le dossier partagé de Vagrant et les applique avec la commande `kubectl apply`. En admettant qu'on ait placé les manifestes dans le dossier `/vagrant/shared/manifests/`, on commence par le namespace :

   ```sh
   $ kubectl apply -f /vagrant/shared/manifests/namespace.yaml
   ```

   Puis les déploiements :

   ```sh
   $ kubectl apply -f /vagrant/shared/manifests/deployments.yaml
   ```

   On vérifie qu'il y a bien trois répliques pour l'application 2 :

   ```sh
   $ kubectl get deployments
   NAME   READY   UP-TO-DATE   AVAILABLE   AGE
   app1   1/1     1            1           64m
   app2   3/3     3            3           64m
   app3   1/1     1            1           64m
   ```

   On peut ensuite appliquer les services et l'Ingress :

   ```sh
   $ kubectl apply -f /vagrant/shared/manifests/services.yaml
   $ kubectl apply -f /vagrant/shared/manifests/ingress.yaml
   ```

3. Pour vérifier que tout fonctionne comme prévu, on peut utiliser `curl` :

   ```sh
   $ curl -H "Host:app1.com" 192.168.56.110
   ```

   Et/ou ouvrir notre navigateur et visiter `192.168.56.110` en changeant le header `Host`.

### 3. À la découverte de Helm

Cette manière de faire était simple et directe, mais un peu répétitive. Les déploiements et services étaient du copier-coller à peu de choses près. On peut donc tenter d'utiliser Helm pour rendre le tout plus modulaire.

Rappel sur la syntaxe [Go templates](https://pkg.go.dev/text/template) :

| **Syntaxe**   | **Signification**                   |
| ------------- | ----------------------------------- |
| `.`           | Contexte actuel                     |
| `$`           | Contexte global                     |
| `{{- ... -}}` | Supprime les espaces/sauts de ligne |
| `range`       | Boucle sur une liste/map            |

1. Un Helm Chart est un package. Pour le créer :

   ```sh
   $ helm create part2
   ```

   Nous obtenons cette structure :

   ```
   charts/
   ├── Chart.yaml
   ├── values.yaml
   └── templates/
       └── deployment.yaml
   ```

2. Il n'y a rien ou presque à changer dans `Chart.yaml`, si ce n'est la description du package.

3. Le fichier `Values.yaml` contient les variables de notre projet. Il va servir à centraliser les valeurs qui viendront remplir les déploiements, services et autres ressources. On peut y mettre tout ce qui différait d'un service à l'autre et nous forçait à le copier-coller juste pour changer une valeur comme, par exemple, le nombre de répliques. Cela permet de faire des modifications sans toucher aux autres fichiers YAML.

4. Les déploiements et services sont simplifiés. Plutôt que de répéter trois fois la même chose, à quelques valeurs près, on ne l'écrit qu'une fois et on utilise `range` pour boucler sur les `values` et ainsi générer le YAML.

5. Une fois que tous les templates sont rédigés, on peut installer le projet, ici appelé "part2" :

   ```sh
   $ helm install part2 charts/
   ```

6. Il est possible de générer le manifeste du projet au format YAML avec la commande suivante :

   ```sh
   $ helm get manifest part2
   ```

   Ce qui nous permet de la comparer avec nos fichiers écrits au début du tutoriel et de vérifier qu'ils sont identiques.

## Ressources

- [Using kubectl to Create a Deployment](https://kubernetes.io/docs/tutorials/kubernetes-basics/deploy-app/deploy-intro/)
- [🇫🇷 Comprendre Kubernetes Ingress : Plongée dans le vrai Load-balancer](https://www.sfeir.dev/cloud/comprendre-kubernetes-ingress-plongee-dans-le-vrai-load-balancer-demo-minikube/)
