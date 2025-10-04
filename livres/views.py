from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.http import HttpResponse, Http404, HttpResponseForbidden
from django.db.models import Q
from django.core.paginator import Paginator
from django.conf import settings
import os

# Assurez-vous d'importer les modèles nécessaires (y compris le modèle User si besoin)
from .models import Livre, Categorie
from users.models import User # Assurez-vous que l'importation fonctionne selon votre structure
from users.decorators import enseignant_requis, admin_requis # Importez les nouveaux decorators

# La classe Achat est remplacée par le concept de 'consultation' ou 'téléchargement'
# Si Achat est nécessaire pour le suivi des consultations, il peut être conservé.
# Pour le moment, nous allons simuler le téléchargement sécurisé.

def liste_livres(request):
    """
    Vue principale pour la recherche avancée et la liste des documents.
    Intègre les filtres par Discipline, Type de Document et Année.
    """
    categories = Categorie.objects.all()
    
    # 1. Récupération des filtres de recherche (y compris les nouveaux)
    categorie_id = request.GET.get('categorie')
    query = request.GET.get('q')
    discipline_filtre = request.GET.get('discipline') # Nouveau filtre
    type_doc_filtre = request.GET.get('type_document') # Nouveau filtre
    annee_filtre = request.GET.get('annee_publication') # Nouveau filtre
    
    livres = Livre.objects.all()
    
    # 2. Application des filtres existants et nouveaux
    if categorie_id:
        livres = livres.filter(categorie_id=categorie_id)
    
    if query:
        # Recherche combinée pour le mot-clé (Titre, Auteur, Description)
        livres = livres.filter(
            Q(titre__icontains=query) | 
            Q(auteur__icontains=query) |
            Q(description__icontains=query)
        )
    
    # Nouveaux filtres de la Recherche Avancée (CDC UADB)
    if discipline_filtre:
        livres = livres.filter(discipline=discipline_filtre)
    if type_doc_filtre:
        livres = livres.filter(type_document=type_doc_filtre)
    if annee_filtre and annee_filtre.isdigit():
        livres = livres.filter(annee_publication=int(annee_filtre))
        
    # Passage des options de filtres aux templates pour créer les listes déroulantes
    disciplines = Livre.objects.values_list('discipline', flat=True).distinct()
    types_doc = Livre.TYPE_DOC_CHOICES # Utiliser les choix définis dans models.py

    # Pagination
    paginator = Paginator(livres, 9)  # 9 livres par page
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    context = {
        'livres': page_obj,
        'categories': categories,
        'page_obj': page_obj,
        'is_paginated': page_obj.has_other_pages(),
        # Ajouter les données pour le formulaire de recherche avancée
        'disciplines': disciplines,
        'types_doc': types_doc,
    }
    return render(request, 'livres/liste_livres.html', context)

def detail_livre(request, livre_id):
    """
    Détail d'un document. La logique d'achat/téléchargement est gérée par la vue telecharger_document.
    """
    livre = get_object_or_404(Livre, id=livre_id)
    # L'état 'déjà_acheté' n'est plus pertinent pour une bibliothèque numérique.
    # Nous pourrions vérifier si l'utilisateur a déjà consulté, si un modèle de Consultation existe.
    
    context = {
        'livre': livre,
        # 'deja_achete': False, # Peut être supprimé ou renommé 'deja_consulte'
    }
    return render(request, 'livres/detail_livre.html', context)


# =================================================================
# NOUVELLE VUE : TÉLÉCHARGEMENT SÉCURISÉ (Remplace acheter_livre)
# =================================================================

@login_required # Doit être connecté
def telecharger_document(request, livre_id):
    """
    Permet le téléchargement sécurisé du document. Les droits sont basés sur le rôle.
    """
    livre = get_object_or_404(Livre, id=livre_id)
    
    # Obtenir le chemin absolu du fichier
    chemin_fichier = livre.fichier.path
    
    # 1. Vérification des Permissions basées sur le rôle (RBAC)
    
    # Si le document est une Thèse ou un Rapport interne, seuls les Enseignants/Admin ont accès
    if livre.type_document in ['These', 'Rapport'] and not (request.user.role in ['enseignant', 'admin_biblio'] or request.user.is_staff):
        return HttpResponseForbidden("Accès refusé. Vous n'avez pas les permissions suffisantes pour télécharger ce type de document.")
    
    # 2. Enregistrement de l'activité (pour les statistiques UADB)
    # (Nécessite un modèle Consultation/Historique. Pour l'instant, c'est une étape à compléter)
    
    # 3. Traitement du téléchargement
    if os.path.exists(chemin_fichier):
        with open(chemin_fichier, 'rb') as fh:
            response = HttpResponse(fh.read(), content_type="application/pdf") # Définir le type MIME
            response['Content-Disposition'] = 'attachment; filename=' + os.path.basename(chemin_fichier)
            return response
    
    # Si le fichier n'est pas trouvé
    return Http404("Le document n'a pas été trouvé sur le serveur.")

# @login_required
# def mes_achats(request): # Cette vue doit être renommée 'mes_consultations' ou 'historique'
#     # ... logique à adapter
#     pass