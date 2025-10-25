BiblioTEC - Bibliothèque Numérique UADB
Plateforme de bibliothèque numérique pour l'Université Alioune Diop de Bambey.

À propos
BiblioTEC est une application Django permettant la gestion et la consultation de documents académiques (livres, thèses, articles, rapports) avec un système de contrôle d'accès basé sur les rôles.

Fonctionnalités principales
Recherche avancée avec filtres multiples
Gestion des documents (CRUD)
Système de rôles (Étudiant, Enseignant, Administrateur)
Téléchargement sécurisé selon les permissions
Suivi des consultations et statistiques
Interface d'administration complète
Stack technique
Backend: Django 5.2.6, Python 3.12
Base de données: PostgreSQL 16 / SQLite3 (dev)
Frontend: Bootstrap 5, HTML5, CSS3
Serveur: Gunicorn, Nginx
Conteneurisation: Docker, Docker Compose
Options de déploiement
BiblioTEC peut être déployé avec Docker ou Kubernetes.

Installation rapide
Option 1: Docker (Recommandé pour développement)

# Configuration

cp env.example .env

# Démarrage

./deploy.sh development

# ou

make dev

# ou

docker-compose up -d --build
Accès: http://localhost:8000
Admin: http://localhost:8000/admin (admin/admin123)

Option 2: Kubernetes (Production)
cd k8s

# Build et déploiement

make build
make load-minikube # ou make load-kind
./deploy.sh

# Accès

make port-forward
Accès: http://localhost:8080
Documentation: Voir k8s/README.md

Installation locale

# Environnement virtuel

python -m venv env
source env/bin/activate # Linux/Mac

# env\Scripts\activate # Windows

# Installation

pip install -r requirements.txt

# Configuration

cp env.example .env

# Base de données

python manage.py migrate
python manage.py createsuperuser
python manage.py collectstatic

# Démarrage

python manage.py runserver
Structure du projet
BiblioTEC-main/
├── bibliotheque/ Configuration Django
├── main/ Pages d'accueil
├── users/ Gestion utilisateurs
├── livres/ Gestion documents
├── admin/ Interface admin
├── templates/ Templates HTML
├── nginx/ Configuration Nginx
└── docker/ Configuration Docker
Commandes utiles
Docker
make help # Afficher toutes les commandes
make up # Démarrer les conteneurs
make down # Arrêter les conteneurs
make logs # Voir les logs
make shell # Shell Django
make migrate # Migrations
make test # Tests
make backup # Backup base de données
Django

# Via Docker

docker-compose exec web python manage.py [commande]

# Commandes courantes

python manage.py migrate
python manage.py createsuperuser
python manage.py collectstatic
python manage.py test
Configuration
Variables d'environnement
Copiez env.example en .env et modifiez:

DEBUG=False
SECRET_KEY=votre-cle-secrete
ALLOWED_HOSTS=localhost,votre-domaine.com
DATABASE_URL=postgresql://user:pass@db:5432/bibliotec_db
Configuration production

# Avec le script

./deploy.sh production

# Ou avec Docker Compose

docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
Système de rôles
Rôle Permissions
Étudiant Documents publics
Enseignant/Chercheur Accès étendu (thèses, rapports)
Administrateur Gestion complète
Déploiement
Checklist production
Changer SECRET_KEY
DEBUG=False
Configurer ALLOWED_HOSTS
Mots de passe forts
Activer HTTPS/SSL
Configurer backups automatiques
SSL/HTTPS
Placer les certificats dans nginx/ssl/
Décommenter la configuration HTTPS dans nginx/conf.d/bibliotec.conf
Redémarrer: docker-compose restart nginx
Documentation
DOCKER_README.md: Guide Docker complet
Makefile: make help pour toutes les commandes
deploy.sh: Script de déploiement automatisé
Backup et restauration

# Backup

make backup

# ou

docker-compose exec db pg_dump -U bibliotec_user bibliotec_db > backup.sql

# Restore

make restore FILE=backup.sql

# ou

docker-compose exec -T db psql -U bibliotec_user bibliotec_db < backup.sql
Dépannage
L'application ne démarre pas
docker-compose logs web
docker-compose build --no-cache
docker-compose up -d
Erreur base de données
docker-compose restart db
docker-compose exec web python manage.py migrate
Permissions
sudo chown -R $USER:$USER .
chmod +x deploy.sh
Tests
make test

# ou

docker-compose exec web python manage.py test
Contribution
Fork le projet
Créer une branche (git checkout -b feature/nouvelle-fonctionnalite)
Commit (git commit -m 'Ajout: nouvelle fonctionnalité')
Push (git push origin feature/nouvelle-fonctionnalite)
Pull Request
Licence
MIT License

Contact
Email: biblio-tec@uadb.edu.sn
Téléphone: +221 33 123 45 67
Adresse: BP 30, Bambey, Sénégal
Université Alioune Diop de Bambey - 2025
