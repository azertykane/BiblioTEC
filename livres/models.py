from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from django.conf import settings

class Categorie(models.Model):
    nom = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    
    def __str__(self):
        return self.nom

class Livre(models.Model):
    titre = models.CharField(max_length=200)
    auteur = models.CharField(max_length=100)
    description = models.TextField()
    prix = models.DecimalField(max_digits=6, decimal_places=2)
    categorie = models.ForeignKey(Categorie, on_delete=models.SET_NULL, null=True)
    image_couverture = models.ImageField(upload_to='couvertures/', default='couvertures/default.jpg')
    fichier = models.FileField(upload_to='livres/', blank=True, null=True)
    est_gratuit = models.BooleanField(default=False)
    date_publication = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        return self.titre

class Achat(models.Model):
    utilisateur = models.ForeignKey(User, on_delete=models.CASCADE)
    livre = models.ForeignKey(Livre, on_delete=models.CASCADE)
    date_achat = models.DateTimeField(auto_now_add=True)
    prix_paye = models.DecimalField(max_digits=6, decimal_places=2)
    
    def __str__(self):
        return f"{self.utilisateur.username} - {self.livre.titre}"

class Consultation(models.Model):
    """Enregistre chaque téléchargement ou consultation d'un document."""
    
    # L'utilisateur qui a consulté le document
    utilisateur = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='consultations_faites'
    )
    
    # Le livre ou document consulté
    livre = models.ForeignKey(
        'Livre', # Utilisation d'une chaîne si Livre n'est pas encore défini
        on_delete=models.CASCADE
    )
    
    # Date et heure de la consultation
    date_consultation = models.DateTimeField(auto_now_add=True)
    
    # Type d'action (utile pour le suivi)
    TYPE_ACTION_CHOICES = [
        ('DL', 'Téléchargement'),
        ('VS', 'Visualisation'),
    ]
    type_action = models.CharField(max_length=2, choices=TYPE_ACTION_CHOICES, default='DL')

    class Meta:
        ordering = ['-date_consultation']
        verbose_name = "Historique de consultation"
        
    def __str__(self):
        return f"{self.utilisateur.username} a consulté {self.livre.titre} le {self.date_consultation.strftime('%Y-%m-%d')}"