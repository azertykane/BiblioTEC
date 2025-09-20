from django.contrib import admin
from .models import Categorie, Livre, Achat

@admin.register(Categorie)
class CategorieAdmin(admin.ModelAdmin):
    list_display = ('nom', 'description')
    search_fields = ('nom',)

@admin.register(Livre)
class LivreAdmin(admin.ModelAdmin):
    list_display = ('titre', 'auteur', 'prix', 'categorie', 'est_gratuit', 'date_publication')
    list_filter = ('categorie', 'est_gratuit', 'date_publication')
    search_fields = ('titre', 'auteur')
    date_hierarchy = 'date_publication'

@admin.register(Achat)
class AchatAdmin(admin.ModelAdmin):
    list_display = ('utilisateur', 'livre', 'prix_paye', 'date_achat')
    list_filter = ('date_achat',)
    date_hierarchy = 'date_achat'