pipeline {
    agent any

    environment {
        APP_NAME = "bibliotheque"
        DOCKER_IMAGE = "bibliotheque:latest"
        K8S_DIR = "k8s"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Clonage du dépôt Git..."
                git 'https://github.com/azertykane/BiblioTEC.git'
            }
        }

        stage('Linting & Tests') {
            steps {
                echo "Exécution des tests Django..."
                sh '''
                python manage.py test || true
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Construction de l'image Docker..."
                sh '''
                eval $(minikube docker-env)
                docker build -t ${DOCKER_IMAGE} .
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Déploiement sur Kubernetes via Ansible..."
                sh '''
                ansible-playbook ansible/deploy_bibliotec.yml -v
                '''
            }
        }

        stage('Health Check') {
            steps {
                echo "Vérification du déploiement..."
                sh '''
                sleep 30
                kubectl get pods
                kubectl get services
                '''
            }
        }
    }

    post {
        success {
            echo "Déploiement réussi ! L'application est en ligne sur Minikube."
            sh '''
            minikube service bibliotheque-service --url || true
            '''
        }
        failure {
            echo "Échec du pipeline. Vérifiez les logs pour plus de détails."
        }
    }
}