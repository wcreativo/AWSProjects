from django.contrib import admin
from django.urls import path
from ninja import NinjaAPI
from api.views import api

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', api.urls),
]
