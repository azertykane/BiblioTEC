from django.urls import path
from . import views

urlpatterns = [
    path('livre/<int:livre_id>/emprunter/', views.emprunter_livre, name='emprunter_livre'),
    path('emprunt/<int:emprunt_id>/rendre/', views.rendre_livre, name='rendre_livre'),
    path('livre/<int:livre_id>/acheter/', views.acheter_livre, name='acheter_livre'),
]
