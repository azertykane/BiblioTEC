# users/decorators.py

from django.contrib.auth.decorators import user_passes_test
from django.shortcuts import redirect

# =================================================================
# A. FONCTIONS DE VÉRIFICATION
# =================================================================

def est_etudiant(user):
    """Vérifie si l'utilisateur a le rôle 'etudiant'."""
    return user.is_authenticated and user.role == 'etudiant'

def est_enseignant(user):
    """Vérifie si l'utilisateur a le rôle 'enseignant'."""
    return user.is_authenticated and user.role == 'enseignant'

def est_admin_biblio(user):
    """Vérifie si l'utilisateur a le rôle 'admin_biblio'."""
    # Les super-utilisateurs (staff) sont souvent considérés comme admins par défaut
    return user.is_authenticated and (user.role == 'admin_biblio' or user.is_staff)

# =================================================================
# B. DECORATORS (À UTILISER DANS LES VUES)
# =================================================================

def role_requis(role):
    """Génère un decorator qui exige un rôle spécifique ou un super-utilisateur."""
    def decorator(view_func):
        def check_role(user):
            return user.is_authenticated and (user.role == role or user.is_staff)
        
        # Rediriger vers la page d'accueil si non autorisé
        return user_passes_test(check_role, login_url='/', redirect_field_name=None)(view_func)
    return decorator

# Décorateurs spécifiques à utiliser :
enseignant_requis = role_requis('enseignant')
admin_requis = role_requis('admin_biblio') 
# Vous pouvez aussi créer une fonction plus spécifique si vous voulez autoriser les enseignants ET les admins