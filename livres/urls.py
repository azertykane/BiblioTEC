# livres/urls.py
from django.urls import path
from . import views

urlpatterns = [
    # Chemin principal : Gère la liste et la Recherche Avancée
    path('', views.liste_livres, name='liste_livres'), 
    
    # Détail d'un document
    path('<int:livre_id>/', views.detail_livre, name='detail_livre'),
    
    # TÉLÉCHARGEMENT SÉCURISÉ (Remplace l'achat)
    # C'est ici que la vérification des rôles (RBAC) est déclenchée
    path('<int:livre_id>/telecharger/', views.telecharger_document, name='telecharger_document'),
    
    # HISTORIQUE DE CONSULTATION (Remplace 'mes_achats')
    path('historique/', views.mes_achats, name='historique_consultations'), 
    # NOTE: La fonction mes_achats dans views.py devra être renommée pour plus de clarté.
]