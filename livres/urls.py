from django.urls import path
from . import views

urlpatterns = [
    path('', views.liste_livres, name='liste_livres'),
    path('<int:livre_id>/', views.detail_livre, name='detail_livre'),
    path('<int:livre_id>/acheter/', views.acheter_livre, name='acheter_livre'),
    path('mes-achats/', views.mes_achats, name='mes_achats'),
]