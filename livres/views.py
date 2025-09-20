from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import Livre, Categorie, Achat
from django.db.models import Q
from django.core.paginator import Paginator

def liste_livres(request):
    categories = Categorie.objects.all()
    categorie_id = request.GET.get('categorie')
    query = request.GET.get('q')
    
    livres = Livre.objects.all()
    
    if categorie_id:
        livres = livres.filter(categorie_id=categorie_id)
    
    if query:
        livres = livres.filter(
            Q(titre__icontains=query) | 
            Q(auteur__icontains=query) |
            Q(description__icontains=query)
        )
    
    # Pagination
    paginator = Paginator(livres, 9)  # 9 livres par page
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    context = {
        'livres': page_obj,
        'categories': categories,
        'page_obj': page_obj,
        'is_paginated': page_obj.has_other_pages()
    }
    return render(request, 'livres/liste_livres.html', context)

def detail_livre(request, livre_id):
    livre = get_object_or_404(Livre, id=livre_id)
    deja_achete = False
    
    if request.user.is_authenticated:
        deja_achete = Achat.objects.filter(utilisateur=request.user, livre=livre).exists()
    
    context = {
        'livre': livre,
        'deja_achete': deja_achete,
    }
    return render(request, 'livres/detail_livre.html', context)

@login_required
def acheter_livre(request, livre_id):
    livre = get_object_or_404(Livre, id=livre_id)
    
    # Vérifier si l'utilisateur a déjà acheté ce livre
    if Achat.objects.filter(utilisateur=request.user, livre=livre).exists():
        return render(request, 'livres/deja_achete.html', {'livre': livre})
    
    # Simuler l'achat (dans un vrai projet, intégrer un système de paiement)
    achat = Achat(utilisateur=request.user, livre=livre, prix_paye=livre.prix)
    achat.save()
    
    return render(request, 'livres/confirmation_achat.html', {'livre': livre})

@login_required
def mes_achats(request):
    achats = Achat.objects.filter(utilisateur=request.user)
    return render(request, 'livres/mes_achats.html', {'achats': achats})