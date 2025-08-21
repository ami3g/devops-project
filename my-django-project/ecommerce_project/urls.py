from django.contrib import admin
from django.urls import path, include # Make sure include is here

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('store.urls')), # This line points to your app's URLs
]