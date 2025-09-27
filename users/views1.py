from django.shortcuts import render
from django.db.models import Count
from .models import Livre, Emprunt, Achat

def statistiques_utilisation(request):
    total_emprunts = Emprunt.objects.count()
    total_achats = Achat.objects.count()

    # Top 5 livres les plus empruntés
    top_emprunts = (
        Emprunt.objects.values("livre__titre")
        .annotate(total=Count("id"))
        .order_by("-total")[:5]
    )

    # Top 5 livres les plus achetés
    top_achats = (
        Achat.objects.values("livre__titre")
        .annotate(total=Count("id"))
        .order_by("-total")[:5]
    )

    context = {
        "total_emprunts": total_emprunts,
        "total_achats": total_achats,
        "top_emprunts": top_emprunts,
        "top_achats": top_achats,
    }
    return render(request, "statistiques.html", context)
