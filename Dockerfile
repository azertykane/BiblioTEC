# Dockerfile pour BiblioTEC - Bibliothèque Numérique UADB
# Multi-stage build pour optimiser la taille de l'image

# Stage 1: Builder
FROM python:3.12-slim as builder

# Définir les variables d'environnement
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Installer les dépendances système nécessaires pour la compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    build-essential \
    libpq-dev \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Créer et définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY requirements.txt .

# Créer un environnement virtuel et installer les dépendances
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim

# Définir les variables d'environnement
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    DJANGO_SETTINGS_MODULE=bibliotheque.settings

# Installer uniquement les dépendances runtime nécessaires
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    libjpeg62-turbo \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Créer un utilisateur non-root pour la sécurité
RUN groupadd -r django && useradd -r -g django django

# Créer les répertoires nécessaires
RUN mkdir -p /app /app/staticfiles /app/media /app/couvertures /app/livres

# Définir le répertoire de travail
WORKDIR /app

# Copier l'environnement virtuel depuis le builder
COPY --from=builder /opt/venv /opt/venv

# Copier le code de l'application
COPY --chown=django:django . .

# Créer le répertoire pour la base de données SQLite
RUN mkdir -p /app/data && chown -R django:django /app/data

# Donner les permissions appropriées
RUN chown -R django:django /app && \
    chmod -R 755 /app

# Collecter les fichiers statiques
RUN python manage.py collectstatic --noinput --clear || true

# Créer un script d'entrée pour gérer les migrations et le démarrage
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Waiting for database to be ready..."\n\
sleep 2\n\
\n\
echo "Running database migrations..."\n\
python manage.py migrate --noinput\n\
\n\
echo "Creating superuser if it does not exist..."\n\
python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username=\"admin\").exists() or User.objects.create_superuser(\"admin\", \"admin@uadb.edu.sn\", \"admin123\")"\n\
\n\
echo "Starting server..."\n\
exec "$@"' > /app/docker-entrypoint.sh && \
    chmod +x /app/docker-entrypoint.sh

# Changer vers l'utilisateur non-root
USER django

# Exposer le port 8000
EXPOSE 8000

# Définir le point d'entrée
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Commande par défaut pour démarrer le serveur
# Pour la production, utiliser gunicorn au lieu de runserver
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# Pour utiliser Gunicorn en production (décommentez et installez gunicorn dans requirements.txt):
# CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "2", "--timeout", "60", "--access-logfile", "-", "--error-logfile", "-", "bibliotheque.wsgi:application"]

# Healthcheck pour vérifier que l'application fonctionne
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

