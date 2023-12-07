---
sidebar_position: 2
---

# Installation

:::warning

Attention, nous partons du principe que vous êtes sous un système d'exploitation `Linux` ou `MacOS`.
Si vous souhaitez voir l'installation pour un OS Windows merci de vous reférez à la documentation Jenkins
en [cliquant ici](https://www.jenkins.io/doc/book/installing/docker/#on-windows).

:::

Afin de comprendre au mieux les commandes que nous allons utiliser prochainement.
Nous vous conseillons d'avoir les connaissances de base sur Docker.

## Docker

### Création d'un réseau

Dans un premier temps, vous devez créer un réseau en mode `bridge` grâce à la commande suivante :

```bash
docker network create jenkins # ici "jenkins" correspond au nom du réseau
```

### Création d'un container avec l'image `docker:dind`

Ensuite, afin de pouvoir exécuter des commandes Docker à l'intérieur des nœuds Jenkins, nous devons
utiliser l'image `docker:dind`. Nous pouvons l'installer en utilisant la commande ci-dessous.

```bash
docker run --name jenkins-docker --rm --detach \
  --privileged --network jenkins --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  docker:dind --storage-driver overlay2
```

:::info

1. L'option `--name` est optionnelle, elle permet de spécifier le nom du container une fois lancé
2. L'option `--rm` est optionnelle, elle supprime le container une fois qu'on éteint celui-ci
3. L'option `--detach` est optionnelle, elle permet de faire tourner le container en arrière-plan (Vous pouvez
   l'éteindre en utilisant la commande `docker stop jenkins-docker`)
4. L'option `--privileged` donne un accès privilégié, en effet afin de faire tourner Docker dans Docker, nous avons
   besoin de certain droit.
5. L'option `--network jenkins` affilie le container a ce réseau (nous l'avons créé dans l'étape précédente)
6. lorem
7. L'option `--env DOCKER_TLS_CERTDIR=/certs` active l'utilisation du
   TLS ([Transport Layer Security](https://www.digicert.com/fr/what-is-ssl-tls-and-https#:~:text=TLS%3A%20Transport%20Layer%20Security,vous%20achetez%20un%20certificat%20TLS.)).
   Étant donné que notre container tourne avec des droits privilégiés, cette option est recommandée puisque nous
   utilisons des volumes partagés. Cette variable d'environnement permet de contrôler le dossier racine où sont stockés
   les certificats TLS.
8. L'option `--volume jenkins-docker-certs:/certs/client` affilie le répertoire `/certs/client` à l'intérieur du
   container dans le volume nommé `jenkins-docker-certs`.
9. L'option `--volume jenkins-data:/var/jenkins_home` affilie le répertoire `/var/jenkins_home` à l'intérieur du
   container dans un volume nommé `jenkins-data`. Cela permet aux containers Docker créé par ce container de monter des
   données depuis Jenkins.
10. L'option `--publish 2376:2376` est optionnelle, elle permet d'ouvrir le port qui permet d'utiliser le démon Docker
    de la machine hôte afin de contrôler ce démon Docker interne. Cependant, vous pouvez ouvrir d'autre port, tel que le
    port 3000 si jamais vous lancez le serveur interne d'une application node par exemple.
11. L'image `docker:dind` elle-même.
12. L'option `--storage-driver overlay2` est le gestionnaire de stockage pour le volume Docker. Reportez-vous à la
    documentation des gestionnaires de stockage Docker pour connaître les options prises en charge
    en [cliquant ici](https://docs.docker.com/storage/storagedriver/select-storage-driver).

:::

## Jenkins

### Création de l'image Jenkins

Maintenant, nous avons besoin d'installer l'image officielle de Jenkins.

Pour ce faire, nous devons créer un `Dockerfile` avec les instructions suivantes :

```dockerfile title="Dockerfile"
FROM jenkins/jenkins:2.426.1-jdk17
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"
```

Puis, nous devons ensuite `build` l'image en executant la commande ci-dessous :

```bash
docker build -t myjenkins-blueocean:2.426.1-1 .
```

### Mise en place du container

Vous pouvez lancer votre container avec la commande `docker run` suivante : 

```bash
docker run --name jenkins-blueocean --restart=on-failure --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --publish 49000:8080 --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  myjenkins-blueocean:2.426.1-1
```

:::info

1. L'option `--name` est optionnelle, elle permet de spécifier le nom du container une fois lancé
2. L'option `--restart=on-failure` permet de redémarrer le container une fois stoppé. Si il est arrêté manuellement alors, il sera relancé uniquement lorsque le démon Docker redémarrera ou si le container est redémarré manuellement 
3. L'option `--detach` est optionnelle, elle permet de faire tourner le container en arrière-plan
4. L'option `--network jenkins` affilie le container a ce réseau (nous l'avons créé dans l'étape précédente)
5. L'option `--env DOCKER_HOST=tcp://docker:2376 --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=` spécifie les variables d'environnement utilisé par `docker`, `docker-compose` et les autres outils de Docker pour connecter le démon Docker de l'étape précédente.
6. L'option `--publish 49000:8080` publie le port 8080 du container courant au port 49000 de la machine hôte.
7. L'option `--volume jenkins-data:/var/jenkins_home` affilie le répertoire `/var/jenkins_home` à l'intérieur du
   container dans un volume nommé `jenkins-data`. Cela permet aux containers Docker créé par ce container de monter des
   données depuis Jenkins.
8. 
9. 
10. 

:::
