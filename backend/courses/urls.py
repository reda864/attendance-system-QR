from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import CourseViewSet, SessionViewSet

router = DefaultRouter()
router.register("courses", CourseViewSet, basename="course")
router.register("sessions", SessionViewSet, basename="session")

urlpatterns = [
    path("", include(router.urls)),
]
