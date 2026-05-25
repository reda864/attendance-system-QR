from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import LoginView, MeView, StudentViewSet, UserViewSet

# Routers are combined in the main config.urls to avoid converter conflicts

urlpatterns = [
    # Auth endpoints
    path("login/", LoginView.as_view(), name="login"),
    path("refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("me/", MeView.as_view(), name="me"),
]
