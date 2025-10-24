# Image de base Python
FROM python:3.10-slim

# Répertoire de travail
WORKDIR /app

# Copier les fichiers
COPY . /app

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements_docker.txt

# Exposer le port
EXPOSE 8000

# Commande de lancement avec gunicorn
CMD ["gunicorn", "bibliotheque.wsgi:application", "--bind", "0.0.0.0:8000"]
