from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from livres.models import Livre
from django.contrib.auth.models import User
from livres.models import Achat, Categorie

def accueil(request):
    if request.user.is_authenticated:
        return accueil_connecte(request)
    
    derniers_livres = Livre.objects.all().order_by('-date_publication')[:3]
    return render(request, 'main/accueil.html', {'derniers_livres': derniers_livres})

@login_required
def accueil_connecte(request):
    derniers_livres = Livre.objects.all().order_by('-date_publication')[:4]
    return render(request, 'main/accueil_connecte.html', {'derniers_livres': derniers_livres})

def manuel_utilisation(request):
    return render(request, 'main/manuel_utilisation.html')

def guide_etudiant(request):
    return render(request, 'main/guide_etudiant.html')

def guide_administrateur(request):
    return render(request, 'main/guide_administrateur.html')