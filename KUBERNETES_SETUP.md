# Configuration Kubernetes - BiblioTEC

## Manifests créés (23 fichiers)

### Configuration de base (4 fichiers)
- `namespace.yaml` - Namespace bibliotec
- `configmap.yaml` - Variables de configuration
- `secrets.yaml` - Secrets (DB, Django)
- `kustomization.yaml` - Configuration Kustomize

### PostgreSQL (3 fichiers)
- `postgres-pvc.yaml` - PersistentVolumeClaim 10Gi
- `postgres-deployment.yaml` - Deployment PostgreSQL 16
- `postgres-service.yaml` - Service ClusterIP

### Django (3 fichiers)
- `django-pvc.yaml` - PVC pour static (5Gi) et media (20Gi)
- `django-deployment.yaml` - Deployment 3 replicas + health checks
- `django-service.yaml` - Service ClusterIP avec session affinity

### Nginx (3 fichiers)
- `nginx-configmap.yaml` - Configuration Nginx
- `nginx-deployment.yaml` - Deployment 2 replicas
- `nginx-service.yaml` - Service LoadBalancer

### Jobs et automatisation (3 fichiers)
- `migration-job.yaml` - Job pour migrations DB
- `collectstatic-job.yaml` - Job pour fichiers statiques
- `backup-cronjob.yaml` - Backup automatique quotidien + PVC 50Gi

### Réseau et scaling (2 fichiers)
- `ingress.yaml` - Ingress avec support SSL/TLS
- `hpa.yaml` - Autoscaling horizontal 2-10 replicas

### Scripts et documentation (5 fichiers)
- `deploy.sh` - Script de déploiement automatisé
- `Makefile` - Commandes simplifiées
- `README.md` - Guide complet Kubernetes
- `QUICKSTART.md` - Démarrage rapide
- `COMMANDS.md` - Aide-mémoire commandes

## Architecture

```
Ingress (nginx-ingress-controller)
    |
    v
LoadBalancer Service (nginx-service:80/443)
    |
    v
Nginx Deployment (2 replicas)
    |
    v
ClusterIP Service (bibliotec-web-service:8000)
    |
    v
Django Deployment (3 replicas + HPA 2-10)
    |
    v
ClusterIP Service (postgres-service:5432)
    |
    v
PostgreSQL Deployment (1 replica)
    |
    v
PersistentVolume (postgres-pvc: 10Gi)
```

## Volumes persistants

| Volume | Taille | Usage |
|--------|--------|-------|
| postgres-pvc | 10Gi | Base de données PostgreSQL |
| django-static-pvc | 5Gi | Fichiers statiques CSS/JS |
| django-media-pvc | 20Gi | Images et fichiers uploadés |
| postgres-backup-pvc | 50Gi | Backups quotidiens |

## Fonctionnalités

- Multi-replicas avec haute disponibilité
- Autoscaling automatique (CPU/Memory)
- Rolling updates sans interruption
- Health checks (liveness + readiness)
- Persistence complète des données
- Backups automatiques quotidiens
- Gestion des secrets sécurisée
- Monitoring et logging
- Ingress pour accès externe

## Déploiement

### Développement local (minikube)

```bash
cd k8s
make build
make load-minikube
./deploy.sh
make port-forward
```

### Production (cluster K8s)

```bash
cd k8s

# 1. Modifier les secrets
kubectl create secret generic bibliotec-secrets \
  --from-literal=DJANGO_SECRET_KEY="votre-cle" \
  --from-literal=POSTGRES_PASSWORD="password-fort" \
  -n bibliotec

# 2. Déployer
./deploy.sh

# 3. Configurer Ingress
kubectl apply -f ingress.yaml
```

## Commandes utiles

```bash
# État
kubectl get all -n bibliotec

# Logs
kubectl logs -f deployment/bibliotec-web -n bibliotec

# Shell
kubectl exec -it deployment/bibliotec-web -n bibliotec -- python manage.py shell

# Scaling
kubectl scale deployment/bibliotec-web --replicas=5 -n bibliotec

# Mise à jour
kubectl set image deployment/bibliotec-web web=bibliotec-web:v2 -n bibliotec

# Rollback
kubectl rollout undo deployment/bibliotec-web -n bibliotec
```

## Ressources configurées

### Requests (minimum garanti)
- Django: 512Mi RAM, 500m CPU
- PostgreSQL: 256Mi RAM, 250m CPU
- Nginx: 128Mi RAM, 100m CPU

### Limits (maximum autorisé)
- Django: 2Gi RAM, 2000m CPU
- PostgreSQL: 1Gi RAM, 1000m CPU
- Nginx: 512Mi RAM, 500m CPU

## Autoscaling (HPA)

- Min replicas: 2
- Max replicas: 10
- Trigger CPU: 70%
- Trigger Memory: 80%

## Backup

CronJob configuré pour backup quotidien à 2h du matin.
Retention: 30 derniers backups.

## Monitoring

```bash
# Ressources
kubectl top pods -n bibliotec
kubectl top nodes

# HPA
kubectl get hpa -n bibliotec

# Events
kubectl get events -n bibliotec
```

---

BiblioTEC - Université Alioune Diop de Bambey
