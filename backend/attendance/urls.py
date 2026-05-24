from django.urls import path

from .views import (
    AllAttendanceListView,
    ExportAttendanceView,
    SessionAttendanceListView,
    ValidateAttendanceView,
)

urlpatterns = [
    path("validate/", ValidateAttendanceView.as_view(), name="attendance-validate"),
    path("", AllAttendanceListView.as_view(), name="attendance-list"),
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
