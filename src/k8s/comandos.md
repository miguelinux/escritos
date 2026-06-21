# Comandos de k8s

* `kubectl --help`: Muestra la ayuda de comandos básicos para kubectl.
* `minikube --help`: Muestra las opciones disponibles para minikube.
* `minikube start --driver=docker`: Inicia un clúster de Minikube utilizando
    Docker como driver.
* `kubectl get nodes`: Muestra los nodos en el clúster.
* `minikube addons list`: Lista los complementos disponibles en Minikube.
* `minikube addons enable registry`: Habilita el registro local.
* `minikube addons enable metrics-server`: Habilita el servidor de métricas.
* `eval $(minikube -p minikube docker-env)`: Habilita el uso del **registry** de
  minikube
* `kubectl config get-context`: Obtiene los contexto del cluster
* `kubectl run hello-cloud --image=gcr.io/google-samples/hello-app:2.0
  --restart=Never --port=8080`: Crea un pod
* `minikube dashboard`: Crea un Web GUI dashboard

<!-- vi: set spl=es spell: -->
