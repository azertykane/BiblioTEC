# users/admin.py
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User # Assurez-vous d'importer le modèle User correct de votre app

# Cette classe personnalise ce qui apparaît dans l'interface /admin
class CustomUserAdmin(UserAdmin):
    # 1. Ajouter 'role' à la liste des champs affichés sur la page de la liste d'utilisateurs
    list_display = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'role')

    # 2. Ajouter le champ 'role' au formulaire d'édition des utilisateurs
    fieldsets = UserAdmin.fieldsets + (
        ('Rôles UADB', {'fields': ('role',)}),
    )

# Il est crucial de dé-enregistrer l'ancien modèle User s'il est déjà enregistré
try:
    admin.site.unregister(User)
except admin.sites.NotRegistered:
    pass

# Enregistrer le modèle avec la classe Admin personnalisée
admin.site.register(User, CustomUserAdmin)