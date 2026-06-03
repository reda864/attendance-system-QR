from django.urls import path

from .views import (
    AllAttendanceListView,
    ExportAttendanceView,
    MyAttendanceListView,
    QrSessionInfoView,
    SessionAttendanceListView,
    SessionStatsView,
    SessionSuspiciousAttemptsView,
    ValidateAppAttendanceView,
    ValidateAttendanceView,
)

urlpatterns = [
    path("validate/", ValidateAttendanceView.as_view(), name="attendance-validate"),
    path(
        "validate/app/",
        ValidateAppAttendanceView.as_view(),
        name="attendance-validate-app",
    ),
    path("qr-info/", QrSessionInfoView.as_view(), name="attendance-qr-info"),
    path("my/", MyAttendanceListView.as_view(), name="attendance-my"),
    path("", AllAttendanceListView.as_view(), name="attendance-list"),
    path(
        "session/<int:session_id>/",
        SessionAttendanceListView.as_view(),
        name="session-attendance-list",
    ),
    path(
        "session/<int:session_id>/stats/",
        SessionStatsView.as_view(),
        name="session-attendance-stats",
    ),
    path(
        "session/<int:session_id>/suspicious/",
        SessionSuspiciousAttemptsView.as_view(),
        name="session-suspicious-attempts",
    ),
    path(
        "session/<int:session_id>/export/",
        ExportAttendanceView.as_view(),
        name="attendance-export",
    ),
]
