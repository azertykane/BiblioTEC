#!/bin/bash

# Script de déploiement Kubernetes pour BiblioTEC

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

echo "==============================================================="
echo "  Déploiement Kubernetes - BiblioTEC"
echo "==============================================================="
echo ""

# Vérification des prérequis
log "Vérification des prérequis..."

if ! command -v kubectl &> /dev/null; then
    error "kubectl n'est pas installé"
fi

if ! command -v docker &> /dev/null; then
    error "docker n'est pas installé"
fi

log "Prérequis OK"

# Build de l'image Docker
log "Build de l'image Docker..."
docker build -t bibliotec-web:latest ..
log "Image buildée avec succès"

# Charger l'image dans le cluster (pour minikube/kind)
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    log "Chargement de l'image dans minikube..."
    minikube image load bibliotec-web:latest
elif command -v kind &> /dev/null; then
    log "Chargement de l'image dans kind..."
    kind load docker-image bibliotec-web:latest
fi

# Créer le namespace
log "Création du namespace..."
kubectl apply -f namespace.yaml

# Appliquer les ConfigMaps et Secrets
log "Application des ConfigMaps et Secrets..."
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
kubectl apply -f nginx-configmap.yaml

# Créer les PVC
log "Création des PersistentVolumeClaims..."
kubectl apply -f postgres-pvc.yaml
kubectl apply -f django-pvc.yaml

# Déployer PostgreSQL
log "Déploiement de PostgreSQL..."
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Attendre que PostgreSQL soit prêt
log "Attente de PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n bibliotec

# Lancer les migrations
log "Exécution des migrations..."
kubectl apply -f migration-job.yaml
kubectl wait --for=condition=complete --timeout=300s job/django-migrations -n bibliotec

# Collecter les fichiers statiques
log "Collection des fichiers statiques..."
kubectl apply -f collectstatic-job.yaml
kubectl wait --for=condition=complete --timeout=300s job/django-collectstatic -n bibliotec

# Déployer Django
log "Déploiement de l'application Django..."
kubectl apply -f django-deployment.yaml
kubectl apply -f django-service.yaml

# Attendre que Django soit prêt
log "Attente de l'application Django..."
kubectl wait --for=condition=available --timeout=300s deployment/bibliotec-web -n bibliotec

# Déployer Nginx
log "Déploiement de Nginx..."
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

# Attendre que Nginx soit prêt
log "Attente de Nginx..."
kubectl wait --for=condition=available --timeout=300s deployment/nginx -n bibliotec

# Appliquer l'Ingress
log "Configuration de l'Ingress..."
kubectl apply -f ingress.yaml

# Appliquer l'HPA
log "Configuration de l'autoscaling..."
kubectl apply -f hpa.yaml

echo ""
echo "==============================================================="
echo "  Déploiement terminé avec succès"
echo "==============================================================="
echo ""
echo "État des pods:"
kubectl get pods -n bibliotec
echo ""
echo "Services:"
kubectl get svc -n bibliotec
echo ""
echo "Pour accéder à l'application:"
echo "  - kubectl port-forward -n bibliotec svc/nginx-service 8080:80"
echo "  - http://localhost:8080"
echo ""
echo "Ou si vous utilisez minikube:"
echo "  - minikube service nginx-service -n bibliotec"
echo ""

