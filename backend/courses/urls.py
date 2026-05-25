from django.urls import path

from .views import CourseViewSet, SessionViewSet

# Routers are combined in the main config.urls to avoid converter conflicts

urlpatterns = [
    # Endpoints are registered via the combined router in config.urls
]
