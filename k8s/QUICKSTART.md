# Démarrage rapide Kubernetes

## Installation en 3 étapes

### 1. Build de l'image

```bash
cd k8s
make build
```

Pour minikube:
```bash
make load-minikube
```

Pour kind:
```bash
make load-kind
```

### 2. Déploiement

```bash
./deploy.sh
```

Ou manuellement:
```bash
make apply
```

### 3. Accès

```bash
make port-forward
```

Accès: http://localhost:8080

## Commandes essentielles

```bash
make status         # État du cluster
make logs           # Logs Django
make shell          # Shell Django
make restart        # Redémarrer Django
make clean          # Tout supprimer
```

## Vérification

```bash
kubectl get pods -n bibliotec
kubectl get svc -n bibliotec
kubectl get pvc -n bibliotec
```

## Scaling

```bash
# Manuel
kubectl scale deployment/bibliotec-web --replicas=5 -n bibliotec

# Autoscaling (HPA configuré: 2-10 replicas)
kubectl get hpa -n bibliotec
```

## Monitoring

```bash
make top            # Utilisation ressources
kubectl get events -n bibliotec
```

---

Guide complet: README.md

