from django.contrib import admin

from .models import Attendance, SuspiciousAttempt


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = [
        "student",
        "session",
        "validation_time",
        "attendance_status",
        "ip_address",
    ]
    list_filter = ["session__classe", "session__date", "attendance_status"]
    search_fields = ["student__code_massar", "student__last_name", "device_fingerprint"]


@admin.register(SuspiciousAttempt)
class SuspiciousAttemptAdmin(admin.ModelAdmin):
    list_display = ["attempt_type", "session", "code_massar", "ip_address", "created_at"]
    list_filter = ["attempt_type", "created_at"]
    search_fields = ["code_massar", "device_fingerprint", "ip_address"]
