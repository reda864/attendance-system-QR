from django.urls import path

from .views import (
    ExportAttendanceView,
    SessionAttendanceListView,
    ValidateAttendanceView,
)

urlpatterns = [
    path("validate/", ValidateAttendanceView.as_view(), name="attendance-validate"),
    path(
        "session/<int:session_id>/",
        SessionAttendanceListView.as_view(),
        name="session-attendance-list",
    ),
    path(
        "session/<int:session_id>/export/",
        ExportAttendanceView.as_view(),
        name="attendance-export",
    ),
]
