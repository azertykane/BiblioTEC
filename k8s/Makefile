# Makefile pour Kubernetes - BiblioTEC

NAMESPACE = bibliotec
IMAGE_NAME = bibliotec-web
IMAGE_TAG = latest

.PHONY: help build deploy status logs shell clean

help:
	@echo "Commandes Kubernetes pour BiblioTEC"
	@echo ""
	@echo "  make build        Build l'image Docker"
	@echo "  make deploy       Déployer sur Kubernetes"
	@echo "  make status       Voir l'état du déploiement"
	@echo "  make logs         Voir les logs"
	@echo "  make shell        Ouvrir un shell Django"
	@echo "  make scale        Scaler l'application"
	@echo "  make restart      Redémarrer les pods"
	@echo "  make clean        Supprimer le déploiement"

build:
	@echo "Build de l'image Docker..."
	cd .. && docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

load-minikube: build
	@echo "Chargement de l'image dans minikube..."
	minikube image load $(IMAGE_NAME):$(IMAGE_TAG)

load-kind: build
	@echo "Chargement de l'image dans kind..."
	kind load docker-image $(IMAGE_NAME):$(IMAGE_TAG)

deploy:
	@echo "Déploiement de BiblioTEC..."
	./deploy.sh

apply:
	@echo "Application des manifests..."
	kubectl apply -f namespace.yaml
	kubectl apply -f configmap.yaml
	kubectl apply -f secrets.yaml
	kubectl apply -f nginx-configmap.yaml
	kubectl apply -f postgres-pvc.yaml
	kubectl apply -f django-pvc.yaml
	kubectl apply -f postgres-deployment.yaml
	kubectl apply -f postgres-service.yaml
	kubectl apply -f django-deployment.yaml
	kubectl apply -f django-service.yaml
	kubectl apply -f nginx-deployment.yaml
	kubectl apply -f nginx-service.yaml
	kubectl apply -f ingress.yaml
	kubectl apply -f hpa.yaml

status:
	@echo "État du déploiement:"
	@kubectl get all -n $(NAMESPACE)

pods:
	@kubectl get pods -n $(NAMESPACE)

services:
	@kubectl get svc -n $(NAMESPACE)

logs:
	@kubectl logs -f deployment/bibliotec-web -n $(NAMESPACE)

logs-postgres:
	@kubectl logs -f deployment/postgres -n $(NAMESPACE)

logs-nginx:
	@kubectl logs -f deployment/nginx -n $(NAMESPACE)

shell:
	@kubectl exec -it deployment/bibliotec-web -n $(NAMESPACE) -- python manage.py shell

bash:
	@kubectl exec -it deployment/bibliotec-web -n $(NAMESPACE) -- /bin/bash

migrate:
	@kubectl apply -f migration-job.yaml
	@kubectl wait --for=condition=complete --timeout=300s job/django-migrations -n $(NAMESPACE)

collectstatic:
	@kubectl apply -f collectstatic-job.yaml
	@kubectl wait --for=condition=complete --timeout=300s job/django-collectstatic -n $(NAMESPACE)

scale:
	@kubectl scale deployment/bibliotec-web --replicas=5 -n $(NAMESPACE)

restart:
	@kubectl rollout restart deployment/bibliotec-web -n $(NAMESPACE)

restart-all:
	@kubectl rollout restart deployment -n $(NAMESPACE)

port-forward:
	@echo "Accès via http://localhost:8080"
	@kubectl port-forward -n $(NAMESPACE) svc/nginx-service 8080:80

describe:
	@kubectl describe deployment/bibliotec-web -n $(NAMESPACE)

top:
	@kubectl top pods -n $(NAMESPACE)

clean:
	@echo "Suppression du déploiement..."
	@kubectl delete namespace $(NAMESPACE)

delete-jobs:
	@kubectl delete jobs --all -n $(NAMESPACE)

