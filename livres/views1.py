from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from .models import Livre, Emprunt, Achat

@login_required
def emprunter_livre(request, livre_id):
    livre = get_object_or_404(Livre, id=livre_id)
    if livre.disponible:
        Emprunt.objects.create(livre=livre, utilisateur=request.user)
        livre.disponible = False
        livre.save()
    return redirect('liste_livres')


@login_required
def rendre_livre(request, emprunt_id):
    emprunt = get_object_or_404(Emprunt, id=emprunt_id)
    emprunt.rendu = True
    emprunt.date_retour = timezone.now()
    emprunt.save()
    emprunt.livre.disponible = True
    emprunt.livre.save()
    return redirect('mes_emprunts')


@login_required
def acheter_livre(request, livre_id):
    livre = get_object_or_404(Livre, id=livre_id)
    Achat.objects.create(
        livre=livre,
        utilisateur=request.user,
        montant=livre.prix
    )
    return redirect('mes_achats')
