# Part 2

In this second part, the instruction is to create a virtual machine, deploy three web applications, and redirect requests based on the requested host. This is a great opportunity to discover **Ingress**, a Kubernetes component that allows exposing web services outside the cluster via HTTP(S).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Tutorial](#tutorial)
- [1. Creating Kubernetes Resources](#1-creating-kubernetes-resources)
- [2. Applying the Manifests](#2-applying-the-manifests)
- [3. Discovering Helm](#3-discovering-helm)
- [Resources](#resources)

## Prerequisites

- Vagrant
- VirtualBox as the virtualization software

## Tutorial

1. Create a new subfolder `p2` as instructed in the project.

   ```sh
   $ mkdir p2
   $ cd p2
   ```

2. Reuse the Vagrantfile and the installation script for the *Server* machine from [part 1](/p1/tutorial_en.md).

### 1. Defining Kubernetes Resources

Next, you will need to write YAML definitions for each of the three applications:

- [**Deployments**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), which can be seen as **technical sheets** describing the desired number of replicas, which image to use, how to restart the pod if needed, and so on.
- [**Services**](https://kubernetes.io/docs/concepts/services-networking/service/) to **expose the applications** by providing them with a **stable address** and enabling communication with the outside through Ingress.

Additionally, we need:

- An [**Ingress**](https://kubernetes.io/docs/concepts/services-networking/ingress/).
- A [**Namespace**](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/), which can be metaphorically seen as a storage space. It's always cleaner than leaving everything in the default namespace.

As specified in the instructions, we use Paul Bouwer's [`hello-kubernetes`](https://github.com/paulbouwer/hello-kubernetes) image, and change the default welcome message using the `MESSAGE` environment variable.

The namespace:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: hello
```

In order to use this namespace, `namespace: hello` must be appended to each resource's `metadata`.

The deployments:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  namespace: hello
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
  namespace: hello
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
  namespace: hello
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

The services:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app1-svc
  namespace: hello
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
  namespace: hello
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
  namespace: hello
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app.kubernetes.io/name: app3
```

Finally, to redirect requests to the correct application using Ingress, we need to define [rules based on the domain name](https://kubernetes.io/docs/concepts/services-networking/ingress/#hostname-wildcards):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-ingress
  namespace: hello
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

### 2. Applying the Manifests

1. First, SSH into the machine:

   ```sh
   $ vagrant ssh <machine>
   ```

2. Place the YAML files describing the resources in Vagrant's shared folder and apply them using the `kubectl apply` command. Assuming the manifests are in the `/vagrant/shared/manifests/` folder, start with the namespace:

   ```sh
   $ kubectl apply -f /vagrant/shared/manifests/namespace.yaml
   ```

   Then, the deployments:

   ```sh
   $ kubectl apply -f /vagrant/shared/manifests/deployments.yaml
   ```

   Ensure there are three replicas for application number two:

   ```sh
   $ kubectl get deployments
   NAME   READY   UP-TO-DATE   AVAILABLE   AGE
   app1   1/1     1            1           64m
   app2   3/3     3            3           64m
   app3   1/1     1            1           64m
   ```

   Apply the services and the Ingress configurations:

   ```sh
   $ kubectl apply -f /vagrant/shared/manifests/services.yaml
   $ kubectl apply -f /vagrant/shared/manifests/ingress.yaml
   ```

3. Use `curl` to ensure everything works as expected:

   ```sh
   $ curl -H "Host:app1.com" 192.168.56.110
   ```

   Open the web browser and visit `192.168.56.110`. Try to change the `Host` header.

### 3. Discovering Helm

This method was simple and straightforward, but also a bit repetitive. The deployments and services were mostly copy-pasted with only slight differences. We can use Helm to make everything more modular.

Reminder on [Go template](https://pkg.go.dev/text/template) syntax:

| **Syntax**    | **Meaning**                         |
| ------------- | ----------------------------------- |
| `.`           | Current context                     |
| `$`           | Global context                      |
| `{{- ... -}}` | Trims spaces/newlines               |
| `range`       | Loops over a list/map               |

1. A Helm Chart is a package. To create one:

   ```sh
   $ helm create hello
   ```

   It generates the following structure:

   ```
   hello-chart/
   ├── Chart.yaml
   ├── values.yaml
   └── templates/
       └── deployment.yaml
   ```

   Note I renamed the `hello-chart` folder to `charts`.

2. There's almost nothing to change in `Chart.yaml`, except for the package description.

3. The `Values.yaml` file contains the variables for our project. It is used to centralize values that will populate deployments, services, and other resources. We can put everything that differs between services in this file, which previously forced us to copy-paste just to change a single value—like the number of replicas. This makes it possible to make changes without touching the other YAML files.

4. Deployments and services are simplified. Instead of repeating the same thing three times with only a few differences, we write it once and use `range` to loop over `values` and generate the YAML.

5. Once all the templates are written, we can install the project, here called "hello":

   ```sh
   $ helm install hello charts/
   ```

6. You can generate the YAML manifest with the following command:

   ```sh
   $ helm get manifest hello
   ```

   This way, it is easy to compare it against our files written at the beginning of the tutorial and check they are identical.

## Resources

- [Using kubectl to Create a Deployment](https://kubernetes.io/docs/tutorials/kubernetes-basics/deploy-app/deploy-intro/)
- [🇫🇷 Comprendre Kubernetes Ingress : Plongée dans le vrai Load-balancer](https://www.sfeir.dev/cloud/comprendre-kubernetes-ingress-plongee-dans-le-vrai-load-balancer-demo-minikube/)
