# users/models.py
from django.db import models
from django.contrib.auth.models import AbstractUser

# Définir des constantes pour les choix de rôles
ROLE_CHOICES = (
    ('etudiant', 'Étudiant'),
    ('enseignant', 'Enseignant/Chercheur'),
    ('admin_biblio', 'Administrateur Bibliothèque'),
)

class User(AbstractUser):
    # Ajoutez le champ 'role'
    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default='etudiant',
        verbose_name='Rôle de l\'utilisateur'
    )

    # CORRECTION DE L'ERREUR E304 : Ajouter les related_name uniques
    groups = models.ManyToManyField(
        'auth.Group',
        verbose_name=('groups'),
        blank=True,
        help_text=('The groups this user belongs to. A user will get all permissions granted to each of their groups.'),
        related_name="users_user_set", # Nom unique
        related_query_name="user",
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        verbose_name=('user permissions'),
        blank=True,
        help_text=('Specific permissions for this user.'),
        related_name="users_user_set", # Nom unique
        related_query_name="user",
    )

    pass