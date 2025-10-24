from django.shortcuts import render, redirect
from django.contrib.auth import login
from django.contrib import messages
from .forms import InscriptionForm

def inscription(request):
    if request.method == 'POST':
        form = InscriptionForm(request.POST)
        if form.is_valid():
            try:
                # Sauvegarder l'utilisateur sans le connecter automatiquement
                user = form.save(commit=False)
                user.email = form.cleaned_data.get('email')
                user.save()
                
                # Message de succès
                messages.success(
                    request, 
                    'Inscription réussie ! Vous pouvez maintenant vous connecter avec vos identifiants.'
                )
                
                # Redirection vers la page de connexion
                return redirect('login')
                
            except Exception as e:
                messages.error(request, f"Une erreur s'est produite lors de l'inscription: {str(e)}")
        else:
            # Afficher les erreurs de formulaire
            for field, errors in form.errors.items():
                for error in errors:
                    messages.error(request, f"{field}: {error}")
    else:
        form = InscriptionForm()
    
    return render(request, 'users/inscription.html', {'form': form})