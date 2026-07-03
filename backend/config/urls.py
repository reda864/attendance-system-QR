"""
Root URL configuration for QR Attendance System.
"""

import os

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import FileResponse, Http404, HttpResponseRedirect
from django.urls import include, path, re_path
from django.views.generic import RedirectView, TemplateView
from drf_yasg import openapi
from drf_yasg.views import get_schema_view
from rest_framework import permissions
from rest_framework.routers import DefaultRouter

from users.views import (
    ClasseViewSet,
    ModuleViewSet,
    SemesterViewSet,
    StudentViewSet,
    UserViewSet,
)
from courses.views import SessionViewSet

# ---------------------------------------------------------------------------
# Swagger / ReDoc schema view
# ---------------------------------------------------------------------------
schema_view = get_schema_view(
    openapi.Info(
        title="QR Attendance API",
        default_version="v1",
        description=(
            "Production-ready REST API for a QR Code-based student attendance system.\n\n"
            "## Roles\n"
            "- **Admin** — full access (users, classes, sessions)\n"
            "- **Teacher** — manage sessions for assigned classes, generate QR codes\n"
            "- **Student** — validate attendance via scanned QR token\n\n"
            "## Authentication\n"
            "All protected endpoints require `Authorization: Bearer <access_token>`."
        ),
        terms_of_service="https://example.com/terms/",
        contact=openapi.Contact(email="admin@qrattendance.local"),
        license=openapi.License(name="MIT License"),
    ),
    public=True,
    permission_classes=[permissions.AllowAny],
)


# ---------------------------------------------------------------------------
# Frontend page views — serve raw HTML files from templates/
# ---------------------------------------------------------------------------
def serve_template(filename):
    """Return a simple view that streams an HTML file from the templates/ folder."""

    def view(request):
        path_ = os.path.join(settings.BASE_DIR, "templates", filename)
        if not os.path.exists(path_):
            raise Http404(f"{filename} not found")
        return FileResponse(open(path_, "rb"), content_type="text/html")

    return view


def serve_js(filename):
    """Serve a JS file from the templates/ folder."""

    def view(request):
        path_ = os.path.join(settings.BASE_DIR, "templates", filename)
        if not os.path.exists(path_):
            raise Http404(f"{filename} not found")
        return FileResponse(open(path_, "rb"), content_type="application/javascript")

    return view


def serve_css(filename):
    """Serve a CSS file from the templates/ folder."""

    def view(request):
        path_ = os.path.join(settings.BASE_DIR, "templates", filename)
        if not os.path.exists(path_):
            raise Http404(f"{filename} not found")
        return FileResponse(open(path_, "rb"), content_type="text/css")

    return view


def redirect_attend_token(request, token):
    """Support /attend/TOKEN/ for basic phone QR scanners."""
    return HttpResponseRedirect(f"/attend/?token={token}")


# ---------------------------------------------------------------------------
# API v1 router
# ---------------------------------------------------------------------------
api_router = DefaultRouter()
api_router.register("users", UserViewSet, basename="user")
api_router.register("classes", ClasseViewSet, basename="classe")
api_router.register("semesters", SemesterViewSet, basename="semester")
api_router.register("modules", ModuleViewSet, basename="module")
api_router.register("students", StudentViewSet, basename="student")
api_router.register("sessions", SessionViewSet, basename="session")

api_v1_urlpatterns = [
    path("", include(api_router.urls)),
    path("auth/", include("users.urls")),
    path("attendance/", include("attendance.urls")),
]

# ---------------------------------------------------------------------------
# Root URL patterns
# ---------------------------------------------------------------------------
urlpatterns = [
    path("", RedirectView.as_view(url="/login/", permanent=False)),
    path("login/", serve_template("login.html"), name="login-page"),
    path("admin-ui/", serve_template("admin.html"), name="admin-page"),
    path("teacher/", serve_template("teacher.html"), name="teacher-page"),
    path("student/", serve_template("student.html"), name="student-page"),
    path("attend/", serve_template("attend.html"), name="attend-page"),
    re_path(
        r"^attend/(?P<token>[A-Za-z0-9_\-]+)/?$",
        redirect_attend_token,
        name="attend-token-redirect",
    ),
    path("api.js", serve_js("api.js"), name="api-js"),
    path("i18n-fr.js", serve_js("i18n-fr.js"), name="i18n-fr"),
    path("dashboard.css", serve_css("dashboard.css"), name="dashboard-css"),
    path("admin/", admin.site.urls),
    path("api/v1/", include(api_v1_urlpatterns)),
    re_path(
        r"^api/docs/swagger(?P<format>\.json|\.yaml)$",
        schema_view.without_ui(cache_timeout=0),
        name="schema-json",
    ),
    path(
        "api/docs/swagger/",
        schema_view.with_ui("swagger", cache_timeout=0),
        name="schema-swagger-ui",
    ),
    path(
        "api/docs/redoc/",
        schema_view.with_ui("redoc", cache_timeout=0),
        name="schema-redoc",
    ),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
