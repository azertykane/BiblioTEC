from django.urls import path
from . import views

urlpatterns = [
    path("statistiques/", views.statistiques_utilisation, name="statistiques"),
]
