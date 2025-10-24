#!/bin/bash

# Script de déploiement pour BiblioTEC
# Usage: ./deploy.sh [development|production|staging]

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
ENVIRONMENT=${1:-development}
PROJECT_NAME="BiblioTEC"
BACKUP_DIR="./backups"
LOG_FILE="./deploy.log"

# Fonctions utiles
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Banner
echo -e "${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════════════╗
║                                                        ║
║        BiblioTEC - Deployment Script                  ║
║        Université Alioune Diop de Bambey              ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Vérifier les prérequis
check_requirements() {
    log "🔍 Vérification des prérequis..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker n'est pas installé. Installez-le depuis https://docker.com"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose n'est pas installé."
    fi
    
    log "✅ Tous les prérequis sont satisfaits"
}

# Créer un backup
create_backup() {
    log "💾 Création d'un backup de la base de données..."
    
    mkdir -p "$BACKUP_DIR"
    
    if docker-compose ps | grep -q "Up"; then
        BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"
        docker-compose exec -T db pg_dump -U bibliotec_user bibliotec_db > "$BACKUP_FILE" 2>/dev/null || \
            warning "Impossible de créer un backup (la base de données n'existe peut-être pas encore)"
        
        if [ -f "$BACKUP_FILE" ]; then
            log "✅ Backup créé: $BACKUP_FILE"
        fi
    else
        warning "Les conteneurs ne sont pas en cours d'exécution, pas de backup créé"
    fi
}

# Charger les variables d'environnement
load_environment() {
    log "📋 Chargement de l'environnement: $ENVIRONMENT"
    
    case $ENVIRONMENT in
        production)
            ENV_FILE=".env.production"
            COMPOSE_FILE="docker-compose.yml"
            ;;
        staging)
            ENV_FILE=".env.staging"
            COMPOSE_FILE="docker-compose.yml"
            ;;
        development)
            ENV_FILE=".env"
            COMPOSE_FILE="docker-compose.yml"
            ;;
        *)
            error "Environnement invalide: $ENVIRONMENT. Utilisez: development, staging, ou production"
            ;;
    esac
    
    if [ ! -f "$ENV_FILE" ]; then
        warning "Le fichier $ENV_FILE n'existe pas. Création depuis .env.example..."
        if [ -f ".env.example" ]; then
            cp .env.example "$ENV_FILE"
            warning "⚠️  N'oubliez pas de modifier $ENV_FILE avec vos valeurs"
        else
            error "Le fichier .env.example n'existe pas"
        fi
    fi
    
    export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
}

# Build des images Docker
build_images() {
    log "🔨 Build des images Docker..."
    
    docker-compose -f "$COMPOSE_FILE" build --no-cache
    
    log "✅ Images buildées avec succès"
}

# Arrêter les conteneurs existants
stop_containers() {
    log "⏹️  Arrêt des conteneurs existants..."
    
    docker-compose -f "$COMPOSE_FILE" down
    
    log "✅ Conteneurs arrêtés"
}

# Démarrer les conteneurs
start_containers() {
    log "🚀 Démarrage des conteneurs..."
    
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Attendre que les conteneurs soient prêts
    log "⏳ Attente du démarrage complet..."
    sleep 10
    
    log "✅ Conteneurs démarrés"
}

# Effectuer les migrations
run_migrations() {
    log "📊 Exécution des migrations de base de données..."
    
    docker-compose exec -T web python manage.py migrate --noinput
    
    log "✅ Migrations effectuées"
}

# Collecter les fichiers statiques
collect_static() {
    log "📦 Collection des fichiers statiques..."
    
    docker-compose exec -T web python manage.py collectstatic --noinput
    
    log "✅ Fichiers statiques collectés"
}

# Créer un superuser par défaut (seulement en développement)
create_superuser() {
    if [ "$ENVIRONMENT" = "development" ]; then
        log "👤 Création du superuser par défaut..."
        
        docker-compose exec -T web python manage.py shell <<EOF || warning "Le superuser existe déjà"
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@uadb.edu.sn', 'admin123')
    print('Superuser créé: admin/admin123')
else:
    print('Superuser existe déjà')
EOF
        
        log "✅ Superuser vérifié"
    fi
}

# Vérifier la santé de l'application
health_check() {
    log "🏥 Vérification de la santé de l'application..."
    
    # Attendre que l'application soit prête
    RETRIES=30
    RETRY_COUNT=0
    
    while [ $RETRY_COUNT -lt $RETRIES ]; do
        if curl -f http://localhost:8000/ > /dev/null 2>&1; then
            log "✅ Application en bonne santé"
            return 0
        fi
        
        RETRY_COUNT=$((RETRY_COUNT + 1))
        info "Tentative $RETRY_COUNT/$RETRIES..."
        sleep 2
    done
    
    error "❌ L'application ne répond pas après $RETRIES tentatives"
}

# Afficher les informations de déploiement
show_info() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Déploiement terminé avec succès!            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}📋 Informations:${NC}"
    echo -e "  - Environnement: ${YELLOW}$ENVIRONMENT${NC}"
    echo -e "  - URL: ${GREEN}http://localhost:8000${NC}"
    echo -e "  - Admin: ${GREEN}http://localhost:8000/admin${NC}"
    
    if [ "$ENVIRONMENT" = "development" ]; then
        echo ""
        echo -e "${YELLOW}🔐 Identifiants par défaut:${NC}"
        echo -e "  - Username: ${GREEN}admin${NC}"
        echo -e "  - Password: ${GREEN}admin123${NC}"
        echo ""
        echo -e "${RED}⚠️  Changez le mot de passe en production!${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📊 Commandes utiles:${NC}"
    echo -e "  - Voir les logs: ${GREEN}docker-compose logs -f${NC}"
    echo -e "  - Arrêter: ${GREEN}docker-compose down${NC}"
    echo -e "  - Redémarrer: ${GREEN}docker-compose restart${NC}"
    echo -e "  - Shell Django: ${GREEN}docker-compose exec web python manage.py shell${NC}"
    echo ""
}

# Nettoyage en cas d'erreur
cleanup_on_error() {
    error "❌ Le déploiement a échoué"
    warning "Consultez les logs: $LOG_FILE"
    warning "Consultez les logs Docker: docker-compose logs"
    exit 1
}

# Trap pour capturer les erreurs
trap cleanup_on_error ERR

# Fonction principale
main() {
    log "🚀 Démarrage du déploiement de $PROJECT_NAME"
    log "Environnement: $ENVIRONMENT"
    
    check_requirements
    load_environment
    create_backup
    stop_containers
    build_images
    start_containers
    run_migrations
    create_superuser
    health_check
    show_info
    
    log "✅ Déploiement terminé avec succès!"
}

# Exécution
main

