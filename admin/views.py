from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib import messages
from livres.models import Livre, Categorie, Achat
from django.contrib.auth.models import User
from livres.forms import LivreForm

def is_admin(user):
    return user.is_staff or user.is_superuser

@login_required
@user_passes_test(is_admin)
def admin_dashboard(request):
    total_livres = Livre.objects.count()
    total_utilisateurs = User.objects.count()
    total_achats = Achat.objects.count()
    total_categories = Categorie.objects.count()
    derniers_livres = Livre.objects.all().order_by('-date_publication')[:5]
    
    context = {
        'total_livres': total_livres,
        'total_utilisateurs': total_utilisateurs,
        'total_achats': total_achats,
        'total_categories': total_categories,
        'derniers_livres': derniers_livres,
    }
    
    return render(request, 'admin/dashboard.html', context)

@login_required
@user_passes_test(is_admin)
def admin_livres(request):
    livres = Livre.objects.all().order_by('-date_publication')
    return render(request, 'admin/gerer_livres.html', {'livres': livres})

@login_required
@user_passes_test(is_admin)
def ajouter_livre(request):
    if request.method == 'POST':
        form = LivreForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            messages.success(request, 'Livre ajouté avec succès!')
            return redirect('admin_livres')
    else:
        form = LivreForm()
    
    return render(request, 'admin/ajouter_livre.html', {'form': form})

@login_required
@user_passes_test(is_admin)
def modifier_livre(request, livre_id):
    livre = get_object_or_404(Livre, id=livre_id)
    
    if request.method == 'POST':
        form = LivreForm(request.POST, request.FILES, instance=livre)
        if form.is_valid():
            form.save()
            messages.success(request, 'Livre modifié avec succès!')
            return redirect('admin_livres')
    else:
        form = LivreForm(instance=livre)
    
    return render(request, 'admin/ajouter_livre.html', {'form': form})

@login_required
@user_passes_test(is_admin)
def supprimer_livre(request, livre_id):
    livre = get_object_or_404(Livre, id=livre_id)
    
    if request.method == 'POST':
        livre.delete()
        messages.success(request, 'Livre supprimé avec succès!')
        return redirect('admin_livres')
    
    return render(request, 'admin/supprimer_livre.html', {'livre': livre})