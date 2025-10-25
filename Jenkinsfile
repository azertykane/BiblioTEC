pipeline {
    agent any

    environment {
        APP_NAME = "bibliotheque"
        DOCKER_IMAGE = "bibliotheque:latest"
        K8S_DEPLOYMENT = "k8s/deployment.yaml"
        K8S_SERVICE = "k8s/service.yaml"
        K8S_INGRESS = "k8s/ingress.yaml"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "\uClonage du dépôt Git...\u"
                git 'https://github.com/azertykane/BiblioTEC.git'
            }
        }

        stage('Linting & Tests') {
            steps {
                echo "\uExécution des tests Django...\u001B[0m"
                sh 'python3 manage.py test || true'  
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "\u Construction de l\'image Docker...\u001B[0m"
                sh '''
                eval $(minikube docker-env)
                docker build -t ${DOCKER_IMAGE} .
                '''
            }
        }

        stage('Push Docker Image (Docker Hub)') {
            steps {
                echo "\u Envoi de l\'image sur Docker Hub...\u"
                withCredentials([usernamePassword(credentialsId: 'dockerhub-cred', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    docker tag ${DOCKER_IMAGE} ${DOCKER_USER}/${APP_NAME}:latest
                    docker push ${DOCKER_USER}/${APP_NAME}:latest
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "\uDéploiement sur Kubernetes via Ansible...\u"
                sh '''
                ansible-playbook ansible/deploy_bibliotec.yml
                '''
            }
        }
    }

    post {
        success {
            echo "\u Déploiement réussi ! L'application est en ligne sur Minikube.\u"
            sh 'minikube service bibliotheque-service --url'
        }
        failure {
            echo "\Échec du pipeline.\[0m"
        }
    }
}
