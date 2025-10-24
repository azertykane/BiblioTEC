# Commandes Kubernetes - BiblioTEC

## Déploiement

```bash
# Déploiement complet
cd k8s && ./deploy.sh

# Ou avec Make
make build load-minikube deploy

# Ou avec kubectl
kubectl apply -f .

# Ou avec Kustomize
kubectl apply -k .
```

## Vérification

```bash
# État général
kubectl get all -n bibliotec

# Pods
kubectl get pods -n bibliotec

# Services
kubectl get svc -n bibliotec

# PVC
kubectl get pvc -n bibliotec
```

## Logs

```bash
# Django
kubectl logs -f deployment/bibliotec-web -n bibliotec

# PostgreSQL
kubectl logs -f deployment/postgres -n bibliotec

# Nginx
kubectl logs -f deployment/nginx -n bibliotec
```

## Shell

```bash
# Shell Django
kubectl exec -it deployment/bibliotec-web -n bibliotec -- python manage.py shell

# Bash
kubectl exec -it deployment/bibliotec-web -n bibliotec -- /bin/bash

# Migrations
kubectl apply -f migration-job.yaml

# Créer superuser
kubectl exec -it deployment/bibliotec-web -n bibliotec -- \
  python manage.py createsuperuser
```

## Scaling

```bash
# Scaler manuellement
kubectl scale deployment/bibliotec-web --replicas=5 -n bibliotec

# Voir HPA
kubectl get hpa -n bibliotec
```

## Mises à jour

```bash
# Rolling update
kubectl set image deployment/bibliotec-web web=bibliotec-web:v2 -n bibliotec

# Status rollout
kubectl rollout status deployment/bibliotec-web -n bibliotec

# Rollback
kubectl rollout undo deployment/bibliotec-web -n bibliotec
```

## Accès

```bash
# Port-forward
kubectl port-forward -n bibliotec svc/nginx-service 8080:80

# Minikube
minikube service nginx-service -n bibliotec
```

## Monitoring

```bash
# Ressources
kubectl top pods -n bibliotec
kubectl top nodes

# Events
kubectl get events -n bibliotec
```

## Backup

```bash
# Backup manuel
kubectl exec deployment/postgres -n bibliotec -- \
  pg_dump -U bibliotec_user bibliotec_db > backup.sql

# Restore
kubectl exec -i deployment/postgres -n bibliotec -- \
  psql -U bibliotec_user bibliotec_db < backup.sql
```

## Nettoyage

```bash
# Supprimer tout
kubectl delete namespace bibliotec

# Supprimer les jobs
kubectl delete jobs --all -n bibliotec
```

