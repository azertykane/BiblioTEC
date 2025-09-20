from django import forms
from django.contrib.auth.models import User
from django.contrib.auth.forms import UserCreationForm
from django.core.exceptions import ValidationError

class InscriptionForm(UserCreationForm):
    email = forms.EmailField(
        required=True, 
        label="Adresse email",
        widget=forms.EmailInput(attrs={
            'class': 'form-control', 
            'placeholder': 'Votre adresse email'
        })
    )
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password1', 'password2']
    
    def clean_email(self):
        email = self.cleaned_data.get('email')
        if User.objects.filter(email=email).exists():
            raise ValidationError("Un utilisateur avec cette adresse email existe déjà.")
        return email
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # Personnalisation des champs
        self.fields['username'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': "Nom d'utilisateur"
        })
        self.fields['password1'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Mot de passe'
        })
        self.fields['password2'].widget.attrs.update({
            'class': 'form-control', 
            'placeholder': 'Confirmation du mot de passe'
        })
        
        # Messages d'aide
        self.fields['username'].help_text = "Requis. 150 caractères maximum. Lettres, chiffres et @/./+/-/_ uniquement."