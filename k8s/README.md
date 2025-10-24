# Déploiement Kubernetes - BiblioTEC

Guide pour déployer BiblioTEC sur Kubernetes.

## Prérequis

- Kubernetes cluster (minikube, kind, GKE, EKS, AKS, etc.)
- kubectl configuré
- Docker pour builder l'image

## Architecture Kubernetes

```
Ingress (nginx-ingress-controller)
    |
    v
Nginx Service (LoadBalancer)
    |
    v
Nginx Deployment (2 replicas)
    |
    v
Django Service (ClusterIP)
    |
    v
Django Deployment (3 replicas + HPA)
    |
    v
PostgreSQL Service (ClusterIP)
    |
    v
PostgreSQL Deployment (1 replica)
    |
    v
PostgreSQL PVC (10Gi)
```

## Déploiement rapide

### Option 1: Script automatisé

```bash
cd k8s
chmod +x deploy.sh
./deploy.sh
```

### Option 2: Manuel avec kubectl

```bash
cd k8s

# 1. Créer le namespace
kubectl apply -f namespace.yaml

# 2. ConfigMaps et Secrets
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
kubectl apply -f nginx-configmap.yaml

# 3. PersistentVolumeClaims
kubectl apply -f postgres-pvc.yaml
kubectl apply -f django-pvc.yaml

# 4. PostgreSQL
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# 5. Attendre PostgreSQL
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n bibliotec

# 6. Migrations
kubectl apply -f migration-job.yaml
kubectl wait --for=condition=complete --timeout=300s job/django-migrations -n bibliotec

# 7. Collectstatic
kubectl apply -f collectstatic-job.yaml
kubectl wait --for=condition=complete --timeout=300s job/django-collectstatic -n bibliotec

# 8. Django
kubectl apply -f django-deployment.yaml
kubectl apply -f django-service.yaml

# 9. Nginx
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

# 10. Ingress et HPA
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
```

### Option 3: Avec Kustomize

```bash
kubectl apply -k .
```

## Build de l'image Docker

Avant le déploiement, buildez l'image:

```bash
cd ..
docker build -t bibliotec-web:latest .
```

Pour minikube:
```bash
minikube image load bibliotec-web:latest
```

Pour kind:
```bash
kind load docker-image bibliotec-web:latest
```

Pour un registry:
```bash
docker tag bibliotec-web:latest your-registry/bibliotec-web:latest
docker push your-registry/bibliotec-web:latest
```

## Vérification du déploiement

### État des pods

```bash
kubectl get pods -n bibliotec
kubectl get deployments -n bibliotec
```

### Logs

```bash
# Django
kubectl logs -f deployment/bibliotec-web -n bibliotec

# PostgreSQL
kubectl logs -f deployment/postgres -n bibliotec

# Nginx
kubectl logs -f deployment/nginx -n bibliotec
```

### Services

```bash
kubectl get svc -n bibliotec
kubectl get ingress -n bibliotec
```

## Accès à l'application

### Avec port-forward

```bash
kubectl port-forward -n bibliotec svc/nginx-service 8080:80
```

Accès: http://localhost:8080

### Avec minikube

```bash
minikube service nginx-service -n bibliotec
```

### Avec Ingress

Si vous avez configuré un ingress controller:
```bash
kubectl get ingress -n bibliotec
```

Accès: http://bibliotec.uadb.edu.sn

## Configuration

### Modifier les secrets

```bash
kubectl edit secret bibliotec-secrets -n bibliotec
```

Ou créez un fichier `secrets.yaml` avec vos valeurs et appliquez:
```bash
kubectl apply -f secrets.yaml
```

### Modifier les ConfigMaps

```bash
kubectl edit configmap bibliotec-config -n bibliotec
```

Redémarrez les pods pour appliquer:
```bash
kubectl rollout restart deployment/bibliotec-web -n bibliotec
```

## Scaling

### Manuel

```bash
# Scaler Django
kubectl scale deployment/bibliotec-web --replicas=5 -n bibliotec

# Scaler Nginx
kubectl scale deployment/nginx --replicas=3 -n bibliotec
```

### Autoscaling (HPA)

L'HPA est déjà configuré pour Django (2-10 replicas):
```bash
kubectl get hpa -n bibliotec
```

## Persistence

### PersistentVolumeClaims

```bash
# Voir les PVC
kubectl get pvc -n bibliotec

# Détails d'un PVC
kubectl describe pvc postgres-pvc -n bibliotec
```

### Backup PostgreSQL

```bash
# Créer un backup
kubectl exec -n bibliotec deployment/postgres -- \
  pg_dump -U bibliotec_user bibliotec_db > backup.sql

# Restaurer un backup
kubectl exec -i -n bibliotec deployment/postgres -- \
  psql -U bibliotec_user bibliotec_db < backup.sql
```

## Mises à jour

### Rolling update

```bash
# 1. Build nouvelle image
docker build -t bibliotec-web:v2 ..

# 2. Charger dans le cluster
minikube image load bibliotec-web:v2

# 3. Mettre à jour le deployment
kubectl set image deployment/bibliotec-web \
  web=bibliotec-web:v2 -n bibliotec

# 4. Surveiller le rollout
kubectl rollout status deployment/bibliotec-web -n bibliotec
```

### Rollback

```bash
# Voir l'historique
kubectl rollout history deployment/bibliotec-web -n bibliotec

# Rollback
kubectl rollout undo deployment/bibliotec-web -n bibliotec

# Rollback vers une version spécifique
kubectl rollout undo deployment/bibliotec-web --to-revision=2 -n bibliotec
```

## Monitoring

### État général

```bash
kubectl get all -n bibliotec
```

### Utilisation des ressources

```bash
kubectl top pods -n bibliotec
kubectl top nodes
```

### Events

```bash
kubectl get events -n bibliotec --sort-by='.lastTimestamp'
```

### Describe

```bash
kubectl describe deployment/bibliotec-web -n bibliotec
kubectl describe pod <pod-name> -n bibliotec
```

## Troubleshooting

### Pods ne démarrent pas

```bash
kubectl describe pod <pod-name> -n bibliotec
kubectl logs <pod-name> -n bibliotec
```

### Problème de base de données

```bash
# Vérifier PostgreSQL
kubectl logs deployment/postgres -n bibliotec

# Redémarrer PostgreSQL
kubectl rollout restart deployment/postgres -n bibliotec
```

### Problème de connexion

```bash
# Tester la connectivité
kubectl exec -it deployment/bibliotec-web -n bibliotec -- \
  curl http://postgres-service:5432
```

### Relancer les migrations

```bash
kubectl delete job django-migrations -n bibliotec
kubectl apply -f migration-job.yaml
```

## Nettoyage

### Supprimer l'application

```bash
kubectl delete namespace bibliotec
```

### Supprimer sans les volumes

```bash
kubectl delete -f django-deployment.yaml
kubectl delete -f postgres-deployment.yaml
kubectl delete -f nginx-deployment.yaml
kubectl delete -f django-service.yaml
kubectl delete -f postgres-service.yaml
kubectl delete -f nginx-service.yaml
```

## Production

### Sécurité

1. Modifier les secrets:
```bash
kubectl create secret generic bibliotec-secrets \
  --from-literal=DJANGO_SECRET_KEY="votre-cle-tres-secrete" \
  --from-literal=POSTGRES_PASSWORD="password-tres-fort" \
  -n bibliotec
```

2. Configurer HTTPS avec cert-manager:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

3. Décommenter la section TLS dans `ingress.yaml`

### Monitoring

Installer Prometheus et Grafana:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

### Backup automatique

Créer un CronJob pour les backups:
```bash
kubectl apply -f backup-cronjob.yaml
```

## Ressources utiles

- kubectl: https://kubernetes.io/docs/reference/kubectl/
- Kustomize: https://kustomize.io/
- Helm: https://helm.sh/

---

BiblioTEC - Université Alioune Diop de Bambey

