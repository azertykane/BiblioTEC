# Makefile pour BiblioTEC - Simplifie les commandes Docker et Django
.PHONY: help build up down restart logs shell migrate collectstatic createsuperuser test clean backup restore

# Variables
DOCKER_COMPOSE = docker-compose
MANAGE_PY = python manage.py
WEB_SERVICE = web
DB_SERVICE = db

# Couleurs pour les messages
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Affiche cette aide
	@echo "$(GREEN)╔════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║         Commandes Make pour BiblioTEC                 ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# ============================================================================
# COMMANDES DOCKER
# ============================================================================

build: ## Builder les images Docker
	@echo "$(GREEN)🔨 Building Docker images...$(NC)"
	$(DOCKER_COMPOSE) build --no-cache

up: ## Démarrer les conteneurs
	@echo "$(GREEN)🚀 Starting containers...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✅ Application disponible sur http://localhost:8000$(NC)"

down: ## Arrêter les conteneurs
	@echo "$(YELLOW)⏹️  Stopping containers...$(NC)"
	$(DOCKER_COMPOSE) down

restart: ## Redémarrer les conteneurs
	@echo "$(YELLOW)🔄 Restarting containers...$(NC)"
	$(DOCKER_COMPOSE) restart

logs: ## Voir les logs en temps réel
	$(DOCKER_COMPOSE) logs -f $(WEB_SERVICE)

logs-all: ## Voir tous les logs
	$(DOCKER_COMPOSE) logs -f

ps: ## Voir l'état des conteneurs
	$(DOCKER_COMPOSE) ps

# ============================================================================
# COMMANDES DJANGO
# ============================================================================

shell: ## Ouvrir un shell Django
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) shell

bash: ## Ouvrir un shell bash dans le conteneur web
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) bash

migrate: ## Effectuer les migrations
	@echo "$(GREEN)📊 Running database migrations...$(NC)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) migrate

makemigrations: ## Créer de nouvelles migrations
	@echo "$(GREEN)📝 Creating migrations...$(NC)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) makemigrations

collectstatic: ## Collecter les fichiers statiques
	@echo "$(GREEN)📦 Collecting static files...$(NC)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) collectstatic --noinput

createsuperuser: ## Créer un superuser
	@echo "$(GREEN)👤 Creating superuser...$(NC)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) createsuperuser

test: ## Lancer les tests
	@echo "$(GREEN)🧪 Running tests...$(NC)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) test

loaddata: ## Charger des données de test
	@echo "$(GREEN)📥 Loading test data...$(NC)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) loaddata fixtures/initial_data.json

dumpdata: ## Exporter les données
	@echo "$(GREEN)📤 Dumping data...$(NC)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) dumpdata --indent 2 > fixtures/data_backup.json

# ============================================================================
# COMMANDES DE BASE DE DONNÉES
# ============================================================================

dbshell: ## Ouvrir un shell PostgreSQL
	$(DOCKER_COMPOSE) exec $(DB_SERVICE) psql -U bibliotec_user -d bibliotec_db

backup: ## Sauvegarder la base de données
	@echo "$(GREEN)💾 Creating database backup...$(NC)"
	@mkdir -p backups
	$(DOCKER_COMPOSE) exec $(DB_SERVICE) pg_dump -U bibliotec_user bibliotec_db > backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✅ Backup créé dans backups/$(NC)"

restore: ## Restaurer la base de données (usage: make restore FILE=backups/backup.sql)
	@echo "$(YELLOW)⚠️  Restoring database from $(FILE)...$(NC)"
	$(DOCKER_COMPOSE) exec -T $(DB_SERVICE) psql -U bibliotec_user bibliotec_db < $(FILE)
	@echo "$(GREEN)✅ Database restored$(NC)"

reset-db: ## Réinitialiser complètement la base de données (⚠️ DANGER)
	@echo "$(RED)⚠️  WARNING: This will delete ALL data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "\n$(YELLOW)Resetting database...$(NC)"; \
		$(DOCKER_COMPOSE) down -v; \
		$(DOCKER_COMPOSE) up -d $(DB_SERVICE); \
		sleep 5; \
		$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) migrate; \
		echo "$(GREEN)✅ Database reset complete$(NC)"; \
	fi

# ============================================================================
# COMMANDES DE DÉVELOPPEMENT
# ============================================================================

dev: build up migrate collectstatic ## Setup complet pour développement
	@echo "$(GREEN)✅ Development environment ready!$(NC)"
	@echo "$(GREEN)👉 Créez un superuser avec: make createsuperuser$(NC)"

prod: ## Démarrer en mode production
	@echo "$(GREEN)🚀 Starting in production mode...$(NC)"
	COMPOSE_FILE=docker-compose.yml COMPOSE_FILE=docker-compose.prod.yml $(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✅ Production environment running$(NC)"

install-deps: ## Installer les dépendances Python localement
	pip install -r requirements.txt

lint: ## Vérifier le code avec flake8
	@echo "$(GREEN)🔍 Linting code...$(NC)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) flake8 .

format: ## Formater le code avec black
	@echo "$(GREEN)✨ Formatting code...$(NC)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) black .

check: ## Vérifier le projet Django
	@echo "$(GREEN)🔍 Checking Django project...$(NC)"
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) check

# ============================================================================
# COMMANDES DE NETTOYAGE
# ============================================================================

clean: ## Nettoyer les fichiers temporaires
	@echo "$(YELLOW)🧹 Cleaning temporary files...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*~" -delete
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

clean-all: down clean ## Arrêter les conteneurs et nettoyer
	@echo "$(YELLOW)🧹 Deep cleaning...$(NC)"
	$(DOCKER_COMPOSE) down -v --remove-orphans
	docker system prune -f
	@echo "$(GREEN)✅ Deep cleanup complete$(NC)"

# ============================================================================
# COMMANDES UTILES
# ============================================================================

status: ## Afficher le statut complet
	@echo "$(GREEN)═══════════════════════════════════════$(NC)"
	@echo "$(GREEN)      BiblioTEC Status Report         $(NC)"
	@echo "$(GREEN)═══════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)📦 Containers:$(NC)"
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "$(YELLOW)💾 Disk Usage:$(NC)"
	@docker system df
	@echo ""

health: ## Vérifier la santé de l'application
	@echo "$(GREEN)🏥 Health Check$(NC)"
	@curl -f http://localhost:8000/ > /dev/null 2>&1 && echo "$(GREEN)✅ Application is healthy$(NC)" || echo "$(RED)❌ Application is down$(NC)"

urls: ## Afficher toutes les URLs Django
	$(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) show_urls 2>/dev/null || $(DOCKER_COMPOSE) exec $(WEB_SERVICE) $(MANAGE_PY) showurls 2>/dev/null || echo "$(YELLOW)Install django-extensions for this feature$(NC)"

stats: ## Afficher les statistiques des conteneurs
	docker stats --no-stream

update: ## Mettre à jour l'application
	@echo "$(GREEN)🔄 Updating application...$(NC)"
	git pull origin main
	$(MAKE) build
	$(MAKE) up
	$(MAKE) migrate
	$(MAKE) collectstatic
	@echo "$(GREEN)✅ Update complete$(NC)"

# ============================================================================
# COMMANDES DE DÉPLOIEMENT
# ============================================================================

deploy: ## Déployer en production (avec backup)
	@echo "$(GREEN)🚀 Deploying to production...$(NC)"
	$(MAKE) backup
	$(MAKE) down
	git pull origin main
	$(MAKE) build
	$(MAKE) up
	$(MAKE) migrate
	$(MAKE) collectstatic
	@echo "$(GREEN)✅ Deployment complete$(NC)"

rollback: ## Revenir à la version précédente
	@echo "$(YELLOW)⏮️  Rolling back...$(NC)"
	git checkout HEAD~1
	$(MAKE) build
	$(MAKE) restart
	@echo "$(GREEN)✅ Rollback complete$(NC)"

# ============================================================================
# ALIAS RAPIDES
# ============================================================================

start: up ## Alias pour 'up'
stop: down ## Alias pour 'down'
reload: restart ## Alias pour 'restart'

.DEFAULT_GOAL := help

