from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from main.views import accueil
from admin.views import admin_dashboard, admin_livres, ajouter_livre, modifier_livre, supprimer_livre
from django.contrib.auth import views as auth_views
from users.views import inscription


urlpatterns = [
    path('admin/', admin.site.urls),
    path('', accueil, name='accueil'),
    path('livres/', include('livres.urls')),
    path('utilisateurs/', include('users.urls')),
    path('utilisateurs/inscription/', inscription, name='inscription'),
    path('comptes/', include('django.contrib.auth.urls')),
    path('admin/dashboard/', admin_dashboard, name='admin_dashboard'),
    path('admin/livres/', admin_livres, name='admin_livres'),
    path('admin/livres/ajouter/', ajouter_livre, name='ajouter_livre'),
    path('admin/livres/modifier/<int:livre_id>/', modifier_livre, name='modifier_livre'),
    path('admin/livres/supprimer/<int:livre_id>/', supprimer_livre, name='supprimer_livre'),
    path('comptes/reinitialisation/', 
         auth_views.PasswordResetView.as_view(
             template_name='registration/password_reset.html',
             email_template_name='registration/password_reset_email.html',
             subject_template_name='registration/password_reset_subject.txt',
             success_url='/comptes/reinitialisation/demande-envoyee/'
         ), 
         name='password_reset'),
    
    path('comptes/reinitialisation/demande-envoyee/', 
         auth_views.PasswordResetDoneView.as_view(
             template_name='registration/password_reset_done.html'
         ), 
         name='password_reset_done'),
    
    path('comptes/reinitialisation/<uidb64>/<token>/', 
         auth_views.PasswordResetConfirmView.as_view(
             template_name='registration/password_reset_confirm.html',
             success_url='/comptes/reinitialisation/termine/'
         ), 
         name='password_reset_confirm'),
    
    path('comptes/reinitialisation/termine/', 
         auth_views.PasswordResetCompleteView.as_view(
             template_name='registration/password_reset_complete.html'
         ), 
         name='password_reset_complete'),

    path('gestion/dashboard/', admin_dashboard, name='admin_dashboard'),
    path('gestion/livres/', admin_livres, name='admin_livres'),
    path('gestion/livres/ajouter/', ajouter_livre, name='ajouter_livre'),
    path('gestion/livres/modifier/<int:livre_id>/', modifier_livre, name='modifier_livre'),
    path('gestion/livres/supprimer/<int:livre_id>/', supprimer_livre, name='supprimer_livre'),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)