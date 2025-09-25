from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

class Livre(models.Model):
    titre = models.CharField(max_length=200)
    auteur = models.CharField(max_length=200)
    disponible = models.BooleanField(default=True)
    prix = models.DecimalField(max_digits=8, decimal_places=2, default=0.0)

    def __str__(self):
        return self.titre


class Emprunt(models.Model):
    livre = models.ForeignKey(Livre, on_delete=models.CASCADE)
    utilisateur = models.ForeignKey(User, on_delete=models.CASCADE)
    date_emprunt = models.DateTimeField(default=timezone.now)
    date_retour = models.DateTimeField(null=True, blank=True)
    rendu = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.utilisateur.username} a emprunté {self.livre.titre}"


class Achat(models.Model):
    livre = models.ForeignKey(Livre, on_delete=models.CASCADE)
    utilisateur = models.ForeignKey(User, on_delete=models.CASCADE)
    date_achat = models.DateTimeField(default=timezone.now)
    montant = models.DecimalField(max_digits=8, decimal_places=2)

    def __str__(self):
        return f"{self.utilisateur.username} a acheté {self.livre.titre}"
