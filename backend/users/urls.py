from django.urls import path

from .views import LoginView, MeView, StudentViewSet, SwitchRoleView, TokenRefreshView, UserViewSet

# Routers are combined in the main config.urls to avoid converter conflicts

urlpatterns = [
    # Auth endpoints
    path("login/", LoginView.as_view(), name="login"),
    path("refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("switch-role/", SwitchRoleView.as_view(), name="switch-role"),
    path("me/", MeView.as_view(), name="me"),
]
