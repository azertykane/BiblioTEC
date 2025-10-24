# Guide Docker - BiblioTEC

Documentation pour le déploiement de BiblioTEC avec Docker.

## Prérequis

- Docker 20.10+
- Docker Compose 2.0+
- 2 GB RAM minimum
- 5 GB espace disque

## Architecture

```
Docker Network (bibliotec-network)
│
├── Nginx (Port 80/443)
│   └── Reverse Proxy & Static Files
│
├── Django Web (Port 8000)
│   └── Application BiblioTEC (Gunicorn)
│
└── PostgreSQL 16
    └── Base de données
```

## Démarrage rapide

```bash
# 1. Configuration
cp env.example .env

# 2. Démarrage
./deploy.sh development
# ou
docker-compose up -d --build

# 3. Accès
# Application: http://localhost:8000
# Admin: http://localhost:8000/admin (admin/admin123)
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| web | 8000 | Application Django |
| db | 5432 | PostgreSQL |
| nginx | 80/443 | Reverse proxy |

## Commandes Docker

### Gestion des conteneurs

```bash
docker-compose up -d              # Démarrer
docker-compose down               # Arrêter
docker-compose restart            # Redémarrer
docker-compose ps                 # État
docker-compose logs -f web        # Logs
```

### Django

```bash
# Shell Django
docker-compose exec web python manage.py shell

# Migrations
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py makemigrations

# Superuser
docker-compose exec web python manage.py createsuperuser

# Fichiers statiques
docker-compose exec web python manage.py collectstatic

# Tests
docker-compose exec web python manage.py test
```

### Base de données

```bash
# Shell PostgreSQL
docker-compose exec db psql -U bibliotec_user -d bibliotec_db

# Backup
docker-compose exec db pg_dump -U bibliotec_user bibliotec_db > backup.sql

# Restore
docker-compose exec -T db psql -U bibliotec_user bibliotec_db < backup.sql
```

## Configuration

### Variables d'environnement (.env)

```env
# Django
DEBUG=False
SECRET_KEY=votre-cle-secrete
ALLOWED_HOSTS=localhost,votre-domaine.com

# Database
POSTGRES_DB=bibliotec_db
POSTGRES_USER=bibliotec_user
POSTGRES_PASSWORD=motdepasse-fort
DATABASE_URL=postgresql://bibliotec_user:motdepasse@db:5432/bibliotec_db

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=votre-email@example.com
EMAIL_HOST_PASSWORD=votre-mot-de-passe
```

### PostgreSQL au lieu de SQLite

Modifiez `.env`:
```env
DATABASE_URL=postgresql://bibliotec_user:password@db:5432/bibliotec_db
```

Redémarrez:
```bash
docker-compose down
docker-compose up -d
docker-compose exec web python manage.py migrate
```

### SSL/HTTPS avec Nginx

1. Placer les certificats:
```bash
mkdir -p nginx/ssl
cp certificate.crt nginx/ssl/
cp private.key nginx/ssl/
```

2. Décommenter la configuration HTTPS dans `nginx/conf.d/bibliotec.conf`

3. Redémarrer:
```bash
docker-compose restart nginx
```

## Déploiement production

### Avec le script

```bash
./deploy.sh production
```

### Manuel

```bash
# 1. Configuration
cp env.example .env.production
nano .env.production

# 2. Démarrage
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 3. Migrations
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py collectstatic

# 4. Superuser
docker-compose exec web python manage.py createsuperuser
```

## Monitoring

### Logs

```bash
# Tous les services
docker-compose logs -f

# Service spécifique
docker-compose logs -f web
docker-compose logs -f db

# Dernières 100 lignes
docker-compose logs --tail=100 web
```

### Santé des conteneurs

```bash
docker-compose ps
docker stats
docker inspect bibliotec-web
```

## Maintenance

### Backups automatiques

Créer un cron job:
```bash
# Backup quotidien à 2h
0 2 * * * cd /path/to/BiblioTEC-main && make backup
```

### Mise à jour

```bash
# 1. Backup
make backup

# 2. Arrêter
docker-compose down

# 3. Mettre à jour le code
git pull origin main

# 4. Rebuilder
docker-compose build --no-cache

# 5. Redémarrer
docker-compose up -d

# 6. Migrations
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py collectstatic
```

## Dépannage

### Conteneur ne démarre pas

```bash
docker-compose logs web
docker-compose build --no-cache web
docker-compose up -d web
```

### Erreur connexion base de données

```bash
docker-compose ps db
docker-compose restart db
docker-compose logs db
```

### Problème permissions

```bash
sudo chown -R $USER:$USER .
chmod -R 755 .
chmod +x deploy.sh
```

### Port déjà utilisé

```bash
# Trouver le processus
lsof -i :8000

# Ou changer le port dans docker-compose.yml
ports:
  - "8080:8000"
```

### Réinitialisation complète

```bash
# ATTENTION: Supprime toutes les données
docker-compose down -v
docker system prune -a -f
docker-compose up -d --build
```

## Nettoyage

```bash
# Fichiers temporaires
make clean

# Images inutilisées
docker image prune

# Volumes inutilisés
docker volume prune

# Nettoyage complet
docker system prune -a
```

## Sécurité production

### Checklist

- [ ] SECRET_KEY unique et aléatoire
- [ ] DEBUG=False
- [ ] ALLOWED_HOSTS configuré
- [ ] Mots de passe forts (DB, Redis)
- [ ] HTTPS/SSL activé
- [ ] Backups automatiques
- [ ] Firewall configuré
- [ ] Monitoring en place
- [ ] Logs centralisés
- [ ] Mises à jour régulières

### Configuration firewall

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Optimisation

### Limites de ressources (production)

Voir `docker-compose.prod.yml` pour les limites CPU/RAM.

### Gunicorn

Configuration dans `Dockerfile`:
```dockerfile
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "2", "bibliotheque.wsgi:application"]
```

Nombre de workers: `(2 x CPU cores) + 1`

## Support

En cas de problème:
1. Vérifier les logs: `docker-compose logs -f`
2. Vérifier l'état: `docker-compose ps`
3. Consulter la documentation: `README.md`
4. Ouvrir une issue sur GitHub

---

Documentation complète: README.md  
Commandes utiles: `make help`
